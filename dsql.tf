resource "aws_dsql_cluster" "main" {
  for_each = var.create ? var.dsql_clusters : {}

  region                      = each.value.region != null ? each.value.region : var.region
  deletion_protection_enabled = each.value.deletion_protection_enabled
  force_destroy               = each.value.force_destroy
  kms_encryption_key          = each.value.kms_encryption_key

  dynamic "multi_region_properties" {
    for_each = each.value.witness_region == null ? [] : [each.value.witness_region]

    content {
      witness_region = multi_region_properties.value
    }
  }

  dynamic "timeouts" {
    for_each = each.value.timeouts == null ? [] : [each.value.timeouts]

    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  tags = merge(local.common_tags, each.value.tags, {
    Name = "${var.name}-${each.key}"
  })
}

resource "aws_dsql_cluster_peering" "main" {
  for_each = var.create ? var.dsql_peerings : {}

  region         = each.value.region != null ? each.value.region : var.region
  identifier     = each.value.identifier
  clusters       = each.value.clusters
  witness_region = each.value.witness_region

  dynamic "timeouts" {
    for_each = each.value.create_timeout == null ? [] : [each.value.create_timeout]

    content {
      create = timeouts.value
    }
  }
}
