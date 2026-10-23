variable "name" {
  description = "Cluster name. Lowercase letters, digits and hyphens, at most 40 characters (the GKE limit)."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{1,40}$", var.name))
    error_message = "name must match ^[a-z0-9-]{1,40}$."
  }
}

variable "context" {
  description = "Deployment context used for naming, tagging and environment-dependent defaults."
  type = object({
    organization = string
    environment  = string
    application  = string
    component    = optional(string)
    owner        = string
    cost_center  = string
    extra_tags   = optional(map(string), {})
  })
  validation {
    condition     = contains(["dev", "staging", "prod", "test", "shared"], var.context.environment)
    error_message = "context.environment must be one of dev, staging, prod, test, shared."
  }
}

variable "project_id" {
  description = "ID of the GCP project that hosts the cluster."
  type        = string
}

variable "create" {
  description = "Whether to create any resources. Set false to create nothing."
  type        = bool
  default     = true
}

variable "region" {
  description = "Region of the regional cluster."
  type        = string
}

variable "network" {
  description = "VPC placement: network name, subnetwork name and the names of the subnetwork's secondary ranges for pods and services."
  type = object({
    name                = string
    subnet_name         = string
    pods_range_name     = string
    services_range_name = string
  })
}

variable "master_cidr" {
  description = "RFC1918 /28 range for the control plane's private network. Must not overlap any subnet or secondary range."
  type        = string
  default     = "172.16.0.0/28"
  validation {
    condition     = can(regex("^[0-9]{1,3}(\\.[0-9]{1,3}){3}/28$", var.master_cidr)) && can(cidrhost(var.master_cidr, 0))
    error_message = "master_cidr must be a valid IPv4 CIDR block with a /28 prefix."
  }
}

variable "authorized_networks" {
  description = "CIDR blocks allowed to reach the public control plane endpoint. Empty means only the cluster's own nodes."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "release_channel" {
  description = "GKE release channel: RAPID, REGULAR or STABLE."
  type        = string
  default     = "REGULAR"
  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "release_channel must be one of RAPID, REGULAR, STABLE."
  }
}

variable "node_pools" {
  description = "Node pools keyed by pool name. Autoscaling between min_count and max_count per zone; spot selects Spot VMs."
  type = map(object({
    machine_type = optional(string, "e2-standard-4")
    min_count    = optional(number, 1)
    max_count    = optional(number, 5)
    disk_size_gb = optional(number, 100)
    spot         = optional(bool, false)
    labels       = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  default = {}
  validation {
    condition     = alltrue([for p in var.node_pools : p.min_count >= 0 && p.min_count <= p.max_count])
    error_message = "Each node pool needs 0 <= min_count <= max_count."
  }
  validation {
    condition     = alltrue([for p in var.node_pools : alltrue([for t in p.taints : contains(["NO_SCHEDULE", "PREFER_NO_SCHEDULE", "NO_EXECUTE"], t.effect)])])
    error_message = "Taint effect must be one of NO_SCHEDULE, PREFER_NO_SCHEDULE, NO_EXECUTE."
  }
}

variable "enable_workload_identity" {
  description = "Enable GKE Workload Identity with the project pool <project_id>.svc.id.goog."
  type        = bool
  default     = true
}

variable "maintenance_window" {
  description = "Recurring maintenance window as RFC3339 start and end timestamps plus an RFC5545 recurrence rule. Default: weekly, Sunday 02:00-06:00 UTC."
  type = object({
    start_time = string
    end_time   = string
    recurrence = string
  })
  default = {
    start_time = "2026-01-04T02:00:00Z"
    end_time   = "2026-01-04T06:00:00Z"
    recurrence = "FREQ=WEEKLY;BYDAY=SU"
  }
}

variable "labels" {
  description = "Labels merged onto the cluster, applied last."
  type        = map(string)
  default     = {}
}
