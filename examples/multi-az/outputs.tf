output "cluster_endpoint" {
  description = "RDS Multi-AZ DB cluster writer endpoint."
  value       = module.rds_multi_az.cluster_endpoint
}

output "reader_endpoint" {
  description = "RDS Multi-AZ DB cluster reader endpoint."
  value       = module.rds_multi_az.cluster_reader_endpoint
}
