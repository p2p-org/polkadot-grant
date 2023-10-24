# Create a Google Kubernetes Engine cluster using the google-beta provider
# The stable provider currently does not support some features like the backup configuration
resource "google_container_cluster" "this" {
  provider = google-beta
  name     = var.name
  project  = var.project
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1

  network         = var.network_id
  networking_mode = var.networking_mode

  dynamic "ip_allocation_policy" {
    for_each = var.networking_mode == "VPC_NATIVE" ? [1] : []
    content {
      cluster_ipv4_cidr_block = "/20"
      services_ipv4_cidr_block = "/20"
    }
  }

  release_channel {
    channel = var.release_channel
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = var.master_auth_issue_client_certificate
    }
  }

  resource_labels = {
    name             = var.name
    project          = var.project
    terraform        = "true"
  }

  addons_config {
    horizontal_pod_autoscaling {
      disabled = var.horizontal_pod_autoscaling_disabled
    }

    http_load_balancing {
      disabled = var.http_load_balancing_disabled
    }

    gke_backup_agent_config {
      enabled = var.backup_enabled
    }

    gcp_filestore_csi_driver_config {
      enabled = var.filestore_csi_driver_enabled
    }
  }

  dynamic "workload_identity_config" {
    for_each = var.workload_identity_enabled ? [
      var.workload_identity_enabled
    ] : [ ]
    content {
      workload_pool = "${var.project}.svc.id.goog"
    }
  }

  cluster_autoscaling {
    enabled = var.cluster_autoscaling_enabled
    dynamic "resource_limits" {
      for_each = var.cluster_autoscaling_enabled ? [
        var.cluster_autoscaling_enabled
      ] : [ ]
      content {
        resource_type = "cpu"
        minimum       = var.cluster_autoscaling_resource_limits_cpu_min
        maximum       = var.cluster_autoscaling_resource_limits_cpu_max
      }
    }
    dynamic "resource_limits" {
      for_each = var.cluster_autoscaling_enabled ? [
        var.cluster_autoscaling_enabled
      ] : [ ]
      content {
        resource_type = "memory"
        minimum       = var.cluster_autoscaling_resource_limits_memory_min
        maximum       = var.cluster_autoscaling_resource_limits_memory_max
      }
    }
    autoscaling_profile = var.cluster_autoscaling_enabled ? var.cluster_autoscaling_profile : null
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = var.maintenance_window_start_time
    }
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = local.master_authorized_cidr_blocks
      iterator = i
      content {
        cidr_block   = i.value.cidr_block
        display_name = lookup(i.value, "display_name", null)
      }
    }
  }

  vertical_pod_autoscaling {
    enabled = var.vertical_pod_autoscaling_enabled
  }

  dynamic "node_config" {
    for_each = var.cluster_autoscaling_enabled ? [
      var.cluster_autoscaling_enabled
    ] : [ ]
    content {
      oauth_scopes = [
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring",
        "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
        "https://www.googleapis.com/auth/devstorage.read_only",
        "https://www.googleapis.com/auth/service.management.readonly",
        "https://www.googleapis.com/auth/servicecontrol",
        "https://www.googleapis.com/auth/trace.append",
      ]

      metadata = {
        disable-legacy-endpoints = "true"
      }

      labels = {
        name             = var.name
        project          = var.project
        terraform        = "true"
      }

      dynamic "workload_metadata_config" {
        for_each = var.workload_identity_enabled ? [
          var.workload_identity_enabled
        ] : [ ]
        content {
          mode = "GKE_METADATA"
        }
      }

      tags = var.primary_node_pool_network_tags
    }
  }
}

# Create a primary custom node pool for the cluster.
resource "google_container_node_pool" "this" {
  name_prefix    = substr(var.name, 0, 12)
  project        = var.project
  location       = var.region
  cluster        = google_container_cluster.this.name
  node_count     = var.primary_node_pool_node_count

  node_config {
    preemptible  = var.primary_node_pool_preemptible
    machine_type = var.primary_node_pool_machine_type
    disk_size_gb = var.primary_node_pool_disk_size_gb
    disk_type    = var.primary_node_pool_disk_type
    image_type   = var.primary_node_pool_image_type

    labels = merge({
      name             = var.name
      project          = var.project
      terraform        = "true"
    }, var.primary_node_pool_labels)

    dynamic "taint" {
      for_each = var.primary_node_pool_taints
      iterator = t
      content {
        effect = t.value[ "effect" ]
        key    = t.value[ "key" ]
        value  = t.value[ "value" ]
      }
    }

    tags = var.primary_node_pool_network_tags

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]

    dynamic "workload_metadata_config" {
      for_each = var.workload_identity_enabled ? [
        var.workload_identity_enabled
      ] : [ ]
      content {
        mode = "GKE_METADATA"
      }
    }

    service_account = var.node_pool_service_account
  }

  autoscaling {
    location_policy = "ANY"
    min_node_count  = var.primary_node_pool_autoscaling_min_node_count
    max_node_count  = var.primary_node_pool_autoscaling_max_node_count
  }

  management {
    auto_repair  = var.primary_node_pool_management_auto_repair
    auto_upgrade = var.primary_node_pool_management_auto_upgrade
  }

  upgrade_settings {
    max_surge       = var.primary_node_pool_upgrade_max_surge
    max_unavailable = var.primary_node_pool_upgrade_max_unavailable
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [
      node_count
    ]
  }
}

# Create a static IP address for the cluster.
resource "google_compute_address" "ingress" {
  count = var.create_static_ip_for_ingress ? 1 : 0
  name  = var.name
}

# Create a secondary custom node pool for the cluster.
resource "google_container_node_pool" "secondary" {
  count          = var.secondary_node_pool_enabled ? 1 : 0
  name_prefix    = substr(var.name, 0, 12)
  project        = var.project
  location       = var.region
  cluster        = google_container_cluster.this.name
  node_count     = var.secondary_node_pool_node_count

  node_config {
    preemptible  = var.secondary_node_pool_preemptible
    machine_type = var.secondary_node_pool_machine_type
    disk_size_gb = var.secondary_node_pool_disk_size_gb
    disk_type    = var.secondary_node_pool_disk_type
    image_type   = var.secondary_node_pool_image_type

    labels = merge({
      name             = var.name
      project          = var.project
      terraform        = "true"
    }, var.secondary_node_pool_labels)

    dynamic "taint" {
      for_each = var.secondary_node_pool_taints
      iterator = t
      content {
        effect = t.value[ "effect" ]
        key    = t.value[ "key" ]
        value  = t.value[ "value" ]
      }
    }

    tags = var.secondary_node_pool_network_tags

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]

    service_account = var.node_pool_service_account
  }

  autoscaling {
    location_policy = "ANY"
    min_node_count  = var.secondary_node_pool_autoscaling_min_node_count
    max_node_count  = var.secondary_node_pool_autoscaling_max_node_count
  }

  management {
    auto_repair  = var.secondary_node_pool_management_auto_repair
    auto_upgrade = var.secondary_node_pool_management_auto_upgrade
  }

  upgrade_settings {
    max_surge       = var.secondary_node_pool_upgrade_max_surge
    max_unavailable = var.secondary_node_pool_upgrade_max_unavailable
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [
      node_count
    ]
  }
}

# Configure a backup plan for the cluster with a schedule.
# resource "google_gke_backup_backup_plan" "this" {
#   count    = var.backup_enabled ? 1 : 0
#   project  = var.project
#   provider = google-beta
#   name     = "${var.name}-backup-plan"
#   cluster  = google_container_cluster.this.id
#   location = var.region

#   retention_policy {
#     backup_delete_lock_days = var.backup_delete_lock_days
#     backup_retain_days = var.backup_retain_days
#   }

#   backup_schedule {
#     cron_schedule = var.backup_schedule
#   }

#   backup_config {
#     include_volume_data = var.backup_include_volume_data
#     include_secrets     = var.backup_include_secrets
#     all_namespaces      = var.backup_all_namespaces
#   }
# }
