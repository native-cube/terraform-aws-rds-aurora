terraform {
  required_version = ">= 1.11.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.61.0, < 7.0.0"
    }
  }
}

provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}

module "primary" {
  source = "../.."

  providers = {
    aws = aws.primary
  }

  name                      = "${var.name}-primary"
  engine                    = "aurora-postgresql"
  engine_version            = var.engine_version
  final_snapshot_identifier = var.primary_final_snapshot_identifier
  database_name             = var.database_name
  create_global_cluster     = true
  global_cluster_identifier = var.name

  manage_master_user_password = false
  master_password_wo          = var.master_password_wo
  master_password_wo_version  = var.master_password_wo_version
  cluster_instance_class      = var.instance_class
  instances = {
    writer = {}
    reader = {}
  }

  vpc_id     = var.primary_vpc_id
  subnet_ids = var.primary_subnet_ids
  ingress_rules = {
    clients = {
      description = "PostgreSQL clients in the primary Region"
      cidr_ipv4   = var.primary_client_cidr_block
    }
  }

  enabled_cloudwatch_logs_exports = ["postgresql"]
  tags                            = merge(var.tags, { Role = "primary" })
}

module "secondary" {
  source = "../.."

  providers = {
    aws = aws.secondary
  }

  name                      = "${var.name}-secondary"
  engine                    = "aurora-postgresql"
  engine_version            = var.engine_version
  final_snapshot_identifier = var.secondary_final_snapshot_identifier
  is_primary_cluster        = false
  global_cluster_identifier = module.primary.global_cluster_id
  cluster_instance_class    = var.instance_class
  instances = {
    reader = {}
  }

  vpc_id     = var.secondary_vpc_id
  subnet_ids = var.secondary_subnet_ids
  ingress_rules = {
    clients = {
      description = "PostgreSQL clients in the secondary Region"
      cidr_ipv4   = var.secondary_client_cidr_block
    }
  }

  enable_global_write_forwarding  = var.enable_global_write_forwarding
  enabled_cloudwatch_logs_exports = ["postgresql"]
  tags                            = merge(var.tags, { Role = "secondary" })
}
