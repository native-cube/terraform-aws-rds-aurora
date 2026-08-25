terraform {
  required_version = ">= 1.11.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.61.0, < 7.0.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "aurora_mysql" {
  source = "../.."

  name                      = var.name
  engine                    = "aurora-mysql"
  engine_version            = var.engine_version
  final_snapshot_identifier = var.final_snapshot_identifier
  database_name             = var.database_name
  cluster_instance_class    = var.instance_class
  instances = {
    writer = {}
    reader = {
      promotion_tier = 1
    }
  }

  storage_type     = "aurora-iopt1"
  backtrack_window = 3600

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids
  ingress_rules = {
    clients = {
      description = "MySQL clients"
      cidr_ipv4   = var.client_cidr_block
    }
  }

  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  monitoring_interval             = 60

  tags = var.tags
}
