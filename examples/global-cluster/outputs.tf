output "global_cluster_id" {
  description = "RDS global cluster identifier."
  value       = module.primary.global_cluster_id
}

output "primary_endpoint" {
  description = "Primary writer endpoint."
  value       = module.primary.cluster_endpoint
}

output "secondary_endpoint" {
  description = "Secondary cluster endpoint."
  value       = module.secondary.cluster_endpoint
}
