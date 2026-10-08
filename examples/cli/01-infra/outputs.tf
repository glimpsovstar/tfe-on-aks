output "effective_settings" {
  value       = module.tfe_infra.effective_settings
  description = "Resolved sizing preset (for tests and review)."
}

output "replica_count" {
  value       = module.tfe_infra.replica_count
  description = "TFE pod count for this size."
}

output "tfe_pod_requests" {
  value       = module.tfe_infra.tfe_pod_requests
  description = "TFE pod CPU and memory requests for this size."
}

output "aks_cluster_name" {
  value       = module.tfe_infra.aks_cluster_name
  description = "AKS cluster name."
}

output "kube_host" {
  value       = module.tfe_infra.kube_host
  sensitive   = true
  description = "AKS API endpoint."
}

output "kube_cluster_ca_certificate" {
  value       = module.tfe_infra.kube_cluster_ca_certificate
  sensitive   = true
  description = "Base64 cluster CA."
}

output "kube_client_certificate" {
  value       = module.tfe_infra.kube_client_certificate
  sensitive   = true
  description = "Base64 admin client certificate."
}

output "kube_client_key" {
  value       = module.tfe_infra.kube_client_key
  sensitive   = true
  description = "Base64 admin client key."
}

output "tfe_database_host" {
  value       = module.tfe_infra.tfe_database_host
  description = "PostgreSQL host:5432."
}

output "tfe_database_name" {
  value       = module.tfe_infra.tfe_database_name
  description = "Database name."
}

output "tfe_database_user" {
  value       = module.tfe_infra.tfe_database_user
  description = "Database user."
}

output "tfe_database_password" {
  value       = module.tfe_infra.tfe_database_password
  sensitive   = true
  description = "Database password."
}

output "tfe_object_storage_azure_account_name" {
  value       = module.tfe_infra.tfe_object_storage_azure_account_name
  description = "Storage account name."
}

output "tfe_object_storage_azure_container" {
  value       = module.tfe_infra.tfe_object_storage_azure_container
  description = "Blob container name."
}

output "tfe_object_storage_azure_client_id" {
  value       = module.tfe_infra.tfe_object_storage_azure_client_id
  description = "Workload identity client ID for Blob access."
}

output "tfe_redis_host" {
  value       = module.tfe_infra.tfe_redis_host
  description = "Main Redis hostname (no port)."
}

output "tfe_redis_password" {
  value       = module.tfe_infra.tfe_redis_password
  sensitive   = true
  description = "Main Redis access key."
}

output "tfe_redis_use_auth" {
  value       = module.tfe_infra.tfe_redis_use_auth
  description = "Main Redis auth flag."
}

output "tfe_redis_sidekiq_host" {
  value       = module.tfe_infra.tfe_redis_sidekiq_host
  description = "Sidekiq Redis hostname (no port)."
}

output "tfe_redis_sidekiq_password" {
  value       = module.tfe_infra.tfe_redis_sidekiq_password
  sensitive   = true
  description = "Sidekiq Redis access key."
}

output "tfe_redis_sidekiq_use_auth" {
  value       = module.tfe_infra.tfe_redis_sidekiq_use_auth
  description = "Sidekiq Redis auth flag."
}
