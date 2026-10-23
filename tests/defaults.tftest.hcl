mock_provider "google" {
  mock_data "google_compute_zones" {
    defaults = {
      names = ["us-central1-a", "us-central1-b", "us-central1-c"]
    }
  }
  mock_data "google_container_engine_versions" {
    defaults = {
      latest_master_version = "1.33.0-gke.1000"
      latest_node_version   = "1.33.0-gke.1000"
      release_channel_default_version = {
        RAPID   = "1.33.0-gke.1000"
        REGULAR = "1.33.0-gke.1000"
        STABLE  = "1.33.0-gke.1000"
      }
    }
  }
  mock_resource "google_service_account" {
    defaults = {
      email  = "gke@example-project.iam.gserviceaccount.com"
      member = "serviceAccount:gke@example-project.iam.gserviceaccount.com"
    }
  }
}

variables {
  context = {
    organization = "olensys"
    environment  = "test"
    application  = "example"
    owner        = "platform"
    cost_center  = "eng"
  }
  name       = "example"
  project_id = "example-project"
  region     = "us-central1"
  network = {
    name                = "example-net"
    subnet_name         = "example-subnet"
    pods_range_name     = "pods"
    services_range_name = "services"
  }
  node_pools = {
    default = {}
  }
}

run "test_private_nodes" {
  command = plan

  # SMOKE: asserts the wrapper passes private_nodes=true, private_endpoint=false and the master CIDR to
  # upstream; the cluster resource is inside the child module, so the real check is complete.tftest.hcl and trivy.
  assert {
    condition = (
      output.private_cluster_config.private_nodes == true
      && output.private_cluster_config.private_endpoint == false
      && output.private_cluster_config.master_cidr == "172.16.0.0/28"
    )
    error_message = "Nodes must be private, endpoint public, master CIDR 172.16.0.0/28."
  }
}

run "test_workload_identity_on" {
  command = plan

  # SMOKE: asserts the pool string the wrapper derives; the workload_identity_config block lives in the
  # upstream cluster resource and is proven by complete.tftest.hcl.
  assert {
    condition     = output.workload_identity_pool == "example-project.svc.id.goog"
    error_message = "Workload Identity pool must be <project>.svc.id.goog by default."
  }
}

run "test_workload_identity_off" {
  command = plan

  variables {
    enable_workload_identity = false
  }

  assert {
    condition     = output.workload_identity_pool == null
    error_message = "No pool when Workload Identity is disabled."
  }

  assert {
    condition     = output.node_metadata == "UNSPECIFIED"
    error_message = "Node metadata must not be GKE_METADATA without Workload Identity."
  }
}

run "test_authorized_networks_wired" {
  command = plan

  # SMOKE: asserts the values handed to upstream; the rendered master_authorized_networks_config is proven by
  # complete.tftest.hcl.
  variables {
    authorized_networks = [{ cidr_block = "203.0.113.0/24", display_name = "office" }]
  }

  assert {
    condition = (
      output.private_cluster_config.public_cidrs_access_enabled == false
      && length(output.private_cluster_config.authorized_networks) == 1
      && output.private_cluster_config.authorized_networks[0].cidr_block == "203.0.113.0/24"
    )
    error_message = "Authorized networks must be passed and public CIDR access disabled."
  }
}

run "test_authorized_networks_empty_still_closed" {
  command = plan

  assert {
    condition     = output.private_cluster_config.public_cidrs_access_enabled == false && length(output.private_cluster_config.authorized_networks) == 0
    error_message = "Empty authorized_networks must still render a closed authorized-networks block."
  }
}

run "test_node_pools_empty_rejected" {
  command = plan

  variables {
    node_pools = {}
  }

  expect_failures = [var.node_pools]
}

run "test_name_must_start_with_letter" {
  command = plan

  variables {
    name = "1bad"
  }

  expect_failures = [var.name]
}

run "test_release_channel_validation" {
  command = plan

  variables {
    release_channel = "NIGHTLY"
  }

  expect_failures = [var.release_channel]
}

run "test_deletion_protection_in_prod" {
  command = plan

  # SMOKE: asserts the value passed to upstream deletion_protection; enforcement is by the provider on destroy.
  variables {
    context = {
      organization = "olensys"
      environment  = "prod"
      application  = "example"
      owner        = "platform"
      cost_center  = "eng"
    }
  }

  assert {
    condition     = output.deletion_protection == true
    error_message = "Deletion protection must be on in prod."
  }
}

run "test_deletion_protection_off_outside_prod" {
  command = plan

  assert {
    condition     = output.deletion_protection == false
    error_message = "Deletion protection must be off outside prod."
  }
}

run "test_node_pools_from_map" {
  command = plan

  variables {
    node_pools = {
      default = {
        machine_type = "e2-standard-4"
        min_count    = 1
        max_count    = 3
      }
      gpu = {
        machine_type = "n1-standard-8"
        spot         = true
        labels       = { workload = "gpu" }
        taints       = [{ key = "gpu", value = "true", effect = "NO_SCHEDULE" }]
      }
    }
  }

  assert {
    condition     = length(output.node_pools_config) == 2
    error_message = "One upstream node pool per map entry."
  }

  assert {
    condition = (
      [for p in output.node_pools_config : p if p.name == "default"][0].min_count == "1"
      && [for p in output.node_pools_config : p if p.name == "default"][0].max_count == "3"
      && [for p in output.node_pools_config : p if p.name == "default"][0].machine_type == "e2-standard-4"
    )
    error_message = "Counts must be passed as strings, machine type unchanged."
  }

  assert {
    condition = (
      [for p in output.node_pools_config : p if p.name == "gpu"][0].spot == "true"
      && [for p in output.node_pools_config : p if p.name == "gpu"][0].enable_secure_boot == "true"
      && [for p in output.node_pools_config : p if p.name == "gpu"][0].image_type == "COS_CONTAINERD"
      && [for p in output.node_pools_config : p if p.name == "gpu"][0].auto_upgrade == "true"
      && [for p in output.node_pools_config : p if p.name == "gpu"][0].auto_repair == "true"
    )
    error_message = "Spot honoured; secure boot, COS_CONTAINERD, auto upgrade and repair hardcoded."
  }
}

run "test_node_pool_min_greater_than_max_rejected" {
  command = plan

  variables {
    node_pools = { default = { min_count = 5, max_count = 2 } }
  }

  expect_failures = [var.node_pools]
}

run "test_maintenance_window_default" {
  command = plan

  assert {
    condition = (
      output.maintenance_config.start_time == "2026-01-03T02:00:00Z"
      && output.maintenance_config.end_time == "2026-01-03T08:00:00Z"
      && output.maintenance_config.recurrence == "FREQ=WEEKLY;BYDAY=SA,SU"
    )
    error_message = "Default maintenance window is weekly Saturday and Sunday 02:00-08:00 UTC."
  }
}

run "test_master_cidr_validation" {
  command = plan

  variables {
    master_cidr = "172.16.0.0/24"
  }

  expect_failures = [var.master_cidr]
}

run "test_create_false_plans_nothing" {
  command = plan

  variables {
    create = false
  }

  assert {
    condition = alltrue([
      output.id == null, output.name == null, output.self_link == null,
      output.endpoint == null, output.ca_certificate == null,
      output.workload_identity_pool == null, output.node_pool_names == null,
      output.labels == null, output.node_pools_config == null,
      output.private_cluster_config == null, output.maintenance_config == null, output.node_metadata == null,
      output.deletion_protection == null,
    ])
    error_message = "Every output must be null when create is false."
  }
}

run "test_name_length_validation" {
  command = plan

  variables {
    name = "a1234567890123456789012345678901234567890"
  }

  expect_failures = [var.name]
}

run "test_tags_contract" {
  command = plan

  variables {
    labels = { owner = "x" }
    context = {
      organization = "olensys"
      environment  = "test"
      application  = "example"
      owner        = "platform"
      cost_center  = "eng"
      extra_tags   = { owner = "y", team = "z" }
    }
  }

  assert {
    condition     = output.labels.owner == "x"
    error_message = "var.labels must win over context.extra_tags."
  }

  assert {
    condition     = output.labels.team == "z"
    error_message = "context.extra_tags must be merged."
  }
}
