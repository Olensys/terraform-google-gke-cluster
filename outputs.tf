output "id" {
  description = "Cluster ID (projects/<project>/locations/<region>/clusters/<name>). Null when create is false."
  value       = var.create ? module.this[0].cluster_id : null
}

output "name" {
  description = "Cluster name. Null when create is false."
  value       = var.create ? module.this[0].name : null
}

output "self_link" {
  description = "Relative resource path of the cluster. Null when create is false."
  value       = var.create ? "projects/${var.project_id}/locations/${var.region}/clusters/${var.name}" : null
}

output "endpoint" {
  description = "Public control plane endpoint. Null when create is false."
  value       = var.create ? module.this[0].endpoint : null
  sensitive   = true
}

output "ca_certificate" {
  description = "Base64-encoded cluster CA certificate. Null when create is false."
  value       = var.create ? module.this[0].ca_certificate : null
  sensitive   = true
}

output "workload_identity_pool" {
  description = "Workload Identity pool (<project>.svc.id.goog). Null when Workload Identity is disabled or create is false."
  value       = var.create ? local.workload_identity_pool : null
}

output "node_pool_names" {
  description = "Names of the node pools. Null when create is false."
  value       = var.create ? module.this[0].node_pools_names : null
}

output "labels" {
  description = "Labels applied to the cluster, with context.extra_tags merged in. Null when create is false."
  value       = var.create ? local.labels : null
}

output "node_pools_config" {
  description = "Node pool list passed to the upstream module (all values are strings). Null when create is false."
  value       = var.create ? local.node_pools_config : null
}

output "private_cluster_config" {
  description = "Private cluster settings passed to the upstream module. Null when create is false."
  value       = var.create ? local.private_cluster_config : null
}

output "maintenance_config" {
  description = "Maintenance window passed to the upstream module. Null when create is false."
  value = var.create ? {
    start_time = var.maintenance_window.start_time
    end_time   = var.maintenance_window.end_time
    recurrence = var.maintenance_window.recurrence
  } : null
}

output "deletion_protection" {
  description = "Whether Terraform is prevented from destroying the cluster (true in prod). Null when create is false."
  value       = var.create ? local.deletion_protection : null
}
