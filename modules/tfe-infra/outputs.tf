output "effective_settings" {
  value       = local.settings
  description = "Resolved sizing preset (for tests and review)."
}
output "replica_count" {
  value       = local.settings.replica_count
  description = "TFE pod count for this size."
}
output "tfe_pod_requests" {
  value       = local.settings.tfe_pod_requests
  description = "TFE pod CPU and memory requests for this size. The lab preset is below the chart default so the pod fits Standard_D4ds_v5 nodes."
}
output "aks_cluster_name" {
  value       = local.aks_cluster_name
  description = "AKS cluster name."
}
output "kube_host" {
  value       = local.kube.host
  sensitive   = true
  description = "AKS API endpoint."
}
output "kube_cluster_ca_certificate" {
  value       = local.kube.cluster_ca_certificate
  sensitive   = true
  description = "Base64 cluster CA."
}
output "kube_client_certificate" {
  value       = local.kube.client_certificate
  sensitive   = true
  description = "Base64 client certificate (cluster-admin on a local-account cluster)."
}
output "kube_client_key" {
  value       = local.kube.client_key
  sensitive   = true
  description = "Base64 client key (cluster-admin on a local-account cluster)."
}
output "tfe_database_host" {
  value       = module.tfe.tfe_database_host
  description = "PostgreSQL host:5432."
}
output "tfe_database_name" {
  value       = module.tfe.tfe_database_name
  description = "Database name."
}
output "tfe_database_user" {
  value       = module.tfe.tfe_database_user
  description = "Database user."
}
output "tfe_database_password" {
  value       = module.tfe.tfe_database_password
  sensitive   = true
  description = "Database password."
}
output "tfe_object_storage_azure_account_name" {
  value       = module.tfe.tfe_object_storage_azure_account_name
  description = "Storage account name."
}
output "tfe_object_storage_azure_container" {
  value       = module.tfe.tfe_object_storage_azure_container
  description = "Blob container name."
}
output "tfe_object_storage_azure_client_id" {
  value       = local.tfe_object_storage_azure_client_id
  description = "Workload identity client ID for Blob access."
}
output "tfe_redis_host" {
  value       = module.tfe.tfe_redis_host
  description = "Main Redis hostname (no port)."
}
output "tfe_redis_password" {
  value       = module.tfe.tfe_redis_password
  sensitive   = true
  description = "Main Redis access key."
}
output "tfe_redis_use_auth" {
  value       = module.tfe.tfe_redis_use_auth
  description = "Main Redis auth flag."
}
output "tfe_redis_sidekiq_host" {
  value       = module.tfe.tfe_redis_sidekiq_host
  description = "Sidekiq Redis hostname (no port)."
}
output "tfe_redis_sidekiq_password" {
  value       = module.tfe.tfe_redis_sidekiq_password
  sensitive   = true
  description = "Sidekiq Redis access key."
}
output "tfe_redis_sidekiq_use_auth" {
  value       = module.tfe.tfe_redis_sidekiq_use_auth
  description = "Sidekiq Redis auth flag."
}
