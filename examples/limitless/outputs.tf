output "cluster_endpoint" {
  description = "Aurora cluster endpoint."
  value       = module.aurora_limitless.cluster_endpoint
}

output "shard_group" {
  description = "Aurora Limitless shard-group connection details."
  value       = module.aurora_limitless.shard_group
}
