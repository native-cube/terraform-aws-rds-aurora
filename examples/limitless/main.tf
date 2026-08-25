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

module "aurora_limitless" {
  source = "../.."

  name                      = var.name
  engine                    = "aurora-postgresql"
  engine_version            = var.engine_version
  final_snapshot_identifier = var.final_snapshot_identifier
  database_name             = var.database_name
  cluster_scalability_type  = "limitless"
  storage_type              = "aurora-iopt1"

  shard_group = {
    identifier         = "${var.name}-shards"
    min_acu            = var.min_acu
    max_acu            = var.max_acu
    compute_redundancy = var.compute_redundancy
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids
  ingress_rules = {
    clients = {
      description = "PostgreSQL clients"
      cidr_ipv4   = var.client_cidr_block
    }
  }

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = var.tags
}
