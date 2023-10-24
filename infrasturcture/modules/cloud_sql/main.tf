resource "google_compute_network" "this" {
  count = var.create_network ? 1 : 0

  name = var.name
}

resource "google_compute_global_address" "this" {
  name          = var.name
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.create_network ? google_compute_network.this[0].id : var.network_id
}

resource "google_service_networking_connection" "this" {
  provider = google

  network                 = var.create_network ? google_compute_network.this[0].id : var.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.this.name]

  lifecycle {
    ignore_changes = [
      reserved_peering_ranges
    ]
  }
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "this" {
  name                = "${var.name}-${random_id.db_name_suffix.hex}"
  database_version    = var.database_version
  region              = var.region
  deletion_protection = var.deletion_protection

  settings {
    tier            = var.instance_tier
    disk_autoresize = var.disk_autoresize
    disk_size       = var.disk_size
    disk_type       = var.disk_type

    availability_type = var.availability_type

    database_flags {
      name  = "max_connections"
      value = 5000
    }

    backup_configuration {
      enabled            = var.backup_enabled
      binary_log_enabled = var.backup_binary_log_enabled
      start_time         = var.backup_start_time
    }

    maintenance_window {
      day          = var.maintenance_window_day
      hour         = var.maintenance_window_hour
      update_track = var.maintenance_window_update_track
    }

    ip_configuration {
      ipv4_enabled    = var.ipv4_enabled
      private_network = var.create_network ? google_compute_network.this[0].id : var.network_id
      require_ssl     = var.ssl_enabled ? true : false

      dynamic "authorized_networks" {
        for_each = var.authorized_networks
        iterator = net

        content {
          name  = lookup(net.value, "name", null)
          value = lookup(net.value, "address", null)
        }
      }
    }
    user_labels = {
      name             = var.name
      project          = var.project
      terraform        = "true"
    }
  }

  depends_on = [google_sql_database_instance.this]
}

resource "google_sql_database" "this" {
  count    = length(var.databases)
  instance = google_sql_database_instance.this.name

  name = var.databases[count.index]

  depends_on = [google_service_networking_connection.this]
}

resource "google_sql_user" "this" {
  count    = length(var.users)
  instance = google_sql_database_instance.this.name

  name     = var.users[count.index].name
  password = var.users[count.index].password
  host     = lookup(var.users[count.index], "host", var.default_remote_host)

  depends_on = [google_sql_database_instance.this]
}

resource "google_sql_ssl_cert" "cluster_certificate" {
  count = var.ssl_enabled ? 1 : 0
  common_name = "cluster-certificate"
  instance    = google_sql_database_instance.this.name
}
