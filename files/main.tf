terraform {
  backend "gcs" {
    bucket = "${bucket_name}"
    prefix = "terraform/state"
  }
}

resource "null_resource" "null" {
  triggers = {
    value = "Doing nothing!"
  }
}