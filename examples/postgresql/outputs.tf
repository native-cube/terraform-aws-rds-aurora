output "cluster_endpoint" {
  description = "Aurora PostgreSQL writer endpoint."
  value       = module.aurora_postgresql.cluster_endpoint
}

output "reader_endpoint" {
  description = "Aurora PostgreSQL reader endpoint."
  value       = module.aurora_postgresql.cluster_reader_endpoint
}

output "master_user_secret" {
  description = "Metadata for the RDS-managed master-user secret."
  value       = module.aurora_postgresql.master_user_secret
}
