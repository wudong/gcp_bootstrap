provider "google" {
}

provider "random" {}
// create a gcp project

resource "random_id" "project_id" {
  byte_length = 4
}

locals {
  uid = random_id.project_id.id
}

resource "google_project" "main" {
  project_id = "gcp_${uid}"
  name = "wudong-cloud-${uid}"
}

resource "google_service_account" "build_sa" {
  account_id = "build_sa"
  display_name = "Service Account for Github Action Pipeline"
}

resource "google_project_iam_binding" "assign_sa_owner_role" {
  project =google_project.main.project_id
  role = "roles/owner"
  members = [
    "serviceAccount:${google_service_account.build_sa.email}"
  ]
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
  name = "${google_project.main.project_id}-tf-state"
  location = "EU"
  force_destroy = true
  uniform_bucket_level_access = true
}