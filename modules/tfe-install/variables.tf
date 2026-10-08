variable "tfe_hostname" { type = string }
variable "tfe_version" {
  type    = string
  default = "2.0.8"
  validation {
    condition     = can(regex("^(1\\.0\\.[1-9][0-9]*|1\\.[1-9][0-9]*\\.[0-9]+|[2-9][0-9]*\\.[0-9]+\\.[0-9]+)$", var.tfe_version))
    error_message = "tfe_version must be semver X.Y.Z, 1.0.1 or later, without a 'v' prefix."
  }
}
variable "chart_version" {
  type    = string
  default = "2.0.8"
}
variable "replica_count" { type = number }
variable "pod_requests" {
  type        = object({ cpu = string, memory = string })
  default     = { cpu = "4", memory = "8Gi" }
  description = "TFE pod CPU and memory requests. The default is the chart default (4 vCPU, 8Gi); the lab preset lowers it so the pod schedules on Standard_D4ds_v5 nodes."
}
variable "tfe_license" {
  type      = string
  sensitive = true
}
variable "namespace" {
  type    = string
  default = "tfe"
  validation {
    condition     = var.namespace == "tfe"
    error_message = "namespace must be \"tfe\": the HVD workload-identity subject is fixed to system:serviceaccount:tfe:tfe, and the chart names the service account after the namespace."
  }
}
variable "lb_subnet_name" { type = string }
variable "lb_static_ip" { type = string }
variable "key_vault_id" { type = string }
variable "tfe_database_host" { type = string }
variable "tfe_database_name" { type = string }
variable "tfe_database_user" { type = string }
variable "tfe_database_password" {
  type      = string
  sensitive = true
}
variable "tfe_object_storage_azure_account_name" { type = string }
variable "tfe_object_storage_azure_container" { type = string }
variable "tfe_object_storage_azure_client_id" { type = string }
variable "tfe_redis_host" { type = string }
variable "tfe_redis_password" {
  type      = string
  sensitive = true
}
variable "tfe_redis_use_auth" { type = bool }
variable "tfe_redis_sidekiq_host" { type = string }
variable "tfe_redis_sidekiq_password" {
  type      = string
  sensitive = true
}
variable "tfe_redis_sidekiq_use_auth" { type = bool }
variable "private_dns_zone_name" { type = string }
variable "resource_group_name" { type = string }
variable "public_dns_zone_name" { type = string }
variable "public_dns_zone_resource_group" { type = string }
variable "subscription_id" { type = string }
variable "acme_azure_auth_method" {
  type        = string
  default     = "msi"
  description = "lego azuredns auth: msi on the agent VM, cli on a laptop."
  validation {
    condition     = contains(["msi", "cli"], var.acme_azure_auth_method)
    error_message = "acme_azure_auth_method must be msi or cli."
  }
}
