mock_provider "aws" {
  override_during = plan
}

run "global_primary" {
  command = plan

  variables {
    name                           = "unit-global"
    final_snapshot_identifier      = "unit-global-final-v1"
    engine_version                 = "17.5"
    create_global_cluster          = true
    manage_master_user_password    = false
    master_password_wo             = "UnitTestPassw0rd!"
    master_password_wo_version     = 1
    cluster_instance_class         = "db.r7g.large"
    vpc_id                         = "vpc-0123456789abcdef0"
    subnet_ids                     = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
    validate_network_configuration = false
    validate_engine_capabilities   = false
  }

  assert {
    condition     = aws_rds_global_cluster.main[0].global_cluster_identifier == "unit-global-global"
    error_message = "The module should create a global cluster container."
  }

  assert {
    condition     = length(aws_rds_cluster.main) == 1 && aws_rds_cluster.main[0].manage_master_user_password == null
    error_message = "The regional primary should be created with caller-managed global-cluster credentials."
  }
}

run "dsql_single_region" {
  command = plan

  variables {
    name               = "unit-dsql"
    create_rds_cluster = false
    dsql_clusters = {
      primary = {}
    }
  }

  assert {
    condition     = length(aws_rds_cluster.main) == 0 && length(aws_dsql_cluster.main) == 1
    error_message = "A DSQL-only call should not create an RDS cluster."
  }

  assert {
    condition = (
      aws_dsql_cluster.main["primary"].deletion_protection_enabled == true &&
      aws_dsql_cluster.main["primary"].force_destroy == false &&
      aws_dsql_cluster.main["primary"].kms_encryption_key == "AWS_OWNED_KMS_KEY"
    )
    error_message = "DSQL should use protected, encrypted defaults."
  }
}

run "dsql_peering" {
  command = plan

  variables {
    name               = "unit-dsql-peer"
    create_rds_cluster = false
    dsql_peerings = {
      primary = {
        identifier     = "primary-cluster-id"
        clusters       = ["arn:aws:dsql:eu-west-1:123456789012:cluster/peer-id"]
        witness_region = "eu-central-1"
      }
    }
  }

  assert {
    condition     = aws_dsql_cluster_peering.main["primary"].witness_region == "eu-central-1"
    error_message = "DSQL peering should forward the witness Region."
  }
}
