locals {
  cloud_sql_certificates_secret_name      = "cloud-sql-certificates"
  mbelt3-postgresql-metadata              = "mbelt3-postgresql-metadata"
  airflow-fernet-key                      = "airflow-fernet-key"
  airflow-env-vars-json-secret-name       = "airflow-env-vars-json"
  airflow-webserver-key-secret-name       = "airflow-webserver-key"
  airflow-bigquery-sa-json-secret-name    = "airflow-bigquery-sa-json"
  airflow-postgresql-metadata-secret-name = "airflow-postgresql-metadata"
  superset-secret-key-secret-name         = "superset-secret-key"
}

resource "kubernetes_secret" "cloud-sql-certificates" {
  depends_on = [kubernetes_namespace.mbelt_namespace]
  count      = var.cloud_sql_ssl_enabled ? 1 : 0
  metadata {
    name      = local.cloud_sql_certificates_secret_name
    namespace = var.mbelt_namespace
  }
  data = {
    "client-key"  = module.cloud_sql.private_key
    "client-cert" = module.cloud_sql.cert
  }
}

resource "kubernetes_secret" "mbelt3-postgresql-metadata" {
  depends_on = [kubernetes_namespace.mbelt_namespace]
  metadata {
    name      = local.mbelt3-postgresql-metadata
    namespace = var.airflow_namespace
  }
  data = {
    "connection" = "postgresql://${local.cloud_sql_postgres_user}:${local.cloud_sql_postgres_password}@${module.cloud_sql.address}:5432/${var.mbelt_database_name}"
  }
}

resource "kubernetes_secret" "airflow-postgresql-metadata" {
  depends_on = [kubernetes_namespace.airflow_namespace]
  metadata {
    name      = local.airflow-postgresql-metadata-secret-name
    namespace = var.airflow_namespace
  }
  data = {
    "connection" = "postgresql://${local.cloud_sql_postgres_user}:${local.cloud_sql_postgres_password}@${module.cloud_sql.address}:5432/${var.airflow_database_name}"
  }
}

resource "kubernetes_secret" "airflow-webserver-key" {
  depends_on = [kubernetes_namespace.airflow_namespace]
  metadata {
    name      = local.airflow-webserver-key-secret-name
    namespace = var.airflow_namespace
  }
  data = {
    "webserver-secret-key" = local.airflow_webserver_key
  }
}

resource "kubernetes_secret" "airflow-env-vars-json" {
  depends_on = [kubernetes_namespace.airflow_namespace]
  metadata {
    name      = local.airflow-env-vars-json-secret-name
    namespace = var.airflow_namespace
  }
  data = {
    "config.json" = local.airflow_dag_vars
  }
}

resource "kubernetes_secret" "airflow-fernet-key" {
  depends_on = [kubernetes_namespace.airflow_namespace]
  metadata {
    name      = local.airflow-fernet-key
    namespace = var.airflow_namespace
  }
  data = {
    "fernet-key" = local.airflow_fernet_key
  }
}

resource "kubernetes_secret" "airflow-bigquery-sa-json" {
  depends_on = [kubernetes_namespace.airflow_namespace]
  metadata {
    name      = local.airflow-bigquery-sa-json-secret-name
    namespace = var.airflow_namespace
  }
  data = {
    "bigquery-sa.json" = base64decode(nonsensitive(google_service_account_key.bigquery-sa.private_key))
  }
}

resource "kubernetes_secret" "superset-secret-key" {
  depends_on = [kubernetes_namespace.superset_namespace]
  metadata {
    name      = local.superset-secret-key-secret-name
    namespace = var.superset_namespace
  }
  data = {
    "secret-key" = local.superset_secret_key
  }
}
