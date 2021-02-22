resource "google_service_account" "default" {
  account_id   = "${var.project}-gke-sa-id"
  display_name = "GKE Service Account"
  description = "Service account for GKE"
}

locals {
  all_service_account_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer"
  ]
}

resource "google_project_iam_member" "service_account-roles" {
  for_each = toset(local.all_service_account_roles)

  project = var.project
  role    = each.value
  member  = "serviceAccount:${google_service_account.default.email}"
}

resource "google_container_cluster" "cluster" {
  provider = google-beta
  name     = "${var.project}-gke"
  location = "${var.region}-a"
  node_locations = ["${var.region}-b", "${var.region}-c"]

  remove_default_node_pool = true
  initial_node_count       = 1

  private_cluster_config {
    enable_private_nodes   = true
    enable_private_endpoint = true
    master_ipv4_cidr_block = var.master_ipv4_cidr_range
  }

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.cluster_subnet.name

  networking_mode = "VPC_NATIVE"

  ip_allocation_policy {
    cluster_ipv4_cidr_block = ""
    services_ipv4_cidr_block = ""
  }

  master_auth {
    username = var.gke_username
    password = var.gke_password

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  master_authorized_networks_config {
      cidr_blocks {
          cidr_block   = "10.0.0.0/16"
          display_name = "internal-testing"
        }      
    }
}

resource "google_container_node_pool" "default_nodes" {
  name       = "${google_container_cluster.cluster.name}-default-node-pool"
  location   = google_container_cluster.cluster.location
  cluster    = google_container_cluster.cluster.name
  initial_node_count = 1

  node_config {
    service_account = google_service_account.default.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    labels = {
      env = var.project
      node = "default"
    }

    disk_size_gb = "20"
    preemptible  = true
    machine_type = "g1-small"
    tags         = ["gke-node-default", "${var.project}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "${google_container_cluster.cluster.name}-preemptible-node-pool"
  location   = google_container_cluster.cluster.location
  cluster    = google_container_cluster.cluster.name
  autoscaling {
     min_node_count = 0
     max_node_count = 3
  }


  node_config {
    service_account = google_service_account.default.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    labels = {
      env = var.project
      node = "preemptible"
    }

    disk_size_gb = "30"
    preemptible  = true
    machine_type = "n1-standard-1"
    tags         = ["gke-node-preemptible", "${var.project}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

resource "google_container_node_pool" "performance_nodes" {
  name       = "${google_container_cluster.cluster.name}-performance-pool"
  location   = google_container_cluster.cluster.location 
  cluster    = google_container_cluster.cluster.name
  autoscaling {
     min_node_count = 0
     max_node_count = 3
  }

  node_config {
    service_account = google_service_account.default.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    labels = {
      env = var.project
      node = "performance"
    }

    disk_size_gb = "30"
    machine_type = "n2-standard-4"
    tags         = ["gke-node-performance", "${var.project}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

