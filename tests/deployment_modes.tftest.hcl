mock_provider "aws" {
  override_during = plan
}

run "serverless_v1" {
  command = plan

  variables {
    name                           = "unit-serverless-v1"
    final_snapshot_identifier      = "unit-serverless-v1-final-v1"
    engine                         = "aurora-mysql"
    engine_mode                    = "serverless"
    engine_version                 = "5.7.mysql_aurora.2.11.4"
    cluster_instance_class         = null
    vpc_id                         = "vpc-0123456789abcdef0"
    subnet_ids                     = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
    performance_insights_enabled   = false
    validate_network_configuration = false
    validate_engine_capabilities   = false
    serverless_v1_scaling_configuration = {
      min_capacity             = 2
      max_capacity             = 16
      seconds_until_auto_pause = 900
    }
  }

  assert {
    condition     = aws_rds_cluster.main[0].engine_mode == "serverless" && length(aws_rds_cluster_instance.main) == 0
    error_message = "Serverless v1 should use serverless engine mode without cluster instances."
  }

  assert {
    condition     = aws_rds_cluster.main[0].scaling_configuration[0].min_capacity == 2
    error_message = "Serverless v1 scaling configuration should be forwarded."
  }
}

run "serverless_v2" {
  command = plan

  variables {
    name                           = "unit-serverless-v2"
    final_snapshot_identifier      = "unit-serverless-v2-final-v1"
    engine_version                 = "17.5"
    vpc_id                         = "vpc-0123456789abcdef0"
    subnet_ids                     = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
    validate_network_configuration = false
    validate_engine_capabilities   = false
    serverless_v2_scaling_configuration = {
      min_capacity = 0.5
      max_capacity = 8
    }
    instances = {
      writer = {}
      reader = {}
    }
  }

  assert {
    condition     = aws_rds_cluster.main[0].engine_mode == "provisioned" && aws_rds_cluster.main[0].serverlessv2_scaling_configuration[0].max_capacity == 8
    error_message = "Serverless v2 should keep provisioned engine mode and configure ACU scaling."
  }

  assert {
    condition     = length(aws_rds_cluster_instance.main) == 2 && alltrue([for instance in aws_rds_cluster_instance.main : instance.instance_class == "db.serverless"])
    error_message = "Serverless v2 should create db.serverless instances."
  }
}

run "rds_multi_az_postgresql" {
  command = plan

  variables {
    name                           = "unit-multi-az"
    final_snapshot_identifier      = "unit-multi-az-final-v1"
    engine                         = "postgres"
    engine_version                 = "17.5"
    allocated_storage              = 100
    storage_type                   = "io1"
    iops                           = 1000
    cluster_instance_class         = "db.m6gd.large"
    vpc_id                         = "vpc-0123456789abcdef0"
    subnet_ids                     = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
    validate_network_configuration = false
    validate_engine_capabilities   = false
  }

  assert {
    condition = (
      aws_rds_cluster.main[0].engine == "postgres" &&
      aws_rds_cluster.main[0].allocated_storage == 100 &&
      aws_rds_cluster.main[0].db_cluster_instance_class == "db.m6gd.large" &&
      length(aws_rds_cluster_instance.main) == 0
    )
    error_message = "RDS Multi-AZ mode should configure managed cluster instances on aws_rds_cluster only."
  }
}

run "aurora_limitless" {
  command = plan

  variables {
    name                           = "unit-limitless"
    final_snapshot_identifier      = "unit-limitless-final-v1"
    engine_version                 = "16.6-limitless"
    storage_type                   = "aurora-iopt1"
    vpc_id                         = "vpc-0123456789abcdef0"
    subnet_ids                     = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
    validate_network_configuration = false
    validate_engine_capabilities   = false
    cluster_scalability_type       = "limitless"
    shard_group = {
      identifier         = "unit-limitless-shards"
      max_acu            = 128
      compute_redundancy = 1
    }
  }

  assert {
    condition     = aws_rds_cluster.main[0].cluster_scalability_type == "limitless" && length(aws_rds_cluster_instance.main) == 0
    error_message = "Limitless should create no standard Aurora instances."
  }

  assert {
    condition     = aws_rds_shard_group.main[0].max_acu == 128 && aws_rds_shard_group.main[0].compute_redundancy == 1
    error_message = "Limitless should create the configured DB shard group."
  }
}
