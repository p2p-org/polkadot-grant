# Create a Service Account.
resource "google_service_account" "this" {
  count = var.create_service_account ? 1 : 0
  account_id   = "${var.name}-sa"
  display_name = "${var.name} Service Account"
  project      = var.project
}

# Create a key for the Service Account (auth.json).
resource "google_service_account_key" "this" {
  count = var.create_service_account ? 1 : 0
  service_account_id = google_service_account.this[count.index].name
}

# Allow the creation of tokens for the Service Account.
resource "google_project_iam_member" "workload_identity_user" {
  count = var.create_service_account ? 1 : 0
  project = var.project
  role    = "roles/iam.workloadIdentityUser"
  member  = google_service_account.this[count.index].member
}

# Attach the Kubernetes Developer role to the Service Account.
# Required to deploy to Google Kubernetes Engine.
resource "google_project_iam_member" "cloud_sql_client" {
  count   = var.create_service_account ? 1 : 0
  project = var.project
  role    = "roles/cloudsql.client"
  member  = google_service_account.this[count.index].member
}
