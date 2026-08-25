output "cluster_endpoint" {
  description = "Aurora MySQL writer endpoint."
  value       = module.aurora_mysql.cluster_endpoint
}

output "reader_endpoint" {
  description = "Aurora MySQL reader endpoint."
  value       = module.aurora_mysql.cluster_reader_endpoint
}

output "master_user_secret" {
  description = "Metadata for the RDS-managed master-user secret."
  value       = module.aurora_mysql.master_user_secret
}
