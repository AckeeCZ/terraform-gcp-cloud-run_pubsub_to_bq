data "google_project" "project" {
  project_id = var.project
}

resource "google_service_account" "sa" {
  account_id = "pubsubtobq-${lower(random_string.random.result)}"
}

resource "google_pubsub_topic_iam_member" "sa_subscriber" {
  topic  = var.topic_name
  role   = "roles/pubsub.subscriber"
  member = "serviceAccount:${google_service_account.sa.email}"
}

resource "google_project_iam_member" "sa_bigquery" {
  project = var.project
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.sa.email}"
}

resource "google_project_iam_member" "sa_token_creator" {
  project = var.project
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}
