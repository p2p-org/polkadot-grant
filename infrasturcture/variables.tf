variable "region" {
  description = "Region"
  type        = string
  default     = "europe-west3"
}

variable "zone" {
  description = "Zone"
  type        = string
  default     = "europe-west3-a"
}

variable "project_prefix" {
  type    = string
  default = "polkadot-monitoring-system"
}

variable "cloud_sql_ssl_enabled" {
  type    = bool
  default = false
}

variable "airflow_database_name" {
  type    = string
  default = "airflow"
}

variable "mbelt_database_name" {
  type    = string
  default = "mbelt"
}

variable "superset_database_name" {
  type    = string
  default = "superset"

}

variable "mbelt_namespace" {
  type    = string
  default = "mbelt3"
}

variable "airflow_namespace" {
  type    = string
  default = "airflow"
}

variable "superset_namespace" {
  type    = string
  default = "superset"
}

variable "service_account_name" {
  type    = string
  default = "bigquery-sa"
}
