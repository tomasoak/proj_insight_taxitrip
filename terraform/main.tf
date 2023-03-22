terraform {
  required_version = ">= 1.0"
  backend "local" {}  # Can change from "local" to "gcs" (for google) or "s3" (for aws), if you would like to preserve your tf-state online
  required_providers {
    google = {
      source  = "hashicorp/google"
    }
  }
}


provider "google" {
  project = var.project
  region = var.region
  # credentials = var.credentials  # Use this if you do not want to set env-var GOOGLE_APPLICATION_CREDENTIALS
  # export GOOGLE_APPLICATION_CREDENTIALS="~/proj_cloud_elt/CREDENTIALS.json"
}

resource "google_project_service" "composer_api" {
  provider = google
  project = var.project
  service = "composer.googleapis.com"
  // Disabling Cloud Composer API might irreversibly break all other
  // environments in your project.
  disable_on_destroy = false
}

resource "google_service_account" "custom_service_account" {
  provider = google
  account_id   = "custom-service-account"
  display_name = "Terraform Custom Service Account"
  description = "Service account for Terraform use to create Cloud Composer"
}


resource "google_project_iam_member" "custom_service_account" {
  provider = google
  project = var.project
  role    = "roles/composer.worker"   // Role for Public IP environments
  member   = format("serviceAccount:%s", google_service_account.custom_service_account.email)
}


resource "google_service_account_iam_member" "custom_service_account" {
  provider = google
  service_account_id = google_service_account.custom_service_account.name
  role = "roles/composer.ServiceAgentV2Ext"
  member = "serviceAccount:service-1080395977432@cloudcomposer-accounts.iam.gserviceaccount.com"
}


resource "google_composer_environment" "example-environment" {
    provider = google
    name = "example-environment"
    region = var.region
    project = var.project

    config {
        environment_size = "ENVIRONMENT_SIZE_SMALL"

        software_config {
          image_version = "composer-2.1.10-airflow-2.4.3"
        }

        node_config {
          service_account = google_service_account.custom_service_account.email
        }

        workloads_config {
            scheduler {
                cpu        = 0.5
                memory_gb  = 1.875
                storage_gb = 1
                count      = 1
            }
            web_server {
                cpu        = 0.5
                memory_gb  = 1.875
                storage_gb = 1
            }
            worker {
                cpu = 0.5
                memory_gb  = 1.875
                storage_gb = 1
                min_count  = 1
                max_count  = 3
            }
      }
  }
}

# resource "google_compute_network" "custom_service_account" {
#   name                    = "composer-ex-network3"
#   auto_create_subnetworks = false
# }

# resource "google_compute_subnetwork" "custom_service_account" {
#   name          = "composer-ex-subnetwork"
#   ip_cidr_range = "10.2.0.0/16"
#   region        = var.region
#   network       = google_compute_network.custom_service_account.id
# }