resource "google_dns_record_set" "public" {
  name         = "database.${var.managed_zone.dns_name}"
  count        = var.create_dns_record && var.ipv4_enabled ? 1 : 0
  managed_zone = var.managed_zone.name
  type         = "A"
  ttl          = var.ttl

  rrdatas = [
    google_sql_database_instance.this.public_ip_address,
  ]
}

resource "google_dns_record_set" "private" {
  count        = var.create_dns_record ? 1 : 0
  managed_zone = var.managed_zone.name
  name         = "internal.db.${var.managed_zone.dns_name}"
  type         = "A"
  ttl          = var.ttl

  rrdatas = [
    google_sql_database_instance.this.private_ip_address,
  ]
}
