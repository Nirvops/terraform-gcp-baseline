variable "gcp_project_id" {
  type        = string
  description = "The unique alphanumeric ID of the Google Cloud Project where resources will be deployed."
}

variable "gcp_region" {
  type    = string
  default = "europe-west6" # Switzerland
}

variable "gcp_zone" {
  type    = string
  default = "europe-west6-b"
}

