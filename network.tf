resource "aws_db_subnet_group" "main" {
  count = local.create_subnet_group ? 1 : 0

  region      = var.region
  name        = coalesce(var.db_subnet_group_name, "${var.name}-database")
  description = var.db_subnet_group_description
  subnet_ids  = var.subnet_ids

  tags = merge(local.common_tags, {
    Name = coalesce(var.db_subnet_group_name, "${var.name}-database")
  })

  lifecycle {
    precondition {
      condition     = length(var.subnet_ids) >= 2
      error_message = "A module-created DB subnet group requires at least two subnet IDs in different Availability Zones."
    }

    precondition {
      condition     = !local.validate_network || length(local.selected_subnet_vpc_ids) == 1
      error_message = "All database subnets must belong to the same VPC."
    }

    precondition {
      condition     = !local.validate_network || length(local.selected_subnet_azs) >= 2
      error_message = "Database subnets must span at least two distinct Availability Zones."
    }

    precondition {
      condition     = !local.validate_network || !local.is_multi_az || length(local.selected_subnet_azs) == 3
      error_message = "An RDS Multi-AZ DB cluster subnet group must span exactly three Availability Zones."
    }

    precondition {
      condition     = !local.validate_network || var.vpc_id == null || local.selected_vpc_id == var.vpc_id
      error_message = "Every database subnet must belong to vpc_id."
    }
  }
}

resource "aws_security_group" "main" {
  count = local.create_security_group ? 1 : 0

  region                 = var.region
  name                   = coalesce(var.security_group_name, "${var.name}-database")
  description            = var.security_group_description
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = var.revoke_rules_on_delete

  tags = merge(local.common_tags, {
    Name = coalesce(var.security_group_name, "${var.name}-database")
  })

  lifecycle {
    precondition {
      condition     = var.vpc_id != null && trimspace(var.vpc_id) != ""
      error_message = "vpc_id is required when create_security_group is true."
    }

    precondition {
      condition     = !local.validate_network || !local.create_subnet_group || local.selected_vpc_id == var.vpc_id
      error_message = "The module-created security group and database subnets must belong to the same VPC."
    }
  }
}

resource "aws_vpc_security_group_ingress_rule" "main" {
  for_each = local.create_security_group ? var.ingress_rules : {}

  region                       = var.region
  security_group_id            = aws_security_group.main[0].id
  description                  = each.value.description
  from_port                    = each.value.from_port == null && each.value.ip_protocol != "-1" ? local.port : each.value.from_port
  to_port                      = each.value.to_port == null && each.value.ip_protocol != "-1" ? local.port : each.value.to_port
  ip_protocol                  = each.value.ip_protocol
  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.referenced_security_group_id
  tags                         = merge(local.common_tags, each.value.tags)
}

resource "aws_vpc_security_group_egress_rule" "main" {
  for_each = local.create_security_group ? var.egress_rules : {}

  region                       = var.region
  security_group_id            = aws_security_group.main[0].id
  description                  = each.value.description
  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  ip_protocol                  = each.value.ip_protocol
  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.referenced_security_group_id
  tags                         = merge(local.common_tags, each.value.tags)
}
