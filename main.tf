# Copyright 2022 Google
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  scoutsuite_bucket = "${var.project_id}-scoutsuite"
}

data "google_project" "project" {
}

data "google_organization" "org" {
  domain = var.gcp_domain
}

module "project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 13.0"

  project_id = var.project_id

  activate_apis = [
    "iam.googleapis.com", 
    "cloudresourcemanager.googleapis.com",
    "storage.googleapis.com",
    "cloudbuild.googleapis.com"
  ]

  disable_dependent_services = false
  disable_services_on_destroy = false
}

# Pre-requiste to have a GCS Bucket name with format "<project-id>-scoutsuite"
resource "google_storage_bucket" "bucket" {
  name     = local.scoutsuite_bucket  # Every bucket name must be globally unique
  location = "${var.region}"
  uniform_bucket_level_access = true
  force_destroy = true
}

# Create Service Account to run Scoutsuite

resource "google_service_account" "scoutsuite_service_account" {
  account_id   = "${var.scoutsuite_sa}-sa"
  display_name = "ScoutSuite Service Account"
}

resource "google_organization_iam_member" "scoutsuite_service_account_roles" {
  org_id  = data.google_organization.org.org_id
  member   = format("serviceAccount:%s", google_service_account.scoutsuite_service_account.email)
  for_each = toset([
    "roles/viewer",
    "roles/iam.securityReviewer",
    "roles/stackdriver.accounts.viewer",
    "roles/logging.logWriter"
  ])
  role     = each.key

}

resource "google_organization_iam_binding" "binding" {
  org_id = data.google_organization.org.org_id
  role    = "roles/storage.objectCreator"
  members = [
    format("serviceAccount:%s", google_service_account.scoutsuite_service_account.email),
  ]
  condition {
    title       = "Restrict to Scoutsuite bucket"
    expression  = "resource.name.startsWith(\"projects/_/buckets/${google_storage_bucket.bucket.name}\")"
  }
  
  depends_on      = [google_organization_iam_member.scoutsuite_service_account_roles]
}

resource "time_sleep" "wait_cloudbuild_sa_iam" {
  depends_on      = [google_organization_iam_binding.binding]
  create_duration = "60s"
}

# Run the Cloud Build Submit for Scout Suite report generation

module "gcloud_build_image" {
  source  = "terraform-google-modules/gcloud/google"
  version = "~> 3.1"

  platform = "linux"

  create_cmd_entrypoint  = "gcloud"
  create_cmd_body        = "builds submit build/ --config=build/cloudbuild.yaml --substitutions=_SCOUTSUITE_BUCKET='${google_storage_bucket.bucket.name}',_SCOPE='${var.scan_scope}',_SERVICE_ACCOUNT='${google_service_account.scoutsuite_service_account.email}',_PROJECT_ID='${var.project_id}' --project ${var.project_id} --region=${var.region} --timeout=12000s"

  module_depends_on = [
    time_sleep.wait_cloudbuild_sa_iam,
  ]
}