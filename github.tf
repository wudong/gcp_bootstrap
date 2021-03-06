provider "github" {
  token = var.github_token
  owner = var.github_owner
}

resource "github_repository" "infra" {
  name       = "infra"
  visibility = "public"
  auto_init  = true
}

resource "github_branch" "dev" {
  repository = github_repository.infra.name
  branch     = "dev"
}

resource "github_branch_default" "default" {
  repository = github_repository.infra.name
  branch     = github_branch.dev.branch
}

resource "github_actions_secret" "build_sa" {
  repository  = github_repository.infra.name
  secret_name = "GCP_SA_KEY"
  //this save the json key into the secret
  plaintext_value = base64decode(google_service_account_key.github_action_secret.private_key)
}

resource "github_actions_secret" "project_id" {
  repository      = github_repository.infra.name
  secret_name     = "GCP_PROJECT_ID"
  plaintext_value = google_project.main.project_id
}

resource "github_repository_file" "tf_action_file" {
  repository = github_repository.infra.name
  branch     = github_branch.dev.branch
  file       = ".github/workflows/terraform.yml"

  content = file("${path.module}/files/terraform.yml")

}

resource "github_repository_file" "tf_main_file" {
  repository = github_repository.infra.name
  branch     = github_branch.dev.branch
  file       = "main.tf"

  content = templatefile("${path.module}/files/main.tf", {
    bucket_name = google_storage_bucket.tf_state_bucket.name
  })

}