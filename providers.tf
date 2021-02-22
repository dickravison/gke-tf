provider "google" {
  credentials = file(".creds/gcp-sa-key.json")
  project     = var.project
  region      = var.region
}

provider "google-beta" {
  credentials = file(".creds/gcp-sa-key.json")
  project     = var.project
  region      = var.region
}

