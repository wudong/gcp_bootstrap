provider "google" {
}

provider "random" {}
// create a gcp project

resource "random_id" "project_id" {
  byte_length = 4
}

locals {
  uid = lower(random_id.project_id.hex)
}

resource "google_project" "main" {
  project_id      = "gcp-${local.uid}"
  name            = "wudong-cloud-${local.uid}"
  billing_account = var.gcp_billing_acc
}

resource "google_service_account" "build_sa" {
  project      = google_project.main.project_id
  account_id   = "buildsa"
  display_name = "Service Account for Github Action Pipeline"
}

resource "google_project_iam_member" "assign_sa_owner_role" {
  project = google_project.main.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.build_sa.email}"
}

resource "time_rotating" "build_sa_key_rotation" {
  rotation_days = 7 // rotate the key every 7 days.
}

resource "google_service_account_key" "github_action_secret" {
  service_account_id = google_service_account.build_sa.name
  keepers = {
    rotation_time = time_rotating.build_sa_key_rotation.rotation_rfc3339
  }
}

resource "google_storage_bucket" "tf_state_bucket" {
  project                     = google_project.main.project_id
  name                        = "${google_project.main.project_id}-tf-state"
  location                    = "EU"
  force_destroy               = true
  uniform_bucket_level_access = true
}