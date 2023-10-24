module "cloud_sql" {
  source    = "./modules/cloud_sql"

  name          = "${var.project_prefix}-sql"
  project       = var.project
  zone          = var.zone
  region        = var.region
  network_id    = google_compute_network.vpc.self_link
  ssl_enabled   = var.cloud_sql_ssl_enabled
  disk_size     = "1500"
  ipv4_enabled  = true

  databases     = [ var.mbelt_database_name, var.airflow_database_name, var.superset_database_name ]
  users         = [
    {
      name      = local.cloud_sql_postgres_user
      password  = local.cloud_sql_postgres_password
      host      = ""
    }
  ]
  authorized_networks = local.authorized_networks
}

output "cloud_sql_address" {
  value = module.cloud_sql.address
}
