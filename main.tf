resource "random_string" "random" {
  length  = 16
  special = false
}

resource "google_cloud_run_service" "default" {
  name     = replace("pubsub_to_bq_${split(".", var.bigquery_table)[2]}_${lower(random_string.random.result)}", "_", "-")
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project}/pubsub-to-bq-consumer:latest"
        env {
          name  = "TABLE_ID"
          value = var.bigquery_table
        }
        resources {
          limits = {
            memory = "256Mi"
            cpu    = "1000m"
          }
        }
      }
      service_account_name = google_service_account.sa.email
    }
    metadata {
      annotations = {
        "run.googleapis.com/ingress"       = "all"
        "autoscaling.knative.dev/minScale" = "0"
        "autoscaling.knative.dev/maxScale" = "10"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_pubsub_subscription" "default" {
  name  = "pubsub_to_bq_${split(".", var.bigquery_table)[2]}_${lower(random_string.random.result)}"
  topic = var.topic_name
  push_config {
    oidc_token {
      service_account_email = google_service_account.sa.email
    }
    push_endpoint = one(google_cloud_run_service.default.status)["url"]
  }
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "serviceAccount:${google_service_account.sa.email}",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.default.location
  project     = var.project
  service     = google_cloud_run_service.default.name
  policy_data = data.google_iam_policy.noauth.policy_data
}
