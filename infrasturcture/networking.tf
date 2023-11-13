resource "google_compute_network" "vpc" {
  name                    = "${var.project_prefix}-vpc"
  auto_create_subnetworks = "true"
}


resource "google_compute_address" "nat-ip" {
  name   = "${var.project_prefix}-nat-ip"
  region = var.region
}


resource "google_compute_router" "router" {
  project = local.project
  name    = "${var.project_prefix}-router"
  network = google_compute_network.vpc.name
  region  = var.region
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.project_prefix}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = [google_compute_address.nat-ip.self_link]

  enable_dynamic_port_allocation      = true
  enable_endpoint_independent_mapping = false
  min_ports_per_vm                    = 4096
  max_ports_per_vm                    = 65536

  tcp_transitory_idle_timeout_sec = 60
  udp_idle_timeout_sec            = 60

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

output "kubernetes_egress_address" {
  value = google_compute_address.nat-ip.address
}
