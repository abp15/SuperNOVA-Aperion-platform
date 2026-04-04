# 0. Provider & Variables Setup
provider "google" {
  project = var.project_id
  region  = var.region
}

# --- NEW: Enable Required APIs via Terraform ---
resource "google_project_service" "services" {
  for_each = toset([
    "artifactregistry.googleapis.com",
    "servicenetworking.googleapis.com", # Fixes your current error
    "redis.googleapis.com",
    "container.googleapis.com",
    "iamcredentials.googleapis.com"     # Required for GitHub Actions
  ])
  service            = each.key
  disable_on_destroy = false
}

# 1. VPC Network
resource "google_compute_network" "vpc" {
  name                    = "supernova-vpc"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.services]
}

# 2. Subnet with Secondary Ranges
resource "google_compute_subnetwork" "subnet" {
  name          = "supernova-gke-subnet"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.0.0.0/20"

  secondary_ip_range {  
    range_name    = "pod-range"
    ip_cidr_range = "10.1.0.0/16"
  }
  secondary_ip_range {
    range_name    = "service-range"
    ip_cidr_range = "10.2.0.0/20"
  }
}

# 3. GKE Cluster
resource "google_container_cluster" "primary" {
  name     = "supernova-cluster"
  location = var.region

  deletion_protection = false

  remove_default_node_pool = true
  initial_node_count       = 1
  network                  = google_compute_network.vpc.name
  subnetwork               = google_compute_subnetwork.subnet.name

  ip_allocation_policy {
    cluster_secondary_range_name  = "pod-range"
    services_secondary_range_name = "service-range"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

# 4. Custom Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "supernova-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = 1 

  node_config {
    machine_type = "e2-standard-4" 
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    labels       = { env = "dev" }
    service_account = google_service_account.gke_sa.email   
  }
}

# 5. Service Account for Nodes
resource "google_service_account" "gke_sa" {
  account_id   = "supernova-gke-sa"
  display_name = "GKE Node Service Account"
}

# 5.5 Private Service Access (Fixes the Error)
resource "google_compute_global_address" "private_ip_alloc" {
  name          = "google-managed-services-supernova-vpc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
  depends_on              = [google_project_service.services]
}

# 6. Google Memorystore (Redis)
resource "google_redis_instance" "chat_cache" {
  name               = "supernova-memory-cache"
  tier               = "BASIC" 
  memory_size_gb     = 1
  region             = var.region
  authorized_network = google_compute_network.vpc.id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"
  
  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# --- NEW: Workload Identity for CI/CD Pipeline ---
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "supernova-pool"
  display_name              = "SuperNOVA GitHub Pool"
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Export the Redis IP
output "redis_ip" {
  value = google_redis_instance.chat_cache.host
}
