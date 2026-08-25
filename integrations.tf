resource "aws_rds_cluster_endpoint" "main" {
  for_each = local.create_rds ? var.custom_endpoints : {}

  region                      = var.region
  cluster_identifier          = aws_rds_cluster.main[0].id
  cluster_endpoint_identifier = coalesce(each.value.identifier, substr("${var.name}-${each.key}", 0, 63))
  custom_endpoint_type        = each.value.type
  static_members              = length(each.value.static_members) > 0 ? [for key in each.value.static_members : aws_rds_cluster_instance.main[key].id] : null
  excluded_members            = length(each.value.excluded_members) > 0 ? [for key in each.value.excluded_members : aws_rds_cluster_instance.main[key].id] : null
  tags                        = merge(local.common_tags, each.value.tags)

  lifecycle {
    precondition {
      condition     = local.create_instances
      error_message = "Custom endpoints require a standard provisioned or Serverless v2 Aurora cluster with module-managed instances."
    }
  }
}

resource "aws_rds_cluster_role_association" "main" {
  for_each = local.create_rds ? var.cluster_role_associations : {}

  region                = var.region
  db_cluster_identifier = aws_rds_cluster.main[0].id
  feature_name          = each.value.feature_name
  role_arn              = each.value.role_arn

  dynamic "timeouts" {
    for_each = each.value.timeouts == null ? [] : [each.value.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
    }
  }
}

resource "aws_secretsmanager_secret_rotation" "master" {
  count = local.create_secret_rotation ? 1 : 0

  region                            = var.region
  secret_id                         = aws_rds_cluster.main[0].master_user_secret[0].secret_arn
  rotate_immediately                = var.managed_master_user_secret_rotation.rotate_immediately
  rotation_lambda_arn               = var.managed_master_user_secret_rotation.rotation_lambda_arn
  external_secret_rotation_role_arn = var.managed_master_user_secret_rotation.external_secret_rotation_role_arn

  rotation_rules {
    automatically_after_days = var.managed_master_user_secret_rotation.automatically_after_days
    duration                 = var.managed_master_user_secret_rotation.duration
    schedule_expression      = var.managed_master_user_secret_rotation.schedule_expression
  }

  dynamic "external_secret_rotation_metadata" {
    for_each = var.managed_master_user_secret_rotation.external_secret_rotation_metadata

    content {
      key   = external_secret_rotation_metadata.key
      value = external_secret_rotation_metadata.value
    }
  }
}
