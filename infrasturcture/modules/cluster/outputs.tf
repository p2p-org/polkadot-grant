# The name of the Kubernetes cluster.
output "cluster_name" {
  value = google_container_cluster.this.name
}

# The region where the Kubernetes cluster is located.
output "region" {
  value = google_container_cluster.this.location
}

# The IP address of the Kubernetes cluster control plane.
output "endpoint" {
  value = google_container_cluster.this.endpoint
}

# The CA certificate of the Kubernetes cluster.
output "ca_cert" {
  value = google_container_cluster.this.master_auth.0.cluster_ca_certificate
}

# The default client certificate of the Kubernetes cluster.
# By default it has no permissions.
output "client_cert" {
  value = google_container_cluster.this.master_auth.0.client_certificate
}

# The default client key of the Kubernetes cluster.
output "client_key" {
  value     = google_container_cluster.this.master_auth.0.client_key
  sensitive = true
}

# The IP Address of the Static IP attached to the Kubernetes cluster.
output "ingress_static_ip_address" {
  value = var.create_static_ip_for_ingress ? join("", google_compute_address.ingress.*.address) : null
}

# The name of the Static IP attached to the Kubernetes cluster.
output "ingress_static_ip_name" {
  value = var.create_static_ip_for_ingress ? join("", google_compute_address.ingress.*.name) : null
}

# The Kubernetes cluster can be accessed from these network ranges.
output "master_authorized_cidr_blocks" {
  value = local.master_authorized_cidr_blocks
}
