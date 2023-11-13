
locals {
  mbelt_chart_path = "../helm/mbelt"
  mbelt_chart_hash = md5(join("", [
    for f in fileset(local.mbelt_chart_path, "**") :
    filemd5(format("%s/%s", local.mbelt_chart_path, f))
  ]))

  db_init_chart_path = "../helm/database-initialization"
  db_init_chart_hash = md5(join("", [
    for f in fileset(local.mbelt_chart_path, "**") :
    filemd5(format("%s/%s", local.mbelt_chart_path, f))
  ]))
}

data "local_file" "init-script" {
  filename = "./values/init-script.sql"
}

data "kubectl_path_documents" "crd-manifests" {
  pattern = "files/crd.yaml"
}

resource "kubectl_manifest" "victoriametrics-crd" {
  depends_on = [module.cluster]
  count      = length(data.kubectl_path_documents.crd-manifests.documents)
  yaml_body  = element(data.kubectl_path_documents.crd-manifests.documents, count.index)
}

resource "helm_release" "database-initialization" {
  depends_on = [kubernetes_namespace.mbelt_namespace, module.cluster, module.gke_auth]
  name       = "database-initialization"
  chart      = "../helm/database-initialization"
  namespace  = var.mbelt_namespace

  values = [
    file("./values/database-initialization.yaml"),
    yamlencode({
      mbelt_chart_hash : local.db_init_chart_hash,
    })
  ]

  set {
    name  = "database.db"
    value = module.cloud_sql.database_name
  }

  set {
    name  = "database.user"
    value = local.cloud_sql_postgres_user
  }

  set {
    name  = "database.pass"
    value = local.cloud_sql_postgres_password
  }

  set {
    name  = "database.host"
    value = module.cloud_sql.address
  }

  set {
    name  = "database.port"
    value = "5432"
  }

  set {
    name  = "init_script"
    value = replace(data.local_file.init-script.content, ",", "\\,")
  }
}

resource "helm_release" "rabbitmq" {
  depends_on = [kubernetes_namespace.mbelt_namespace, module.cluster, module.gke_auth]
  name       = "rabbitmq"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "rabbitmq"
  namespace  = var.mbelt_namespace

  set {
    name  = "auth.username"
    value = local.rabbitmq_username
  }

  set {
    name  = "auth.password"
    value = local.rabbitmq_password
  }

  values = [
    file("./values/rabbitmq.yaml")
  ]
}

resource "helm_release" "mbelt-preloader" {
  depends_on = [kubectl_manifest.victoriametrics-crd, helm_release.database-initialization, helm_release.rabbitmq]
  name       = "mbelt-preloader"
  chart      = "../helm/mbelt"
  namespace  = var.mbelt_namespace

  values = [
    file("./values/mbelt3/preloader.yaml"),
    yamlencode({
      mbelt_chart_hash : local.mbelt_chart_hash,
    })
  ]

  set {
    name  = "image.repository"
    value = local.mbelt_image_repository
  }

  set {
    name  = "image.tag"
    value = local.mbelt_image_tag
  }

  set {
    name  = "env.substrate_uri"
    value = local.polkadot_rpc_ws_url
  }

  set {
    name  = "env.rabbitmq_connection_string"
    value = "amqp://${local.rabbitmq_username}:${local.rabbitmq_password}@rabbitmq.mbelt3.svc.cluster.local:5672"
  }

  set {
    name  = "env.pg_connection_string"
    value = "postgresql://${local.cloud_sql_postgres_user}:${local.cloud_sql_postgres_password}@${module.cloud_sql.address}:5432/${var.mbelt_database_name}"
  }
}

resource "helm_release" "mbelt-block-processor" {
  depends_on = [helm_release.database-initialization, helm_release.rabbitmq, helm_release.mbelt-preloader]
  name       = "mbelt-block-processor"
  chart      = "../helm/mbelt"
  namespace  = var.mbelt_namespace

  values = [
    file("./values/mbelt3/block-processor.yaml"),
    yamlencode({
      mbelt_chart_hash : local.mbelt_chart_hash,
    })
  ]

  set {
    name  = "image.repository"
    value = local.mbelt_image_repository
  }

  set {
    name  = "image.tag"
    value = local.mbelt_image_tag
  }


  set {
    name  = "env.substrate_uri"
    value = local.polkadot_rpc_ws_url
  }

  set {
    name  = "env.rabbitmq_connection_string"
    value = "amqp://${local.rabbitmq_username}:${local.rabbitmq_password}@rabbitmq.mbelt3.svc.cluster.local:5672"
  }

  set {
    name  = "env.pg_connection_string"
    value = "postgresql://${local.cloud_sql_postgres_user}:${local.cloud_sql_postgres_password}@${module.cloud_sql.address}:5432/${var.mbelt_database_name}"
  }
}

resource "helm_release" "mbelt-staking-processsor" {
  depends_on = [helm_release.database-initialization, helm_release.rabbitmq, helm_release.mbelt-preloader, helm_release.mbelt-block-processor]
  name       = "mbelt-staking-processsor"
  chart      = "../helm/mbelt"
  namespace  = var.mbelt_namespace

  force_update = true
  replace      = true
  reset_values = true

  values = [
    file("./values/mbelt3/staking-processor.yaml"),
    yamlencode({
      mbelt_chart_hash : local.mbelt_chart_hash,
    })
  ]

  set {
    name  = "image.repository"
    value = local.mbelt_image_repository
  }

  set {
    name  = "image.tag"
    value = local.mbelt_image_tag
  }

  set {
    name  = "env.substrate_uri"
    value = local.polkadot_rpc_ws_url
  }

  set {
    name  = "env.rabbitmq_connection_string"
    value = "amqp://${local.rabbitmq_username}:${local.rabbitmq_password}@rabbitmq.mbelt3.svc.cluster.local:5672"
  }

  set {
    name  = "env.pg_connection_string"
    value = "postgresql://${local.cloud_sql_postgres_user}:${local.cloud_sql_postgres_password}@${module.cloud_sql.address}:5432/${var.mbelt_database_name}"
  }
}

resource "helm_release" "mbelt-balances-processor" {
  depends_on = [helm_release.database-initialization, helm_release.rabbitmq, helm_release.mbelt-preloader, helm_release.mbelt-block-processor]
  name       = "mbelt-balances-processor"
  chart      = "../helm/mbelt"
  namespace  = var.mbelt_namespace

  force_update = true
  replace      = true
  reset_values = true

  values = [
    file("./values/mbelt3/balances-processor.yaml"),
    yamlencode({
      mbelt_chart_hash : local.mbelt_chart_hash,
    })
  ]

  set {
    name  = "image.repository"
    value = local.mbelt_image_repository
  }

  set {
    name  = "image.tag"
    value = local.mbelt_image_tag
  }

  set {
    name  = "env.substrate_uri"
    value = local.polkadot_rpc_ws_url
  }

  set {
    name  = "env.rabbitmq_connection_string"
    value = "amqp://${local.rabbitmq_username}:${local.rabbitmq_password}@rabbitmq.mbelt3.svc.cluster.local:5672"
  }

  set {
    name  = "env.pg_connection_string"
    value = "postgresql://${local.cloud_sql_postgres_user}:${local.cloud_sql_postgres_password}@${module.cloud_sql.address}:5432/${var.mbelt_database_name}"
  }
}

resource "helm_release" "mbelt-identity-processor" {
  depends_on = [helm_release.database-initialization, helm_release.rabbitmq, helm_release.mbelt-preloader, helm_release.mbelt-block-processor]
  name       = "mbelt-identity-processor"
  chart      = "../helm/mbelt"
  namespace  = var.mbelt_namespace

  force_update = true
  replace      = true
  reset_values = true

  values = [
    file("./values/mbelt3/identity-processor.yaml"),
    yamlencode({
      mbelt_chart_hash : local.mbelt_chart_hash,
    })
  ]

  set {
    name  = "image.repository"
    value = local.mbelt_image_repository
  }

  set {
    name  = "image.tag"
    value = local.mbelt_image_tag
  }

  set {
    name  = "env.substrate_uri"
    value = local.polkadot_rpc_ws_url
  }

  set {
    name  = "env.rabbitmq_connection_string"
    value = "amqp://${local.rabbitmq_username}:${local.rabbitmq_password}@rabbitmq.mbelt3.svc.cluster.local:5672"
  }

  set {
    name  = "env.pg_connection_string"
    value = "postgresql://${local.cloud_sql_postgres_user}:${local.cloud_sql_postgres_password}@${module.cloud_sql.address}:5432/${var.mbelt_database_name}"
  }
}

resource "helm_release" "mbelt-monitoring" {
  depends_on = [helm_release.database-initialization, helm_release.rabbitmq, helm_release.mbelt-preloader, helm_release.mbelt-block-processor, helm_release.mbelt-staking-processsor]
  name       = "mbelt-monitoring"
  chart      = "../helm/mbelt"
  namespace  = var.mbelt_namespace

  force_update = true
  replace      = true
  reset_values = true

  values = [
    file("./values/mbelt3/monitoring.yaml"),
    yamlencode({
      mbelt_chart_hash : local.mbelt_chart_hash,
    })
  ]

  set {
    name  = "image.repository"
    value = local.mbelt_image_repository
  }

  set {
    name  = "image.tag"
    value = local.mbelt_image_tag
  }

  set {
    name  = "env.substrate_uri"
    value = local.polkadot_rpc_ws_url
  }

  set {
    name  = "env.rabbitmq_connection_string"
    value = "amqp://${local.rabbitmq_username}:${local.rabbitmq_password}@rabbitmq.mbelt3.svc.cluster.local:5672"
  }

  set {
    name  = "env.pg_connection_string"
    value = "postgresql://${local.cloud_sql_postgres_user}:${local.cloud_sql_postgres_password}@${module.cloud_sql.address}:5432/${var.mbelt_database_name}"
  }
}

data "template_file" "airflow_values" {
  template = file("${path.module}/values/airflow.yaml")
  vars = {
    bucket_name = google_storage_bucket.datalake.name
  }
}

resource "helm_release" "airflow" {
  depends_on = [helm_release.mbelt-preloader, helm_release.mbelt-block-processor, helm_release.mbelt-staking-processsor, kubernetes_secret.airflow-bigquery-sa-json, kubernetes_secret.airflow-fernet-key, kubernetes_secret.airflow-postgresql-metadata, kubernetes_secret.airflow-webserver-key]
  name       = "airflow"
  repository = "https://airflow.apache.org"
  chart      = "airflow"

  timeout   = 600
  namespace = var.airflow_namespace

  values = [
    data.template_file.airflow_values.rendered
  ]

  set {
    name  = "webserver.service.loadBalancerIP"
    value = module.cluster.ingress_static_ip_address
  }

  set {
    name  = "webserver.service.loadBalancerSourceRanges"
    value = "{${join(",", local.allowed_source_ranges)}}"
  }

  set {
    name  = "webserver.defaultUser.username"
    value = local.airflow_web_username
  }

  set {
    name  = "webserver.defaultUser.password"
    value = local.airflow_web_password
  }
}

data "template_file" "superset_values" {
  template = file("${path.module}/values/superset.yaml")
  vars = {
    service_account_name = var.service_account_name
    project_id           = local.project
  }
}

resource "helm_release" "superset" {
  depends_on = [kubernetes_namespace.superset_namespace]

  name  = "superset"
  chart = "../helm/superset"

  timeout   = 600
  namespace = var.superset_namespace

  values = [
    data.template_file.superset_values.rendered
  ]

  set {
    name  = "service.loadBalancerIP"
    value = module.cluster.ingress_static_ip_address
  }

  set {
    name  = "service.loadBalancerSourceRanges"
    value = "{${join(",", local.allowed_source_ranges)}}"
  }

  set {
    name  = "googleProjectId"
    value = local.project
  }

  set {
    name  = "supersetNode.connections.db_host"
    value = module.cloud_sql.address
  }

  set {
    name  = "supersetNode.connections.db_port"
    value = "5432"
  }

  set {
    name  = "supersetNode.connections.db_user"
    value = local.cloud_sql_postgres_user
  }

  set {
    name  = "supersetNode.connections.db_pass"
    value = local.cloud_sql_postgres_password
  }

  set {
    name  = "supersetNode.connections.db_name"
    value = var.superset_database_name
  }


  set {
    name  = "init.adminUser.username"
    value = local.superset_web_username
  }

  set {
    name  = "init.adminUser.password"
    value = local.superset_web_password
  }
}
