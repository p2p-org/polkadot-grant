locals {
  sa_roles = [
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
    "roles/storage.objectUser"
  ]
}

resource "google_service_account" "bigquery-sa" {
  account_id   = var.service_account_name
  project      = local.project
  display_name = "A service acount to interact with Big Query"
}

resource "google_project_iam_member" "bigquery-sa" {
  for_each = toset(local.sa_roles)
  project  = local.project
  role     = each.key
  member   = "serviceAccount:${google_service_account.bigquery-sa.email}"
}

resource "google_service_account_iam_member" "bigquery-sa" {
  service_account_id = google_service_account.bigquery-sa.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${local.project}.svc.id.goog[superset/superset]"
}

resource "google_service_account_key" "bigquery-sa" {
  service_account_id = google_service_account.bigquery-sa.name
  public_key_type    = "TYPE_RAW_PUBLIC_KEY"
}
