terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.39, < 8.0"
    }
  }
}

variable "project_id" {
  description = "Project that hosts the cluster."
  type        = string
}

variable "network_name" {
  description = "Name of an existing VPC network."
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnetwork to place the cluster in."
  type        = string
}

variable "pods_range_name" {
  description = "Secondary range name for pods."
  type        = string
}

variable "services_range_name" {
  description = "Secondary range name for services."
  type        = string
}

module "this" {
  source = "../../"

  name       = "example"
  project_id = var.project_id
  region     = "us-central1"
  context = {
    organization = "olensys"
    environment  = "test"
    application  = "example"
    owner        = "platform"
    cost_center  = "eng"
  }

  network = {
    name                = var.network_name
    subnet_name         = var.subnet_name
    pods_range_name     = var.pods_range_name
    services_range_name = var.services_range_name
  }

  node_pools = {
    default = {
      machine_type = "e2-standard-4"
      min_count    = 1
      max_count    = 3
    }
  }
}

output "cluster_name" {
  description = "Name of the cluster."
  value       = module.this.name
}
