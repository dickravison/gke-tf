resource "google_compute_network" "vpc" {
  name                    = "${var.project}-vpc"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "cluster_subnet" {
  name          = "${var.project}-cluster-subnet"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = var.cluster_cidr_range
  private_ip_google_access = true
}

resource "google_compute_router" "router" {
  name = "${var.project}-nat-router"
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name = "${var.project}-nat-gw"
  region = var.region
  router = google_compute_router.router.name
  nat_ip_allocate_option = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
