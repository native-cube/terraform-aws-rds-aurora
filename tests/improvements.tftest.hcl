mock_provider "aws" {
  override_during = plan

  mock_data "aws_subnet" {
    defaults = {
      vpc_id            = "vpc-0123456789abcdef0"
      availability_zone = "eu-west-2a"
    }
  }

  mock_data "aws_security_group" {
    defaults = {
      vpc_id = "vpc-0123456789abcdef0"
    }
  }

  mock_data "aws_rds_engine_version" {
    defaults = {
      status                          = "available"
      supported_modes                 = ["provisioned", "serverless"]
      supports_global_databases       = true
      supports_limitless_database     = true
      supports_local_write_forwarding = true
      exportable_log_types            = ["postgresql", "audit", "error", "general", "slowquery"]
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }
}

run "validated_network_and_engine" {
  command = plan

  variables {
    name                      = "unit-validated"
    engine_version            = "17.5"
    cluster_instance_class    = "db.r7g.large"
    final_snapshot_identifier = "unit-validated-final-v1"
    vpc_id                    = "vpc-0123456789abcdef0"
    subnet_ids = [
      "subnet-00000000000000001",
      "subnet-00000000000000002",
      "subnet-00000000000000003"
    ]
    availability_zones              = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
    enabled_cloudwatch_logs_exports = ["postgresql"]
  }

  override_data {
    target = data.aws_subnet.selected["subnet-00000000000000001"]
    values = {
      vpc_id            = "vpc-0123456789abcdef0"
      availability_zone = "eu-west-2a"
    }
  }

  override_data {
    target = data.aws_subnet.selected["subnet-00000000000000002"]
    values = {
      vpc_id            = "vpc-0123456789abcdef0"
      availability_zone = "eu-west-2b"
    }
  }

  override_data {
    target = data.aws_subnet.selected["subnet-00000000000000003"]
    values = {
      vpc_id            = "vpc-0123456789abcdef0"
      availability_zone = "eu-west-2c"
    }
  }

  assert {
    condition     = length(data.aws_subnet.selected) == 3 && data.aws_rds_engine_version.selected[0].status == "available"
    error_message = "Network and engine capability data should be queried by default."
  }

  assert {
    condition     = aws_rds_cluster.main[0].database_insights_mode == "standard"
    error_message = "CloudWatch Database Insights standard mode should be the default."
  }
}

run "restore_integrations_and_rotation" {
  command = plan

  variables {
    name                           = "unit-integrations"
    engine_version                 = "17.5"
    cluster_instance_class         = "db.r7g.large"
    final_snapshot_identifier      = "unit-integrations-final-v1"
    vpc_id                         = "vpc-0123456789abcdef0"
    subnet_ids                     = ["subnet-00000000000000001", "subnet-00000000000000002"]
    validate_network_configuration = false
    validate_engine_capabilities   = false
    monitoring_interval            = 60
    managed_master_user_secret_rotation = {
      enabled                  = true
      automatically_after_days = 30
    }
    custom_endpoints = {
      reporting = {
        type           = "READER"
        static_members = ["reader"]
      }
    }
    instances = {
      writer = {}
      reader = {}
    }
    cluster_role_associations = {
      s3 = {
        role_arn     = "arn:aws:iam::123456789012:role/rds-s3-integration"
        feature_name = "S3_INTEGRATION"
      }
    }
  }

  assert {
    condition = (
      length(aws_rds_cluster_endpoint.main) == 1 &&
      length(aws_rds_cluster_role_association.main) == 1 &&
      length(aws_secretsmanager_secret_rotation.master) == 1
    )
    error_message = "Custom endpoints, IAM role associations, and managed-secret rotation should be created."
  }
}

run "point_in_time_restore" {
  command = plan

  variables {
    name                           = "unit-pitr"
    engine_version                 = "17.5"
    cluster_instance_class         = "db.r7g.large"
    final_snapshot_identifier      = "unit-pitr-final-v1"
    vpc_id                         = "vpc-0123456789abcdef0"
    subnet_ids                     = ["subnet-00000000000000001", "subnet-00000000000000002"]
    validate_network_configuration = false
    validate_engine_capabilities   = false
    restore_to_point_in_time = {
      source_cluster_identifier  = "source-cluster"
      use_latest_restorable_time = true
    }
  }

  assert {
    condition     = aws_rds_cluster.main[0].restore_to_point_in_time[0].source_cluster_identifier == "source-cluster"
    error_message = "Point-in-time restore settings should be forwarded to the cluster."
  }
}

run "advanced_database_insights" {
  command = plan

  variables {
    name                                  = "unit-insights"
    engine_version                        = "17.5"
    cluster_instance_class                = "db.r7g.large"
    final_snapshot_identifier             = "unit-insights-final-v1"
    vpc_id                                = "vpc-0123456789abcdef0"
    subnet_ids                            = ["subnet-00000000000000001", "subnet-00000000000000002"]
    validate_network_configuration        = false
    validate_engine_capabilities          = false
    database_insights_mode                = "advanced"
    monitoring_interval                   = 60
    performance_insights_retention_period = 465
  }

  assert {
    condition = (
      aws_rds_cluster.main[0].database_insights_mode == "advanced" &&
      aws_rds_cluster.main[0].performance_insights_retention_period == 465
    )
    error_message = "Advanced Database Insights should configure cluster-level monitoring and retention."
  }
}

run "final_snapshot_identifier_required" {
  command = plan

  variables {
    name                           = "invalid-final-snapshot"
    engine_version                 = "17.5"
    cluster_instance_class         = "db.r7g.large"
    vpc_id                         = "vpc-0123456789abcdef0"
    subnet_ids                     = ["subnet-00000000000000001", "subnet-00000000000000002"]
    validate_network_configuration = false
    validate_engine_capabilities   = false
  }

  expect_failures = [aws_rds_cluster.main]
}

run "subnets_must_span_availability_zones" {
  command = plan

  variables {
    name                         = "invalid-subnet-azs"
    engine_version               = "17.5"
    cluster_instance_class       = "db.r7g.large"
    final_snapshot_identifier    = "invalid-subnet-azs-final-v1"
    vpc_id                       = "vpc-0123456789abcdef0"
    validate_engine_capabilities = false
    subnet_ids = [
      "subnet-00000000000000001",
      "subnet-00000000000000002"
    ]
  }

  expect_failures = [aws_db_subnet_group.main]
}

run "deprecated_engine_version_rejected" {
  command = plan

  variables {
    name                           = "invalid-engine-version"
    engine_version                 = "17.5"
    cluster_instance_class         = "db.r7g.large"
    final_snapshot_identifier      = "invalid-engine-version-final-v1"
    vpc_id                         = "vpc-0123456789abcdef0"
    subnet_ids                     = ["subnet-00000000000000001", "subnet-00000000000000002"]
    validate_network_configuration = false
  }

  override_data {
    target = data.aws_rds_engine_version.selected[0]
    values = {
      status               = "deprecated"
      exportable_log_types = ["postgresql"]
    }
  }

  expect_failures = [aws_rds_cluster.main]
}
