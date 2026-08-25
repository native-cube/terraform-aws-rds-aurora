data "aws_partition" "current" {
  count = local.create_monitoring_role ? 1 : 0
}

data "aws_subnet" "selected" {
  for_each = local.validate_network && local.create_subnet_group ? toset(var.subnet_ids) : toset([])

  region = var.region
  id     = each.value
}

data "aws_security_group" "selected" {
  for_each = local.validate_network ? var.security_group_ids : toset([])

  region = var.region
  id     = each.value
}

data "aws_rds_engine_version" "selected" {
  count = local.validate_engine ? 1 : 0

  region      = var.region
  engine      = var.engine
  version     = var.engine_version
  include_all = true
}

data "aws_rds_orderable_db_instance" "selected" {
  for_each = local.validate_engine ? local.orderable_instance_classes : toset([])

  region         = var.region
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = each.value
  storage_type   = local.is_multi_az ? var.storage_type : null
  vpc            = true
}
