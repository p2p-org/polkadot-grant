module "cluster" {
  depends_on = [google_project_service.this]
  source     = "./modules/cluster"

  providers = {
    google-beta = google-beta
  }

  name                                         = "${var.project_prefix}-cluster"
  project                                      = local.project
  region                                       = var.region
  network_id                                   = google_compute_network.vpc.id
  networking_mode                              = "VPC_NATIVE"
  secondary_node_pool_enabled                  = false
  workload_identity_enabled                    = true
  backup_enabled                               = false
  primary_node_pool_machine_type               = "e2-standard-8"
  primary_node_pool_node_count                 = 4
  primary_node_pool_autoscaling_min_node_count = 1
  primary_node_pool_autoscaling_max_node_count = 8
  primary_node_pool_preemptible                = true
  master_authorized_cidr_blocks                = local.k8s_allowed_source_ranges
}

module "gke_auth" {
  depends_on           = [module.cluster]
  source               = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  version              = "24.1.0"
  project_id           = local.project
  location             = module.cluster.region
  cluster_name         = module.cluster.cluster_name
  use_private_endpoint = false
}

resource "kubernetes_config_map" "ip-masq-configmap" {
  depends_on = [module.cluster]
  metadata {
    name      = "ip-masq-agent"
    namespace = "kube-system"
  }

  data = {
    config = <<EOF
      nonMasqueradeCIDRs:
        - 0.0.0.0/0
      masqLinkLocal: true
      resyncInterval: 60s
    EOF
  }
}

resource "kubernetes_daemonset" "ip_masq_agent" {
  depends_on = [module.cluster]
  metadata {
    name      = "ip-masq-agent"
    namespace = "kube-system"
  }

  spec {
    selector {
      match_labels = {
        "k8s-app" = "ip-masq-agent"
      }
    }

    template {
      metadata {
        labels = {
          "k8s-app" = "ip-masq-agent"
        }
      }

      spec {
        host_network = true

        volume {
          name = "config"

          config_map {
            name     = "ip-masq-agent"
            optional = true
            items {
              key  = "config"
              path = "ip-masq-agent"
            }
          }
        }

        toleration {
          effect   = "NoSchedule"
          operator = "Exists"
        }

        toleration {
          effect   = "NoExecute"
          operator = "Exists"
        }

        toleration {
          key      = "CriticalAddonsOnly"
          operator = "Exists"
        }

        container {
          name  = "ip-masq-agent"
          image = "gcr.io/google-containers/ip-masq-agent-amd64:v2.5.0"

          args = [
            "--masq-chain=IP-MASQ"
          ]

          security_context {
            privileged = true
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/config"
          }
        }
      }
    }
  }
}

# resource "local_file" "kubeconfig" {
#   content = module.gke_auth.kubeconfig_raw
#   filename = local.kube_config_filepath
# }

output "kubernetes_endpoint" {
  value = module.cluster.endpoint
}

output "kubernetes_ingress_address" {
  value = module.cluster.ingress_static_ip_address
}
