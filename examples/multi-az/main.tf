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

module "rds_multi_az" {
  source = "../.."

  name                      = var.name
  engine                    = "postgres"
  engine_version            = var.engine_version
  final_snapshot_identifier = var.final_snapshot_identifier
  database_name             = var.database_name
  allocated_storage         = var.allocated_storage
  storage_type              = "io1"
  iops                      = var.iops
  cluster_instance_class    = var.instance_class

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids
  ingress_rules = {
    clients = {
      description = "PostgreSQL clients"
      cidr_ipv4   = var.client_cidr_block
    }
  }

  enabled_cloudwatch_logs_exports = ["postgresql"]
  monitoring_interval             = 60

  tags = var.tags
}
