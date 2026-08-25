resource "aws_iam_role" "monitoring" {
  count = local.create_monitoring_role ? 1 : 0

  name                 = coalesce(var.monitoring_role_name, substr("${var.name}-rds-monitoring", 0, 64))
  description          = "Enhanced Monitoring role for ${var.name}"
  permissions_boundary = var.monitoring_role_permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  count = local.create_monitoring_role ? 1 : 0

  role       = aws_iam_role.monitoring[0].name
  policy_arn = "arn:${data.aws_partition.current[0].partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_cloudwatch_log_group" "main" {
  for_each = local.create_rds && var.create_cloudwatch_log_groups ? var.enabled_cloudwatch_logs_exports : toset([])

  region                      = var.region
  name                        = "/aws/rds/cluster/${var.name}/${each.value}"
  retention_in_days           = var.cloudwatch_log_group_retention_in_days
  kms_key_id                  = var.cloudwatch_log_group_kms_key_id
  log_group_class             = var.cloudwatch_log_group_class
  deletion_protection_enabled = var.cloudwatch_log_group_deletion_protection
  skip_destroy                = var.cloudwatch_log_group_skip_destroy

  tags = local.common_tags
}
