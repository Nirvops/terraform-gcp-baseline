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
}