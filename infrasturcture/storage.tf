resource "google_compute_disk" "dags_disk" {
  name  = "dags-gce-disk"
  size  = 2
  type  = "pd-standard"
}

resource "random_id" "bucket_prefix" {
  byte_length = 8
}

resource "google_storage_bucket" "datalake" {
  name          = "mbelt3-airflow-bucket-${random_id.bucket_prefix.hex}"
  location      = var.region

  storage_class = "STANDARD"
  uniform_bucket_level_access = true

  force_destroy = true
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id = "mbelt3_raw_data"
  project    = var.project
  location   = var.region
}
