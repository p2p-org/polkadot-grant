output "address" {
  value = google_sql_database_instance.this.private_ip_address
}

output "service_account" {
  value = var.create_service_account ? google_service_account.this[0].email : ""
}

output "database_name" {
  value = google_sql_database.this.0.name
}

output "google_sql_database_instance" {
  value = google_sql_database_instance.this
}

output "google_sql_database" {
  value = google_sql_database.this
}

output "connection_name" {
  value = google_sql_database_instance.this.connection_name
}

output "server_ca_cert" {
  value = var.ssl_enabled ? google_sql_ssl_cert.cluster_certificate.0.server_ca_cert : ""
}

output "private_key" {
  value = var.ssl_enabled ? google_sql_ssl_cert.cluster_certificate.0.private_key : ""
}

output "cert" {
  value = var.ssl_enabled ? google_sql_ssl_cert.cluster_certificate.0.cert : ""
}
