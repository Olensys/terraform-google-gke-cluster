locals {
  labels = merge(var.context.extra_tags, var.labels)

  deletion_protection = var.context.environment == "prod"

  # GKE_METADATA requires Workload Identity.
  node_metadata = var.enable_workload_identity ? "GKE_METADATA" : "UNSPECIFIED"

  workload_identity_pool = var.enable_workload_identity ? "${var.project_id}.svc.id.goog" : null

  # Upstream takes a list of maps and treats every value as a string.
  node_pools_config = [
    for pool_name, p in var.node_pools : {
      name               = pool_name
      machine_type       = p.machine_type
      min_count          = tostring(p.min_count)
      max_count          = tostring(p.max_count)
      disk_size_gb       = tostring(p.disk_size_gb)
      spot               = tostring(p.spot)
      auto_upgrade       = "true"
      auto_repair        = "true"
      image_type         = "COS_CONTAINERD"
      enable_secure_boot = "true"
    }
  ]

  node_pools_labels = merge(
    { all = {} },
    { for pool_name, p in var.node_pools : pool_name => p.labels },
  )

  node_pools_taints = merge(
    { all = [] },
    { for pool_name, p in var.node_pools : pool_name => p.taints },
  )

  private_cluster_config = {
    private_nodes    = true
    private_endpoint = false
    master_cidr      = var.master_cidr

    public_cidrs_access_enabled = false
    authorized_networks         = var.authorized_networks
  }
}

module "this" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "46.0.0"

  count = var.create ? 1 : 0

  project_id        = var.project_id
  name              = var.name
  region            = var.region
  regional          = true
  network           = var.network.name
  subnetwork        = var.network.subnet_name
  ip_range_pods     = var.network.pods_range_name
  ip_range_services = var.network.services_range_name

  enable_private_nodes    = local.private_cluster_config.private_nodes
  enable_private_endpoint = local.private_cluster_config.private_endpoint
  master_ipv4_cidr_block  = var.master_cidr

  master_authorized_networks = local.private_cluster_config.authorized_networks

  # Always render master_authorized_networks_config; without this an empty list leaves the endpoint open.
  gcp_public_cidrs_access_enabled = local.private_cluster_config.public_cidrs_access_enabled

  # DNS-based endpoint stays closed to external traffic (the provider default, set explicitly).
  dns_allow_external_traffic = false

  release_channel       = var.release_channel
  datapath_provider     = "ADVANCED_DATAPATH"
  network_policy        = false
  enable_shielded_nodes = true

  identity_namespace = var.enable_workload_identity ? "enabled" : null
  node_metadata      = local.node_metadata

  remove_default_node_pool = true
  initial_node_count       = 1

  node_pools        = local.node_pools_config
  node_pools_labels = local.node_pools_labels
  node_pools_taints = local.node_pools_taints

  maintenance_start_time = var.maintenance_window.start_time
  maintenance_end_time   = var.maintenance_window.end_time
  maintenance_recurrence = var.maintenance_window.recurrence

  logging_enabled_components    = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  monitoring_enabled_components = ["SYSTEM_COMPONENTS"]

  horizontal_pod_autoscaling = true
  http_load_balancing        = true

  deletion_protection     = local.deletion_protection
  cluster_resource_labels = local.labels
}
