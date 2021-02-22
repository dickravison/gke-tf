variable "project" {
  description = "Project ID"
}

variable "region" {
  description = "Region to deploy this in"
}

variable "cluster_cidr_range" {
  description = "CIDR range for the cluster nodes"
}

variable "master_ipv4_cidr_range" {
  description = "CIDR range for the master nodes"
}

variable "gke_username" {
  description = "Username for master auth"
}

variable "gke_password" {
  description = "Password for master auth"
}
