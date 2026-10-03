variable "project_id" {
  description = "GCP project ID to deploy into (billing must already be enabled on it)."
  type        = string
}

variable "region" {
  description = "Region for the network, Autopilot cluster and Artifact Registry repository."
  type        = string
  default     = "asia-south1"
}

variable "cluster_name" {
  description = "Name of the GKE Autopilot cluster."
  type        = string
  default     = "darviq-gke"
}

variable "vpc_cidr" {
  description = "Base range for the VPC: nodes, pods and services are carved from it."
  type        = string
  default     = "10.42.0.0/16"
}

variable "registry_name" {
  description = "Artifact Registry repository ID for the app image."
  type        = string
  default     = "darviq-demo"
}
