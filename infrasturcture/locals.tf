locals {
    kube_config_filepath = pathexpand("~/.kube/kubeconfig-${var.project_prefix}")

    raw_settings = yamldecode(file("../values.yaml"))
    allowed_source_ranges = flatten([
        for obj in try(local.raw_settings.authorizedNetworks, []) :
            obj.address
    ])

    k8s_allowed_source_ranges = flatten([
        for obj in try(local.raw_settings.authorizedNetworks, []) : {
            display_name = obj.name
            cidr_block = obj.address
        }
    ])

    authorized_networks = try(local.raw_settings.authorizedNetworks, [])

    airflow_web_username = try(local.raw_settings.airflow.username, "admin")
    airflow_web_password = try(local.raw_settings.airflow.password, "airflowpassword")
    airflow_fernet_key = try(local.raw_settings.airflow.fernetKey, "uDomk3Z8NA63jKaJoNEExhNFA_4gNhRHumuCJ_O-6DU=")
    airflow_webserver_key = try(local.raw_settings.airflow.webserverKey, "webserverkey")
    airflow_dag_vars      = try(local.raw_settings.airflow.dagVars, "{\"env_mode\": \"prod\", \"airflow_home_dir\": \"/opt/airflow\", \"airflow_output\": \"/opt/airflow/output\", \"gcp_conn_id\": \"de\", \"dbt_bin\": \"/opt/airflow/.local/bin/dbt\", \"dbt_project_dir\": \"/opt/airflow/p2p\", \"dbt_profiles_dir\": \"/opt/airflow/.dbt\", \"bq_dataset\": \"mbelt3_raw_data\",  \"bq_project_id\": \"${var.project}\"}")

    service_account_token = local.raw_settings.serviceAccountToken
    service_account_name = try(local.raw_settings.serviceAccountName, "")

    polkadot_rpc_ws_url = try(local.raw_settings.polkadotWSRPCUrl, "wss://rpc.polkadot.io/")

    mbelt_image_repository  = try(local.raw_settings.mbelt.repository, "altvnv/mbelt_preloader")
    mbelt_image_tag         = try(local.raw_settings.mbelt.tag, "77bc8650")

    cloud_sql_postgres_user     = try(local.raw_settings.database.username, "pguser")
    cloud_sql_postgres_password = try(local.raw_settings.database.password, "pgpassword")

    rabbitmq_username = try(local.raw_settings.rabbitmq.username, "rabbitmq")
    rabbitmq_password = try(local.raw_settings.rabbitmq.password, "rabbitmqpassword")

    superset_web_username = try(local.raw_settings.superset.username, "admin")
    superset_web_password = try(local.raw_settings.superset.password, "supersetpassword")
    superset_secret_key = try(local.raw_settings.superset.secretKey, "superSecretKey")

}
