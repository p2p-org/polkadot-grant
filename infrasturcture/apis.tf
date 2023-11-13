locals {
  gcp_services_list = [
    "kubernetesmetadata.googleapis.com",
    "container.googleapis.com",
    "compute.googleapis.com",
    "bigquery.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com"
  ]
}

resource "google_project_service" "this" {
  for_each                   = toset(local.gcp_services_list)
  project                    = local.project
  service                    = each.key
  disable_dependent_services = true
}
