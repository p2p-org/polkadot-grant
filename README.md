# Polkadot Monitoring System

This guide explains how to configure infrastructure to create a Polkadot monitoring system in Google Kubernetes Engine (GKE) from scratch

## Prerequisites

Before you begin, ensure you have the following prerequisites:

1. Google Project
2. Polkadot node setup (in case you need balances with the following flags `--unsafe-rpc-external --rpc-methods=Unsafe`, refer to [this guide](https://wiki.polkadot.network/docs/maintain-sync) to set it up, otherwise you can use a public one)
2. Account/Service account permissions (deployment user):
   - Editor
   - Security Admin
   - Project IAM Admin
   - Kubernetes Engine Admin
   - Service Networking Admin
3. Make sure [GCloud CLI](https://cloud.google.com/sdk/docs/install) is installed
4. Make sure [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) is installed

## Installation
1. **Create Project in Google Cloud and assign to your user permissions mentioned above**

   To create Google project refer to [this](https://developers.google.com/workspace/guides/create-project) guide

   To assign permissions refer to [this](https://developers.google.com/apps-script/guides/admin/assign-cloud-permissions) guide

2. **Authenticate to Google Cloud**:
   ```bash
   gcloud auth application-default login
   ```

3. **Update `values.yaml` file**:
   - Generate a Fernet key for Airflow deployment:
   ```bash
   python3 -c 'from cryptography.fernet import Fernet; fernet_key = Fernet.generate_key(); print(fernet_key.decode())'
   ```
   - Generate a Superset secret key for Superset deployment
   ```bash
   openssl rand -base64 42
   ```
   - Generate an Airflow Web secret key for Airflow deployment
   ```bash
   openssl rand -base64 24
   ```
   - Set RabbitMQ, PostgreSQL (database), Airflow and Superset credentials if needed
   - Set the `project` variable with Google project name

4. **Create a Bucket for Terraform State File (Optional)**:
   - Run the following command to create Google Storage Bucket
   ```bash
   gcloud storage buckets create gs://polkadot-monitoring-tfstate-$(LC_CTYPE=UTF tr -dc 'a-z0-9' < /dev/urandom | head -c8) \
    --project=<YOUR_PROJECT_ID> \
    --location=europe-west3 \
    --default-storage-class=STANDARD \
    --uniform-bucket-level-access \
    --public-access-prevention
   ```

   - Update Backend Configuration in `infrastructure/backend.tf.example` and rename it to `infrastructure/backend.tf`:
   Set `bucket_name` to the bucket created in the previous step

5. **Initialize Terraform Modules**:

   Run `terraform init` in the infrastructrure folder

6. **Plan and Apply Infrastructure**:

   It's better to enable APIs first as they may not respond during deployment as it takes some time to provision them
   To enable them simply run
   ```bash
   terraform apply -auto-approve -target google_project_service.this
   ```

   ```bash
   terraform plan -out=out.tfplan
   terraform apply out.tfplan
   ```

7. **Now you can access Airflow and Superset at the following addresses**
   ```
      http://<kubernetes_ingress_address>:8080 - Airflow
      http://<kubernetes_ingress_address>:8088 - Superset
   ```

8. **To delete infrastructure**:
   ```bash
   terraform destroy
   ```
