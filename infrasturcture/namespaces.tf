resource "kubernetes_namespace" "mbelt_namespace" {
  depends_on = [module.cluster]
  metadata {
    annotations = {
      name = var.mbelt_namespace
    }
    name = var.mbelt_namespace
  }
}

resource "kubernetes_namespace" "airflow_namespace" {
  depends_on = [module.cluster]
  metadata {
    annotations = {
      name = var.airflow_namespace
    }
    name = var.airflow_namespace
  }
}

resource "kubernetes_namespace" "superset_namespace" {
  depends_on = [module.cluster]
  metadata {
    annotations = {
      name = var.superset_namespace
    }
    name = var.superset_namespace
  }
}
