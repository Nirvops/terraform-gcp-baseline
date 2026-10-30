# Defines the required Terraform version and global settings
terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Specifies which cloud or service provider GCP
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}

# Represents the actual infrastructure components
resource "google_compute_network" "vpc_network" {
  name                    = "my-custom-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "vpc_subnet" {
  name          = "my-custom-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.gcp_region
  network       = google_compute_network.vpc_network.id

  # Secondary range dedicated solely to Kubernetes Pods
  secondary_ip_range {
    range_name    = "my-custom-gke-pods-range"
    ip_cidr_range = "10.4.0.0/14"
  }

  # Secondary range dedicated solely to Kubernetes Services
  secondary_ip_range {
    range_name    = "my-custom-gke-services-range"
    ip_cidr_range = "10.8.0.0/20"
  }
}

resource "google_container_cluster" "primary" {
  name     = "my-custom-gke-cluster"
  location = var.gcp_zone
  remove_default_node_pool = true
  initial_node_count       = 1

  deletion_protection      = false

  network    = google_compute_network.vpc_network.id
  subnetwork = google_compute_subnetwork.vpc_subnet.id

  ip_allocation_policy {
    cluster_secondary_range_name  = "my-custom-gke-pods-range"
    services_secondary_range_name = "my-custom-gke-services-range"
  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "my-custom-node-pool"
  location   = var.gcp_zone
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-small"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.gke_nodes.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  depends_on = [google_project_iam_member.gke_nodes_binding]
}