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
  alias  = "primary"
  region = var.primary_region
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}

module "single_region" {
  source = "../.."

  providers = {
    aws = aws.primary
  }

  name               = "${var.name}-single"
  create_rds_cluster = false
  dsql_clusters = {
    this = {}
  }

  tags = merge(var.tags, { Deployment = "single-region" })
}

module "multi_region_primary" {
  source = "../.."

  providers = {
    aws = aws.primary
  }

  name               = "${var.name}-primary"
  create_rds_cluster = false
  dsql_clusters = {
    this = {
      witness_region = var.witness_region
    }
  }

  tags = merge(var.tags, { Role = "primary" })
}

module "multi_region_secondary" {
  source = "../.."

  providers = {
    aws = aws.secondary
  }

  name               = "${var.name}-secondary"
  create_rds_cluster = false
  dsql_clusters = {
    this = {
      witness_region = var.witness_region
    }
  }

  tags = merge(var.tags, { Role = "secondary" })
}

# DSQL multi-Region clusters require symmetric peering: one peering resource
# is created through the provider for each participating cluster Region.
module "primary_peering" {
  source = "../.."

  providers = {
    aws = aws.primary
  }

  name               = "${var.name}-primary-peer"
  create_rds_cluster = false
  dsql_peerings = {
    this = {
      identifier     = module.multi_region_primary.dsql_clusters["this"].id
      clusters       = [module.multi_region_secondary.dsql_clusters["this"].arn]
      witness_region = var.witness_region
    }
  }
}

module "secondary_peering" {
  source = "../.."

  providers = {
    aws = aws.secondary
  }

  name               = "${var.name}-secondary-peer"
  create_rds_cluster = false
  dsql_peerings = {
    this = {
      identifier     = module.multi_region_secondary.dsql_clusters["this"].id
      clusters       = [module.multi_region_primary.dsql_clusters["this"].arn]
      witness_region = var.witness_region
    }
  }
}
