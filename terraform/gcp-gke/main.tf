locals {
  apis = [
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
  ]
}

resource "google_project_service" "apis" {
  for_each = toset(local.apis)

  service = each.value
  # Leave the APIs enabled on destroy: other things in the project may use
  # them, and re-disabling is slow and can fail on dependent services.
  disable_on_destroy = false
}

# --- Network ---------------------------------------------------------------
# A dedicated VPC with secondary ranges for pods and services (VPC-native).
resource "google_compute_network" "main" {
  name                    = "${var.cluster_name}-vpc"
  auto_create_subnetworks = false

  depends_on = [google_project_service.apis]
}

resource "google_compute_subnetwork" "nodes" {
  name          = "${var.cluster_name}-nodes"
  region        = var.region
  network       = google_compute_network.main.id
  ip_cidr_range = cidrsubnet(var.vpc_cidr, 8, 0)

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = cidrsubnet(var.vpc_cidr, 2, 1)
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = cidrsubnet(var.vpc_cidr, 4, 8)
  }
}

# --- Image registry --------------------------------------------------------
resource "google_artifact_registry_repository" "app" {
  location      = var.region
  repository_id = var.registry_name
  format        = "DOCKER"
  description   = "Darviq demo app images"

  depends_on = [google_project_service.apis]
}

# --- GKE -------------------------------------------------------------------
# Autopilot: Google manages the nodes and bills per pod resource request, so
# there's no node pool to size. It also enforces NetworkPolicy (Dataplane V2),
# which k8s/base relies on.
resource "google_container_cluster" "main" {
  name     = var.cluster_name
  location = var.region

  enable_autopilot = true

  # A demo cluster meant to be torn down with `terraform destroy`;
  # deletion protection would just block that.
  deletion_protection = false

  release_channel {
    channel = "REGULAR"
  }

  network    = google_compute_network.main.id
  subnetwork = google_compute_subnetwork.nodes.id

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  depends_on = [google_project_service.apis]
}
