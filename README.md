# Scoutsuite Security Scan for Google Cloud

This will run a Scoutsuite scan in your Google Cloud Organization and copy the report to a GCS Bucket.

## Providers

| Name | Version  |
|:----------|:----------|
| Terraform    | >= 0.14.0    |
| Google    | ~> 4.41.0    |


## Resources

The following resources will be created:

- GCS Bucket to store report
- Service Account for Cloud Build job to run with and Scoutsuite scan to run under
- Organization IAM Role Bindings that are attached to the SA: **Viewer**, **Security Reviewer**, **Stackdriver Accounts Viewer**, **Log Writer**, **Storage Object Creator** (restricted to the GCS bucket previously created)
- Cloud Build Image


## Cloud Build

The Cloud Build job will contain the following attributes:

- Uses google-cloud-cli:slim and gsutil base container images from Google's public container registry
- Scoutsuite is installed on google-cloud-cli:slim
- Scoutsuite is run on Current Project, Organization, Folder, or all Projects that the service account has access to. 
- gsutil is used to copy the report files to the bucket created previously

 
## IAM Permissions

The following Roles are required for the user/SA to apply and destroy this Terraform script:

- Storage Admin
- Create Service Accounts
- Security Admin
- Service Account User
- Service Usage Admin
- Cloud Build Editor


## GCP Environment setup

It is recommended that this is run from within Google Cloud using Cloud Shell or however your currently execute Terraform scripts so as not to need to download SA keys.

Clone this repository

```sh
git clone https://github.com/icraytho/scoutsuite-gcp-tf.git
cd scoutsuite-gcp-tf
export WORKING_DIR=$(pwd)
```


## Variable Inputs


| Name | Description | Default  |
|:----------|:----------|:----------|
| gcp_domain   | The domain name of your Org    | n/a    |
| project_id    | The Project to create Resources    | n/a    |
| region    | Preferred Region to create bucket    | asia-southeast1    |
| scoutsuite_sa    | NAme of Service Account to Run Cloud Build Job and Scoutsuite scan    | scoutsuite    |
| scan_scope    | The scope of where Scoutsuite will run: Org/Folder/Project/All Projects service account has access to    | --all-projects    |


## Terraform init, plan and apply

Use Terraform to provision the Scoutsuite container and generate the report

```
cd ${WORKING_DIR}
terraform init
terraform plan
terraform apply
```

## Get the Scout Suite Report

The result report is put in to the GCS Bucket that was created. To view the report it is recommended that you download all the files from the bucket to your local machine and open the html file on your local browser.

## Clean up

Delete all provisioned resources by using Terraform destroy

```
terraform destroy
```

-------

This is not an official Google or Google Cloud product.

Copyright 2022 Ian Craythorne
SPDX-License-Identifier: Apache-2.0
