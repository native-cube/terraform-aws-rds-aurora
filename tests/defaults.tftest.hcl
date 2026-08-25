mock_provider "aws" {
  override_during = plan
}

run "aurora_postgresql_production_defaults" {
  command = plan

  variables {
    name                           = "unit-postgres"
    final_snapshot_identifier      = "unit-postgres-final-v1"
    engine_version                 = "17.5"
    cluster_instance_class         = "db.r7g.large"
    vpc_id                         = "vpc-0123456789abcdef0"
    validate_network_configuration = false
    validate_engine_capabilities   = false
    subnet_ids = [
      "subnet-0123456789abcdef0",
      "subnet-0fedcba9876543210"
    ]
  }

  assert {
    condition = (
      aws_rds_cluster.main[0].engine == "aurora-postgresql" &&
      aws_rds_cluster.main[0].port == 5432 &&
      aws_rds_cluster.main[0].storage_encrypted &&
      aws_rds_cluster.main[0].deletion_protection &&
      aws_rds_cluster.main[0].backup_retention_period == 7
    )
    error_message = "Aurora PostgreSQL should use the documented production defaults."
  }

  assert {
    condition = (
      aws_rds_cluster.main[0].manage_master_user_password == true &&
      aws_rds_cluster.main[0].iam_database_authentication_enabled == true
    )
    error_message = "RDS-managed credentials and IAM database authentication should be enabled by default."
  }

  assert {
    condition     = length(aws_rds_cluster_instance.main) == 1 && aws_rds_cluster_instance.main["one"].instance_class == "db.r7g.large"
    error_message = "A standard Aurora cluster should create the declared instance."
  }

  assert {
    condition     = length(aws_security_group.main) == 1 && length(aws_db_subnet_group.main) == 1
    error_message = "Networking resources should be created by default."
  }

  assert {
    condition     = length(aws_vpc_security_group_egress_rule.main) == 0
    error_message = "The default security group should deny outbound traffic until callers explicitly add egress rules."
  }
}

run "aurora_mysql" {
  command = plan

  variables {
    name                           = "unit-mysql"
    final_snapshot_identifier      = "unit-mysql-final-v1"
    engine                         = "aurora-mysql"
    engine_version                 = "8.0.mysql_aurora.3.10.0"
    cluster_instance_class         = "db.r7g.large"
    backtrack_window               = 3600
    vpc_id                         = "vpc-0123456789abcdef0"
    validate_network_configuration = false
    validate_engine_capabilities   = false
    subnet_ids = [
      "subnet-0123456789abcdef0",
      "subnet-0fedcba9876543210"
    ]
  }

  assert {
    condition     = aws_rds_cluster.main[0].engine == "aurora-mysql" && aws_rds_cluster.main[0].port == 3306 && aws_rds_cluster.main[0].backtrack_window == 3600
    error_message = "Aurora MySQL should use port 3306 and support backtracking."
  }
}
