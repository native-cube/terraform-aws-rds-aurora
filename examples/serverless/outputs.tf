output "serverless_v1_endpoint" {
  description = "Aurora Serverless v1 endpoint."
  value       = module.serverless_v1.cluster_endpoint
}

output "serverless_v2_endpoint" {
  description = "Aurora Serverless v2 writer endpoint."
  value       = module.serverless_v2.cluster_endpoint
}

output "serverless_v2_reader_endpoint" {
  description = "Aurora Serverless v2 reader endpoint."
  value       = module.serverless_v2.cluster_reader_endpoint
}
