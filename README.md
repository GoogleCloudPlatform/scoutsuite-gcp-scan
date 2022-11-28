# Scoutsuite Security Scan for Google Cloud

This will run a Scoutsuite security scan in your Google Cloud Organization, Folder or Project and copy the report to a GCS Bucket.

## Providers

| Name | Version  |
|:----------|:----------|
| Terraform    | >= 0.14.0    |
| Google    | ~> 4.41.0    |


## Resources

The following resources will be created:

- GCS bucket to store html report
- Service Account for Cloud Build job to run with, and the Scoutsuite scan to run under
- IAM Role Bindings that are attached to the SA: **Viewer**, **Security Reviewer**, **Stackdriver Accounts Viewer**, **Log Writer**, **Storage Object Admin** (restricted to the GCS bucket previously created and the bucket created for Cloud Build)
- Cloud Build Image


## Cloud Build

The Cloud Build job will contain the following attributes:

- Uses google-cloud-cli:slim and gsutil base container images from Google's public container registry
- Scoutsuite is installed on google-cloud-cli:slim
- Scoutsuite is run on Current Project, Organization, Folder, or all Projects that the service account has access to
- gsutil is used to copy the report files to the bucket created previously

 
## IAM Permissions

The following Roles are required for the user/SA to apply and destroy this Terraform script:

Within the host project from where the scan will be run:

- Storage Admin
- Create Service Accounts
- Service Account User
- Service Usage Admin
- Cloud Build Editor

The following roles are required depending on the scan scope:
- Project IAM Admin Administrator (Project Level Scan)
- Folder Administrator (Folder Level Scan)
- Organization Administrator (Org Level Scan)


## GCP Environment setup

It is recommended that this is run from within Google Cloud using Cloud Shell, or however your currently execute Terraform scripts so as not to need to download SA keys.

Clone this repository

```sh
git clone https://github.com/GoogleCloudPlatform/scoutsuite-gcp-scan.git
cd scoutsuite-gcp-tf
export WORKING_DIR=$(pwd)
```


## Variable Inputs

| Name | Description | Default  |
|:----------|:----------|:----------|
| host_project_id   | The Project ID used to to create resources in (SA, GCS Bucket, Cloud Build) and run Scoutsuite from    | n/a    |
| scan_scope    | The scope of where Scoutsuite should scan. Valid inputs are: 'organization-id [ORGANIZATION ID]'; 'folder-id [FOLDER ID]'; 'project-id [PROJECT ID]'  | n/a    |
| region    | Preferred Region to create resources    | n/a   |
| scoutsuite_sa    | Name of Service Account to Run Cloud Build Job and Scoutsuite scan    | scoutsuite    |


## Terraform init, plan and apply

Use Terraform to provision the Scoutsuite container and generate the report

```
cd ${WORKING_DIR}
terraform init
terraform plan
terraform apply
```

## Get the Scout Suite Report

The result report is put in to the GCS bucket that was created. To view the report it is recommended that you download all the files from the bucket to your local machine and open the html file on your local browser.

## Clean up

Delete all provisioned resources by using Terraform destroy

```
terraform destroy
```

-------

This is not an official Google or Google Cloud product.

Copyright 2022 Google
SPDX-License-Identifier: Apache-2.0
