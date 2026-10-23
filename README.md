# terraform-google-gke-cluster

Private GKE cluster with Workload Identity, shielded nodes, release channel and node pools from a map

## Opinions

- Private nodes (`enable_private_nodes = true`) with a public control plane endpoint (`enable_private_endpoint = false`) reachable only from `authorized_networks` (an empty list means no external access; `gcp_public_cidrs_access_enabled = false` guarantees the authorized-networks block is always rendered); the DNS endpoint stays closed to external traffic.
- Shielded nodes, Secure Boot, `COS_CONTAINERD` images, auto-upgrade and auto-repair on every node pool.
- Dataplane V2 (`ADVANCED_DATAPATH`); the legacy network policy addon is off.
- Regional cluster; the default node pool is removed and all capacity comes from `node_pools`.
- Workload Identity with the project pool `<project_id>.svc.id.goog` unless `enable_workload_identity = false`.
- Logging of `SYSTEM_COMPONENTS` and `WORKLOADS`; monitoring of `SYSTEM_COMPONENTS` (the GA provider and GKE 1.24+ reject `WORKLOADS` monitoring).
- Horizontal pod autoscaling and HTTP load balancing addons on.
- `deletion_protection = true` when `context.environment` is `prod`.
- Weekly maintenance window Saturday and Sunday 02:00-08:00 UTC by default (GKE requires at least 48 hours of availability per 32 days).

## Provider requirement

The upstream module requires `google >= 7.39.0`, so this module constrains the provider to `>= 7.39, < 8.0` rather than the library-wide `>= 6.0`.

## Usage

```hcl
module "this" {
  source = "git::https://github.com/Olensys/terraform-google-gke-cluster.git?ref=v1.0.0"

  name       = "example"
  project_id = "my-project"
  region     = "us-central1"
  context = {
    organization = "olensys"
    environment  = "dev"
    application  = "example"
    owner        = "platform"
    cost_center  = "eng"
  }

  network = {
    name                = "my-network"
    subnet_name         = "my-subnet"
    pods_range_name     = "pods"
    services_range_name = "services"
  }

  node_pools = {
    default = { machine_type = "e2-standard-4", min_count = 1, max_count = 3 }
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 7.39, < 8.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_this"></a> [this](#module\_this) | terraform-google-modules/kubernetes-engine/google//modules/private-cluster | 46.0.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_context"></a> [context](#input\_context) | Deployment context used for naming, tagging and environment-dependent defaults. | <pre>object({<br/>    organization = string<br/>    environment  = string<br/>    application  = string<br/>    component    = optional(string)<br/>    owner        = string<br/>    cost_center  = string<br/>    extra_tags   = optional(map(string), {})<br/>  })</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Cluster name. Starts with a letter, lowercase letters, digits and hyphens, ends with a letter or digit, at most 40 characters (the GKE limit). | `string` | n/a | yes |
| <a name="input_network"></a> [network](#input\_network) | VPC placement: network name, subnetwork name and the names of the subnetwork's secondary ranges for pods and services. | <pre>object({<br/>    name                = string<br/>    subnet_name         = string<br/>    pods_range_name     = string<br/>    services_range_name = string<br/>  })</pre> | n/a | yes |
| <a name="input_node_pools"></a> [node\_pools](#input\_node\_pools) | Node pools keyed by pool name. Autoscaling between min\_count and max\_count per zone; spot selects Spot VMs. | <pre>map(object({<br/>    machine_type = optional(string, "e2-standard-4")<br/>    min_count    = optional(number, 1)<br/>    max_count    = optional(number, 5)<br/>    disk_size_gb = optional(number, 100)<br/>    spot         = optional(bool, false)<br/>    labels       = optional(map(string), {})<br/>    taints = optional(list(object({<br/>      key    = string<br/>      value  = string<br/>      effect = string<br/>    })), [])<br/>  }))</pre> | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | ID of the GCP project that hosts the cluster. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Region of the regional cluster. | `string` | n/a | yes |
| <a name="input_authorized_networks"></a> [authorized\_networks](#input\_authorized\_networks) | CIDR blocks allowed to reach the public control plane endpoint. Empty means no external access to the public endpoint; add CIDRs to allow. | <pre>list(object({<br/>    cidr_block   = string<br/>    display_name = string<br/>  }))</pre> | `[]` | no |
| <a name="input_create"></a> [create](#input\_create) | Whether to create any resources. Set false to create nothing. | `bool` | `true` | no |
| <a name="input_enable_workload_identity"></a> [enable\_workload\_identity](#input\_enable\_workload\_identity) | Enable GKE Workload Identity with the project pool <project\_id>.svc.id.goog. | `bool` | `true` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels merged onto the cluster, applied last. | `map(string)` | `{}` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | Recurring maintenance window as RFC3339 start and end timestamps plus an RFC5545 recurrence rule. Default: weekly, Saturday and Sunday 02:00-08:00 UTC (GKE requires at least 48 hours of availability per 32 days). | <pre>object({<br/>    start_time = string<br/>    end_time   = string<br/>    recurrence = string<br/>  })</pre> | <pre>{<br/>  "end_time": "2026-01-03T08:00:00Z",<br/>  "recurrence": "FREQ=WEEKLY;BYDAY=SA,SU",<br/>  "start_time": "2026-01-03T02:00:00Z"<br/>}</pre> | no |
| <a name="input_master_cidr"></a> [master\_cidr](#input\_master\_cidr) | RFC1918 /28 range for the control plane's private network. Must not overlap any subnet or secondary range. | `string` | `"172.16.0.0/28"` | no |
| <a name="input_release_channel"></a> [release\_channel](#input\_release\_channel) | GKE release channel: RAPID, REGULAR or STABLE. | `string` | `"REGULAR"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ca_certificate"></a> [ca\_certificate](#output\_ca\_certificate) | Base64-encoded cluster CA certificate. Null when create is false. |
| <a name="output_deletion_protection"></a> [deletion\_protection](#output\_deletion\_protection) | Whether Terraform is prevented from destroying the cluster (true in prod). Null when create is false. |
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | Public control plane endpoint. Null when create is false. |
| <a name="output_id"></a> [id](#output\_id) | Cluster ID (projects/<project>/locations/<region>/clusters/<name>). Null when create is false. |
| <a name="output_labels"></a> [labels](#output\_labels) | Labels applied to the cluster, with context.extra\_tags merged in. Null when create is false. |
| <a name="output_maintenance_config"></a> [maintenance\_config](#output\_maintenance\_config) | Maintenance window passed to the upstream module. Null when create is false. |
| <a name="output_name"></a> [name](#output\_name) | Cluster name. Null when create is false. |
| <a name="output_node_metadata"></a> [node\_metadata](#output\_node\_metadata) | Node metadata mode passed to the upstream module (GKE\_METADATA with Workload Identity, else UNSPECIFIED). Null when create is false. |
| <a name="output_node_pool_names"></a> [node\_pool\_names](#output\_node\_pool\_names) | Names of the node pools. Null when create is false. |
| <a name="output_node_pools_config"></a> [node\_pools\_config](#output\_node\_pools\_config) | Node pool list passed to the upstream module (all values are strings). Null when create is false. |
| <a name="output_private_cluster_config"></a> [private\_cluster\_config](#output\_private\_cluster\_config) | Private cluster settings passed to the upstream module. Null when create is false. |
| <a name="output_self_link"></a> [self\_link](#output\_self\_link) | Relative resource path of the cluster. Null when create is false. |
| <a name="output_workload_identity_pool"></a> [workload\_identity\_pool](#output\_workload\_identity\_pool) | Workload Identity pool (<project>.svc.id.goog). Null when Workload Identity is disabled or create is false. |
<!-- END_TF_DOCS -->
