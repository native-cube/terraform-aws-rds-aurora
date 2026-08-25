output "cluster_id" {
  description = "RDS/Aurora cluster identifier, or null when cluster creation is disabled."
  value       = try(aws_rds_cluster.main[0].id, null)
}

output "cluster_arn" {
  description = "RDS/Aurora cluster ARN, or null when cluster creation is disabled."
  value       = try(aws_rds_cluster.main[0].arn, null)
}

output "cluster_resource_id" {
  description = "RDS/Aurora cluster resource ID, or null when cluster creation is disabled."
  value       = try(aws_rds_cluster.main[0].cluster_resource_id, null)
}

output "cluster_endpoint" {
  description = "Writer endpoint for the RDS/Aurora cluster, or null when cluster creation is disabled."
  value       = try(aws_rds_cluster.main[0].endpoint, null)
}

output "cluster_reader_endpoint" {
  description = "Reader endpoint for the Aurora cluster, or null when unavailable."
  value       = try(aws_rds_cluster.main[0].reader_endpoint, null)
}

output "cluster_port" {
  description = "Database port for the RDS/Aurora cluster."
  value       = try(aws_rds_cluster.main[0].port, null)
}

output "cluster_engine_version_actual" {
  description = "Actual engine version reported for the RDS/Aurora cluster."
  value       = try(aws_rds_cluster.main[0].engine_version_actual, null)
}

output "cluster_instances" {
  description = "Aurora cluster instances keyed by the caller-controlled instances map keys."
  value = {
    for key, instance in aws_rds_cluster_instance.main : key => {
      id          = instance.id
      arn         = instance.arn
      endpoint    = instance.endpoint
      writer      = instance.writer
      resource_id = instance.dbi_resource_id
    }
  }
}

output "global_cluster_id" {
  description = "Created or external global cluster identifier used by this cluster."
  value       = local.global_cluster_identifier
}

output "global_cluster_arn" {
  description = "ARN of the module-created global cluster, or null when creation is disabled."
  value       = try(aws_rds_global_cluster.main[0].arn, null)
}

output "global_cluster_members" {
  description = "Members reported by the module-created global cluster."
  value       = try(aws_rds_global_cluster.main[0].global_cluster_members, [])
}

output "db_subnet_group_name" {
  description = "Created or external DB subnet group name used by the RDS/Aurora cluster."
  value       = local.db_subnet_group_name
}

output "security_group_id" {
  description = "ID of the module-created security group, or null when creation is disabled."
  value       = try(aws_security_group.main[0].id, null)
}

output "security_group_ids" {
  description = "All security group IDs associated with the RDS/Aurora cluster."
  value       = local.security_group_ids
}

output "cluster_parameter_group_id" {
  description = "ID of the module-created cluster parameter group, or null when not created."
  value       = try(aws_rds_cluster_parameter_group.main[0].id, null)
}

output "db_parameter_group_id" {
  description = "ID of the module-created DB instance parameter group, or null when not created."
  value       = try(aws_db_parameter_group.main[0].id, null)
}

output "monitoring_role_arn" {
  description = "Created or external Enhanced Monitoring role ARN used by the cluster and instances."
  value       = local.monitoring_role_arn
}

output "master_user_secret" {
  description = "RDS-managed master-user secret metadata. The secret value is not exposed."
  value       = try(aws_rds_cluster.main[0].master_user_secret, [])
}

output "custom_endpoints" {
  description = "Aurora custom endpoints keyed by the caller-controlled custom_endpoints map keys."
  value = {
    for key, endpoint in aws_rds_cluster_endpoint.main : key => {
      id       = endpoint.id
      arn      = endpoint.arn
      endpoint = endpoint.endpoint
      type     = endpoint.custom_endpoint_type
    }
  }
}

output "cluster_role_association_ids" {
  description = "RDS cluster IAM role-association IDs keyed by caller-controlled keys."
  value       = { for key, association in aws_rds_cluster_role_association.main : key => association.id }
}

output "managed_master_user_secret_rotation_id" {
  description = "Secrets Manager rotation resource ID for the RDS-managed master-user secret, or null when disabled."
  value       = try(aws_secretsmanager_secret_rotation.master[0].id, null)
}

output "shard_group" {
  description = "Aurora Limitless shard-group connection and identity details, or null when Limitless is disabled."
  value = try({
    arn         = aws_rds_shard_group.main[0].arn
    id          = aws_rds_shard_group.main[0].db_shard_group_identifier
    resource_id = aws_rds_shard_group.main[0].db_shard_group_resource_id
    endpoint    = aws_rds_shard_group.main[0].endpoint
  }, null)
}

output "dsql_clusters" {
  description = "Aurora DSQL clusters keyed by the caller-controlled dsql_clusters map keys."
  value = {
    for key, cluster in aws_dsql_cluster.main : key => {
      id                        = cluster.identifier
      arn                       = cluster.arn
      vpc_endpoint_service_name = cluster.vpc_endpoint_service_name
      encryption_details        = cluster.encryption_details
      multi_region_properties   = cluster.multi_region_properties
    }
  }
}

output "dsql_peering_ids" {
  description = "Aurora DSQL cluster identifiers whose peering configuration is managed by this module."
  value       = { for key, peering in aws_dsql_cluster_peering.main : key => peering.identifier }
}
