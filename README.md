# Polkadot Monitoring System

This guide explains how to configure infrastructure to create a Polkadot monitoring system in Google Kubernetes Engine (GKE) from scratch

## Prerequisites

Before you begin, ensure you have the following prerequisites:

1. Google Project
2. Polkadot node setup (in case you need balances with the following flags `--unsafe-rpc-external --rpc-methods=Unsafe`, refer to [this guide](https://wiki.polkadot.network/docs/maintain-sync) to set it up, otherwise you can use a public one)
3. Have the following APIs enabled:
   - Compute Engine API
   - Kubernetes Engine API
   - BigQuery API
   - Service Networking API
   - Cloud SQL
   - Cloud SQL Admin API
   - Cloud Storage
   - Cloud Storage API
4. Account/Service account permissions (deployment user):
   - Editor
   - Kubernetes Engine Admin
   - Service Networking Admin
   - Project IAM Admin
5. Make sure [GCloud CLI](https://cloud.google.com/sdk/docs/install) installed

## Installation

1. **Create a Google Service Account and Generate JSON Key**:
   ```bash
   gcloud iam service-accounts create <SERVICE_ACCOUNT_NAME> --description "Polkadot monitoring system's service account"
   gcloud projects add-iam-policy-binding <PROJECT_ID> --member "serviceAccount:<SERVICE_ACCOUNT_NAME>@YOUR_PROJECT_ID.iam.gserviceaccount.com" --role "roles/bigquery.dataEditor"
   gcloud projects add-iam-policy-binding <PROJECT_ID> --member "serviceAccount:<SERVICE_ACCOUNT_NAME>@YOUR_PROJECT_ID.iam.gserviceaccount.com" --role "roles/storage.objectUser"
   gcloud iam service-accounts keys create key.json --iam-account <SERVICE_ACCOUNT_NAME>@<PROJECT_ID>.iam.gserviceaccount.com
   ```

   > Note (optional): create an IAM Policy binding for the service account to connect to BigQuery without the service account key (e.g. in Superset):

   ```bash
   gcloud iam service-accounts add-iam-policy-binding <SERVICE_ACCOUNT_NAME>@<PROJECT_ID>.iam.gserviceaccount.com \ --role roles/iam.workloadIdentityUser \ --member "serviceAccount:<SERVICE_ACCOUNT_NAME>@<PROJECT_ID>.svc.id.goog[superset/superset]"
   ```

2. **Update `values.yaml` file**
   - Set serviceAccountName from the previous step (in case you'd like to use Workload Identity)
   - Set serviceAccountToken from the previous step
   - Generate a Fernet key for Airflow deployment:
   ```bash
   python3 -c 'from cryptography.fernet import Fernet; fernet_key = Fernet.generate_key(); print(fernet_key.decode())'
   ```
   - Generate a Superset secret key for Superset deployment
   ```bash
   openssl rand -base64 42
   ```
   - Set RabbitMQ, PostgreSQL (database), Airflow and Superset credentials if needed

3. **Create a Bucket for Terraform State File (Optional)**:
   - Run the following command to create Google Storage Bucket
   ```bash
   gcloud storage buckets create gs://polkadot-monitoring-tfstate-$(LC_CTYPE=UTF tr -dc 'a-z0-9' < /dev/urandom | head -c8) \
    --project=<YOUR_PROJECT_ID> \
    --location=europe-west3 \
    --default-storage-class=STANDARD \
    --uniform-bucket-level-access \
    --public-access-prevention
   ```
   > In case you decide to store terraform state locally, remove backend.tf file

   - Update Backend Configuration in `infrastructure/backend.tf`:
   Set bucket_name to the bucket created in the previous step

   - Update Project ID in `infrastructure/variables.tf`
   ```
   variable "project" {
      description = "Project name in GCP"
      type        = string
      default     = "<project_id>"
   }
   ```

4. **Initialize Terraform Modules**:

    Run `terraform init` in the infrastructrure folder

5. **Plan and Apply Infrastructure**:

    ```bash
    terraform plan -out=out.tfplan
    terraform apply out.tfplan
    ```

6. **Now you can access Airflow and Superset at the following addresses**
   ```
      http://<kubernetes_ingress_address>:8080 - Airflow
      http://<kubernetes_ingress_address>:8088 - Superset
   ```

7. **Import Superset BigQuery database in the UI** (in case IAM Policy binding wasn't created)

   Navigate to `Settings` -> `Database Connections`, click on `+ Database`, in `SUPPORTED DATABASES` dropdown select `Google BigQuery` and upload credentials from Step 1
