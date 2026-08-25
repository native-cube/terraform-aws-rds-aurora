mock_provider "aws" {
  override_during = plan
}

run "multi_az_requires_storage" {
  command = plan

  variables {
    name                           = "invalid-multi-az"
    final_snapshot_identifier      = "invalid-multi-az-final-v1"
    engine                         = "postgres"
    cluster_instance_class         = "db.m6gd.large"
    vpc_id                         = "vpc-0123456789abcdef0"
    subnet_ids                     = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
    validate_network_configuration = false
    validate_engine_capabilities   = false
  }

  expect_failures = [aws_rds_cluster.main]
}

run "limitless_requires_postgresql" {
  command = plan

  variables {
    name                           = "invalid-limitless"
    final_snapshot_identifier      = "invalid-limitless-final-v1"
    engine                         = "aurora-mysql"
    cluster_scalability_type       = "limitless"
    vpc_id                         = "vpc-0123456789abcdef0"
    subnet_ids                     = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
    storage_type                   = "aurora-iopt1"
    validate_network_configuration = false
    validate_engine_capabilities   = false
    shard_group = {
      max_acu = 64
    }
  }

  expect_failures = [aws_rds_cluster.main]
}

run "global_primary_requires_caller_password" {
  command = plan

  variables {
    name                           = "invalid-global"
    final_snapshot_identifier      = "invalid-global-final-v1"
    create_global_cluster          = true
    cluster_instance_class         = "db.r7g.large"
    vpc_id                         = "vpc-0123456789abcdef0"
    subnet_ids                     = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
    validate_network_configuration = false
    validate_engine_capabilities   = false
  }

  expect_failures = [aws_rds_cluster.main]
}
