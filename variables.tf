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


variable "host_project_id" {
  description = "The project to use to run Scoutsuite, Cloud Build, and create the SA and GCS Bucket."
  type        = string
}

variable "scan_scope" {
  description = "The scope of where Scoutsuite should scan. Valid inputs are: ' organization-id <ORGANIZATION ID>'; 'folder-id <FOLDER ID>'; 'project-id <PROJECT ID>'; 'all-projects' (that the service account has access to)"
  type        = string
}

variable "region" {
  description = "The Google Cloud region for the GCS Bucket to be created, and the region for Cloud Build to use" 
  type        = string
}

variable "scoutsuite_sa" {
  description = "The service account for ScoutSuite."
  default = "scoutsuite"
  type        = string
}

