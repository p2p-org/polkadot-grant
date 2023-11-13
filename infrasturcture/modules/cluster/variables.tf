variable "name" {
  description = "The name of the Kubernetes cluster and the prefix for the additional resources"
}

variable "project" {
  description = "GCP Project ID"
}

variable "region" {
  description = "GCP region"
}

variable "master_auth_issue_client_certificate" {
  default     = true
  description = "Specifies a client certificate to be issued by the cluster"
}

variable "release_channel" {
  default     = "REGULAR"
  description = "The release channel for the cluster (valid values: STABLE, REGULAR, RAPID)"
}

variable "master_authorized_cidr_blocks" {
  type = list(object({
    display_name = string,
    cidr_block   = string,
  }))
  default     = []
  description = "The list of CIDR blocks to allow access to the master endpoint. This one can be used as defaults for all clusters"
}

variable "master_authorized_cidr_blocks_extra" {
  type = list(object({
    display_name = string,
    cidr_block   = string,
  }))
  default     = []
  description = "The list of CIDR blocks to allow access to the master endpoint. This one can be used to add extra CIDR blocks to the default list"
}

locals {
  # Create a list of the two list of maps
  master_authorized_cidr_block_maps = [
    var.master_authorized_cidr_blocks,
    var.master_authorized_cidr_blocks_extra,
  ]

  # Merge the default and the additional list of cidr blocks to 1 list of maps
  master_authorized_cidr_blocks = flatten([
    # Iterate through the list of lists (default list + extra list)
    for m in local.master_authorized_cidr_block_maps : [
      # Iterate through the list of maps
      for x in m : [
        {
          display_name = x.display_name,
          cidr_block   = x.cidr_block,
        }
      ]
    ]
  ])
}

variable "horizontal_pod_autoscaling_disabled" {
  default     = false
  description = "Whether to disable the horizontal pod autoscaling addon"
}

variable "http_load_balancing_disabled" {
  default     = false
  description = "Whether to disable the http load balancing addon"
}

variable "vertical_pod_autoscaling_enabled" {
  default     = true
  description = "Whether to enable the vertical pod autoscaling addon"
}

variable "maintenance_window_start_time" {
  default     = "03:00"
  description = "The start time of the maintenance window (in UTC)"
}

variable "cluster_autoscaling_enabled" {
  default     = false
  description = "Whether to enable the cluster autoscaling addon"
}

variable "cluster_autoscaling_profile" {
  description = "The cluster autoscaling profile (valid values: OPTIMIZE_UTILIZATION, BALANCED)"
  default     = "OPTIMIZE_UTILIZATION"
}

variable "cluster_autoscaling_resource_limits_cpu_min" {
  description = "The cluster autoscaler will scale the cluster to make this minimum number of CPU cores available"
  default     = 4
}

variable "cluster_autoscaling_resource_limits_cpu_max" {
  description = "The cluster autoscaler will scale the cluster to make this maximum number of CPU cores available"
  default     = 8
}

variable "cluster_autoscaling_resource_limits_memory_min" {
  description = "The cluster autoscaler will scale the cluster to make this minimum amount of memory available"
  default     = null
}

variable "cluster_autoscaling_resource_limits_memory_max" {
  description = "The cluster autoscaler will scale the cluster to make this maximum amount of memory available"
  default     = 16
}

variable "node_pool_service_account" {
  description = "The service account to use by the node pool"
  default     = null
}

### PRIMARY NODE POOL
variable "primary_node_pool_node_locations" {
  description = "The list of GCP zones to deploy the primary node pool to. If it's empty the default location will be used"
  default     = []
}

locals {
  primary_node_pool_node_locations = var.primary_node_pool_node_locations == [] ? [
    var.region
  ] : var.primary_node_pool_node_locations
}

variable "primary_node_pool_node_count" {
  description = "The number of nodes in the primary node pool"
  default     = 1
}

variable "primary_node_pool_machine_type" {
  description = "The machine type of the primary node pool"
  default     = "e2-standard-2"
}

variable "primary_node_pool_preemptible" {
  description = "Whether the primary node pool nodes should be preemptible or not"
  default     = true
}

variable "primary_node_pool_disk_size_gb" {
  description = "The root disk size of the primary node pool nodes"
  default     = 100
}

variable "primary_node_pool_disk_type" {
  description = "The root disk type of the primary node pool nodes"
  default     = "pd-ssd"
}

variable "primary_node_pool_image_type" {
  description = "The image type of the primary node pool nodes. (valid values: UBUNTU_CONTAINERD, COS_CONTAINERD)"
  default     = "COS_CONTAINERD"
}

variable "primary_node_pool_labels" {
  description = "The labels of the primary node pool"
  default     = {}
}

variable "primary_node_pool_taints" {
  description = "The taints of the primary node pool"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []

  # e. g.
  # default = [{
  #   key    = "preemptible"
  #   value  = "false"
  #   effect = "NO_SCHEDULE"
  # }]
}

variable "primary_node_pool_network_tags" {
  description = "The network tags of the primary node pool. Can be used to attach firewall the nodes"
  default     = []
}

variable "primary_node_pool_autoscaling_min_node_count" {
  description = "The minimum number of nodes in the primary node pool"
  default     = 1
}

variable "primary_node_pool_autoscaling_max_node_count" {
  description = "The maximum number of nodes in the primary node pool"
  default     = 5
}

variable "primary_node_pool_management_auto_repair" {
  description = "Whether the primary node pool nodes should be auto repaired or not"
  default     = true
}

variable "primary_node_pool_management_auto_upgrade" {
  description = "Whether the primary node pool nodes should be auto upgraded or not"
  default     = true
}

variable "primary_node_pool_maintenance_window_start_time" {
  description = "The start time of the maintenance window (in UTC)"
  default     = "03:00"
}

variable "primary_node_pool_upgrade_max_surge" {
  description = "The maximum number of nodes that can be created above the desired number of nodes during an upgrade"
  default     = 2
}

variable "primary_node_pool_upgrade_max_unavailable" {
  description = "The maximum number of nodes that can be unavailable during an upgrade"
  default     = 0
}

### SECONDARY NODE POOL
variable "secondary_node_pool_enabled" {
  description = "Whether to create a secondary node pool or not"
  default     = false
}

variable "secondary_node_pool_node_locations" {
  description = "The list of GCP zones to deploy the secondary node pool to. If it's empty the default location will be used"
  default     = []
}

locals {
  secondary_node_pool_node_locations = var.secondary_node_pool_node_locations == [] ? [
    var.region
  ] : var.secondary_node_pool_node_locations
}

variable "secondary_node_pool_node_count" {
  description = "The number of nodes in the secondary node pool"
  default     = 1
}

variable "secondary_node_pool_machine_type" {
  description = "The machine type of the secondary node pool"
  default     = "e2-standard-2"
}

variable "secondary_node_pool_preemptible" {
  description = "Whether the secondary node pool nodes should be preemptible or not"
  default     = false
}

variable "secondary_node_pool_disk_size_gb" {
  description = "The root disk size of the secondary node pool nodes"
  default     = 100
}

variable "secondary_node_pool_disk_type" {
  description = "The root disk type of the secondary node pool nodes"
  default     = "pd-ssd"
}

variable "secondary_node_pool_image_type" {
  description = "The image type of the secondary node pool nodes. (valid values: UBUNTU_CONTAINERD, COS_CONTAINERD)"
  default     = "COS_CONTAINERD"
}

variable "secondary_node_pool_labels" {
  description = "The labels of the secondary node pool"
  default     = {}
}

variable "secondary_node_pool_taints" {
  description = "The taints of the secondary node pool"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []

  # eg.
  # default = [{
  #   key    = "preemptible"
  #   value  = "false"
  #   effect = "NO_SCHEDULE"
  # }]
}

variable "secondary_node_pool_network_tags" {
  description = "The network tags of the secondary node pool. Can be used to attach firewall the nodes"
  default     = []
}

variable "secondary_node_pool_autoscaling_min_node_count" {
  description = "The minimum number of nodes in the secondary node pool"
  default     = 1
}

variable "secondary_node_pool_autoscaling_max_node_count" {
  description = "The maximum number of nodes in the secondary node pool"
  default     = 5
}

variable "secondary_node_pool_management_auto_repair" {
  description = "Whether the secondary node pool nodes should be auto repaired or not"
  default     = true
}

variable "secondary_node_pool_management_auto_upgrade" {
  description = "Whether the secondary node pool nodes should be auto upgraded or not"
  default     = true
}

variable "secondary_node_pool_upgrade_max_surge" {
  description = "The maximum number of nodes that can be created above the desired number of nodes during an upgrade"
  default     = 2
}

variable "secondary_node_pool_upgrade_max_unavailable" {
  description = "The maximum number of nodes that can be unavailable during an upgrade"
  default     = 1
}

variable "create_static_ip_for_ingress" {
  description = "Whether to create a static IP for the ingress or not"
  default     = true
}

variable "backup_enabled" {
  description = "Whether to create a Kubernetes Backup Plan or not"
  default     = true
}

variable "backup_include_volume_data" {
  description = "Whether to include volume data in the backup or not"
  default     = true
}

variable "backup_include_secrets" {
  description = "Whether to include secrets in the backup or not"
  default     = true
}

variable "backup_all_namespaces" {
  description = "Whether to backup all namespaces or not"
  default     = true
}

variable "backup_delete_lock_days" {
  description = "The number of days to prevent the backup deletion"
  default     = 7
}

variable "backup_retain_days" {
  description = "The number of days to retain the backup"
  default     = 30
}

variable "backup_schedule" {
  description = "The schedule of the backup"
  default     = "0 9 * * 1"
}

variable "filestore_csi_driver_enabled" {
  description = "Whether to install the Filestore CSI Driver to the Kubernetes cluster or not"
  default     = true
}

variable "workload_identity_enabled" {
  description = "Enable Workload Identity. This allows to use other GCP services from the Kubernetes cluster"
  default     = false
}

variable "networking_mode" {
  description = "The networking mode of the Kubernetes cluster. (valid values: ROUTES, VPC_NATIVE)"
  default     = "ROUTES"
}

variable "network_id" {
  description = "Network ID"
}
