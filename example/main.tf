variable "project" {}

variable "region" {
  default = "europe-west3"
}

variable "zone" {
  default = "europe-west3-c"
}

resource "google_project_service" "project" {
  project                    = var.project
  service                    = "dataflow.googleapis.com"
  disable_dependent_services = false
}

locals {
  schema = [
    {
      name : "i",
      type : "INTEGER",
      mode : "NULLABLE",
    },
  ]
}

resource "google_pubsub_topic" "example" {
  name = "pubsub_to_bq_example_topic"
}

resource "google_cloud_scheduler_job" "job" {
  name        = "test-job"
  description = "test job"
  schedule    = "* * * * *"
  region      = "us-central1"

  pubsub_target {
    topic_name = google_pubsub_topic.example.id
    data       = base64encode("{\"i\": 1}")
  }
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id = "pubsub_to_bq_example_dataset"
  location   = "EU"
}

resource "google_bigquery_table" "table" {
  dataset_id          = google_bigquery_dataset.dataset.dataset_id
  table_id            = "test_table"
  deletion_protection = false

  schema = jsonencode(local.schema)
}

module "pubsub_to_bq" {
  source         = "../"
  bigquery_table = "${var.project}.${google_bigquery_table.table.dataset_id}.${google_bigquery_table.table.table_id}"
  topic_name     = google_pubsub_topic.example.name
  region         = var.region
  project        = var.project
}
