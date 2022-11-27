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


locals {
  scoutsuite_bucket = "${var.host_project_id}-scoutsuite"
}

module "project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 13.0"
  project_id = var.host_project_id
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


resource "google_project_iam_member" "cloud_build_service_account_roles" {
  project = var.host_project_id
  role = "roles/logging.logWriter"
  member   = format("serviceAccount:%s", google_service_account.scoutsuite_service_account.email)
}

resource "google_project_iam_binding" "cloud_build_binding" {
  project = var.host_project_id
  role    = "roles/storage.admin"
  members = [
    format("serviceAccount:%s", google_service_account.scoutsuite_service_account.email),
  ]
  condition {
    title       = "Restrict to CloudBuild bucket"
    expression  = "resource.name.startsWith(\"projects/_/buckets/${var.host_project_id}_cloudbuild\")||\nresource.name.startsWith(\"projects/_/buckets/${google_storage_bucket.bucket.name}\")"
  }
}

# If scope set to Org scan

resource "google_organization_iam_member" "scoutsuite_service_account_roles" {
  org_id = regex("organization-id (.*)", var.scan_scope)[0]
  member   = format("serviceAccount:%s", google_service_account.scoutsuite_service_account.email)
  for_each = length(regexall("organization-id", var.scan_scope)) > 0 ? toset([
    "roles/viewer",
    "roles/iam.securityReviewer",
    "roles/stackdriver.accounts.viewer"
  ]) : []
  role     = each.key

}

resource "time_sleep" "wait_cloudbuild_sa_iam_org" {
  count = length(regexall("organization-id", var.scan_scope)) > 0 ? 1 : 0
  depends_on      = [google_organization_iam_member.scoutsuite_service_account_roles]
  create_duration = "60s"
}


# If scope set to Project scan

resource "google_project_iam_member" "scoutsuite_service_account_roles" {
  member   = format("serviceAccount:%s", google_service_account.scoutsuite_service_account.email)
  project = regex("project-id (.*)", var.scan_scope)[0]
  for_each = length(regexall("project-id", var.scan_scope)) > 0 ? toset([
    "roles/viewer",
    "roles/iam.securityReviewer",
    "roles/stackdriver.accounts.viewer"
  ]) : []
  role     = each.key

}

resource "time_sleep" "wait_cloudbuild_sa_iam_project" {
  count = length(regexall("project-id", var.scan_scope)) > 0 ? 1 : 0
  depends_on      = [google_project_iam_member.scoutsuite_service_account_roles]
  create_duration = "60s"
}

# If scope set to Folder scan

resource "google_folder_iam_member" "scoutsuite_service_account_roles" {
  member   = format("serviceAccount:%s", google_service_account.scoutsuite_service_account.email)
  folder = regex("folder-id (.*)", var.scan_scope)[0]
  for_each = length(regexall("folder-id", var.scan_scope)) > 0 ? toset([
    "roles/viewer",
    "roles/iam.securityReviewer",
    "roles/stackdriver.accounts.viewer"
  ]) : []
  role     = each.key

}

resource "time_sleep" "wait_cloudbuild_sa_iam_folder" {
  count = length(regexall("folder-id", var.scan_scope)) > 0 ? 1 : 0
  depends_on      = [google_folder_iam_member.scoutsuite_service_account_roles]
  create_duration = "60s"
}

# Run the Cloud Build Submit for Scout Suite report generation

module "gcloud_build_image" {
  source  = "terraform-google-modules/gcloud/google"
  version = "~> 3.1"

  platform = "linux"

  create_cmd_entrypoint  = "gcloud"
  create_cmd_body        = "builds submit build/ --config=build/cloudbuild.yaml --substitutions=_SCOUTSUITE_BUCKET='${google_storage_bucket.bucket.name}',_SCOPE='${var.scan_scope}',_SERVICE_ACCOUNT='${google_service_account.scoutsuite_service_account.email}',_PROJECT_ID='${var.host_project_id}' --project ${var.host_project_id} --region=${var.region} --timeout=12000s"

  module_depends_on = [
    time_sleep.wait_cloudbuild_sa_iam_org,
    time_sleep.wait_cloudbuild_sa_iam_project,
    time_sleep.wait_cloudbuild_sa_iam_folder
  ]
}