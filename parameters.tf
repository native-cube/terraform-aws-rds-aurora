resource "aws_rds_cluster_parameter_group" "main" {
  count = local.create_rds && var.cluster_parameter_group != null ? 1 : 0

  region      = var.region
  name        = var.cluster_parameter_group.use_name_prefix ? null : coalesce(var.cluster_parameter_group.name, "${var.name}-cluster")
  name_prefix = var.cluster_parameter_group.use_name_prefix ? "${coalesce(var.cluster_parameter_group.name, "${var.name}-cluster")}-" : null
  description = coalesce(var.cluster_parameter_group.description, "Cluster parameter group for ${var.name}")
  family      = var.cluster_parameter_group.family

  dynamic "parameter" {
    for_each = var.cluster_parameter_group.parameters

    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(local.common_tags, var.cluster_parameter_group.tags)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_parameter_group" "main" {
  count = local.create_rds && var.db_parameter_group != null ? 1 : 0

  region       = var.region
  name         = var.db_parameter_group.use_name_prefix ? null : coalesce(var.db_parameter_group.name, "${var.name}-instance")
  name_prefix  = var.db_parameter_group.use_name_prefix ? "${coalesce(var.db_parameter_group.name, "${var.name}-instance")}-" : null
  description  = coalesce(var.db_parameter_group.description, "DB parameter group for ${var.name}")
  family       = var.db_parameter_group.family
  skip_destroy = var.db_parameter_group.skip_destroy

  dynamic "parameter" {
    for_each = var.db_parameter_group.parameters

    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(local.common_tags, var.db_parameter_group.tags)

  lifecycle {
    create_before_destroy = true
  }
}
