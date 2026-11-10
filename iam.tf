# Create a Google Cloud Service Account
resource "google_service_account" "gke_nodes" {
  account_id   = "gke-cluster-nodes-sa"
  display_name = "Service Account pour les nœuds du Cluster GKE"
}

# List of minimum IAM roles required for GKE instances
variable "gke_node_roles" {
  type = list(string)
  default = [
    "roles/logging.logWriter",       # Allows sending logs to Cloud Logging
    "roles/monitoring.metricWriter", # Allows sending metrics to Cloud Monitoring
    "roles/monitoring.viewer",       # Allows the node to self-monitor
  ]
}

# Assigning roles to the service account
resource "google_project_iam_member" "gke_nodes_binding" {
  for_each = toset(var.gke_node_roles)

  project = var.gcp_project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}
