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

module "serverless_v1" {
  source = "../.."

  name                      = "${var.name}-v1"
  engine                    = "aurora-mysql"
  engine_mode               = "serverless"
  engine_version            = var.serverless_v1_engine_version
  final_snapshot_identifier = var.serverless_v1_final_snapshot_identifier
  database_name             = var.database_name

  serverless_v1_scaling_configuration = {
    auto_pause               = true
    min_capacity             = 2
    max_capacity             = 16
    seconds_until_auto_pause = 900
    timeout_action           = "ForceApplyCapacityChange"
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids
  ingress_rules = {
    clients = {
      description = "MySQL clients"
      cidr_ipv4   = var.client_cidr_block
    }
  }

  enable_http_endpoint         = true
  performance_insights_enabled = false
  tags                         = merge(var.tags, { Generation = "Serverless v1" })
}

module "serverless_v2" {
  source = "../.."

  name                      = "${var.name}-v2"
  engine                    = "aurora-postgresql"
  engine_mode               = "provisioned"
  engine_version            = var.serverless_v2_engine_version
  final_snapshot_identifier = var.serverless_v2_final_snapshot_identifier
  database_name             = var.database_name

  serverless_v2_scaling_configuration = {
    min_capacity             = 0.5
    max_capacity             = 16
    seconds_until_auto_pause = 900
  }

  instances = {
    writer = {}
    reader = {}
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
  tags                            = merge(var.tags, { Generation = "Serverless v2" })
}
