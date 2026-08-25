resource "aws_rds_global_cluster" "main" {
  count = local.create_global ? 1 : 0

  region                       = var.region
  global_cluster_identifier    = coalesce(var.global_cluster_identifier, substr("${var.name}-global", 0, 63))
  engine                       = var.engine
  engine_version               = var.engine_version
  engine_lifecycle_support     = var.engine_lifecycle_support
  database_name                = var.global_cluster_source_db_cluster_identifier == null ? var.database_name : null
  source_db_cluster_identifier = var.global_cluster_source_db_cluster_identifier
  storage_encrypted            = var.storage_encrypted
  deletion_protection          = var.global_cluster_deletion_protection
  force_destroy                = var.global_cluster_force_destroy
  tags                         = local.common_tags

  dynamic "timeouts" {
    for_each = var.global_cluster_timeouts == null ? [] : [var.global_cluster_timeouts]

    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  lifecycle {
    precondition {
      condition     = local.is_aurora
      error_message = "RDS global clusters require engine aurora-postgresql or aurora-mysql."
    }
  }
}

resource "aws_rds_cluster" "main" {
  count = local.create_rds ? 1 : 0

  region                              = var.region
  cluster_identifier                  = var.name
  engine                              = var.engine
  engine_mode                         = local.is_limitless ? null : var.engine_mode
  engine_version                      = var.engine_version
  engine_lifecycle_support            = var.engine_lifecycle_support
  cluster_scalability_type            = local.is_limitless ? "limitless" : null
  database_name                       = local.use_primary_settings ? var.database_name : null
  master_username                     = local.use_primary_settings ? var.master_username : null
  manage_master_user_password         = local.use_managed_master_password ? true : null
  master_user_secret_kms_key_id       = local.use_managed_master_password ? var.master_user_secret_kms_key_id : null
  master_password_wo                  = local.use_caller_master_password ? var.master_password_wo : null
  master_password_wo_version          = local.use_caller_master_password ? var.master_password_wo_version : null
  port                                = local.port
  allocated_storage                   = local.is_multi_az ? var.allocated_storage : null
  db_cluster_instance_class           = local.is_multi_az ? var.cluster_instance_class : null
  storage_type                        = var.storage_type
  iops                                = local.is_multi_az ? var.iops : null
  storage_encrypted                   = var.storage_encrypted
  kms_key_id                          = var.kms_key_id
  availability_zones                  = var.availability_zones
  ca_certificate_identifier           = local.is_multi_az ? var.cluster_ca_certificate_identifier : null
  db_subnet_group_name                = local.db_subnet_group_name
  vpc_security_group_ids              = local.security_group_ids
  db_cluster_parameter_group_name     = local.cluster_parameter_group_name
  db_instance_parameter_group_name    = local.is_multi_az ? local.db_parameter_group_name : null
  backup_retention_period             = var.backup_retention_period
  preferred_backup_window             = local.is_serverless_v1 ? null : var.preferred_backup_window
  preferred_maintenance_window        = var.preferred_maintenance_window
  copy_tags_to_snapshot               = var.copy_tags_to_snapshot
  delete_automated_backups            = var.delete_automated_backups
  deletion_protection                 = var.deletion_protection
  skip_final_snapshot                 = var.skip_final_snapshot
  final_snapshot_identifier           = var.skip_final_snapshot ? null : var.final_snapshot_identifier
  snapshot_identifier                 = var.snapshot_identifier
  replication_source_identifier       = var.replication_source_identifier
  source_region                       = var.source_region
  apply_immediately                   = var.apply_immediately
  allow_major_version_upgrade         = var.allow_major_version_upgrade
  auto_minor_version_upgrade          = var.auto_minor_version_upgrade
  backtrack_window                    = var.engine == "aurora-mysql" && !local.is_serverless_v1 ? var.backtrack_window : 0
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  enable_http_endpoint                = var.enable_http_endpoint
  enable_global_write_forwarding      = var.enable_global_write_forwarding
  enable_local_write_forwarding       = var.enable_local_write_forwarding
  enabled_cloudwatch_logs_exports     = var.enabled_cloudwatch_logs_exports
  global_cluster_identifier           = local.global_cluster_identifier
  network_type                        = var.network_type
  monitoring_interval                 = var.monitoring_interval
  monitoring_role_arn                 = var.monitoring_interval > 0 ? local.monitoring_role_arn : null
  database_insights_mode              = local.is_serverless_v1 ? null : var.database_insights_mode
  performance_insights_enabled        = local.is_serverless_v1 ? null : var.performance_insights_enabled
  performance_insights_kms_key_id     = !local.is_serverless_v1 && var.performance_insights_enabled ? var.performance_insights_kms_key_id : null
  performance_insights_retention_period = (
    !local.is_serverless_v1 && var.performance_insights_enabled ? var.performance_insights_retention_period : null
  )

  dynamic "restore_to_point_in_time" {
    for_each = var.restore_to_point_in_time == null ? [] : [var.restore_to_point_in_time]

    content {
      source_cluster_identifier  = restore_to_point_in_time.value.source_cluster_identifier
      source_cluster_resource_id = restore_to_point_in_time.value.source_cluster_resource_id
      restore_type               = restore_to_point_in_time.value.restore_type
      restore_to_time            = restore_to_point_in_time.value.restore_to_time
      use_latest_restorable_time = restore_to_point_in_time.value.use_latest_restorable_time
    }
  }

  dynamic "s3_import" {
    for_each = var.s3_import == null ? [] : [var.s3_import]

    content {
      bucket_name           = s3_import.value.bucket_name
      bucket_prefix         = s3_import.value.bucket_prefix
      ingestion_role        = s3_import.value.ingestion_role
      source_engine         = s3_import.value.source_engine
      source_engine_version = s3_import.value.source_engine_version
    }
  }

  dynamic "scaling_configuration" {
    for_each = local.is_serverless_v1 && var.serverless_v1_scaling_configuration != null ? [var.serverless_v1_scaling_configuration] : []

    content {
      auto_pause               = scaling_configuration.value.auto_pause
      max_capacity             = scaling_configuration.value.max_capacity
      min_capacity             = scaling_configuration.value.min_capacity
      seconds_before_timeout   = scaling_configuration.value.seconds_before_timeout
      seconds_until_auto_pause = scaling_configuration.value.seconds_until_auto_pause
      timeout_action           = scaling_configuration.value.timeout_action
    }
  }

  dynamic "serverlessv2_scaling_configuration" {
    for_each = var.serverless_v2_scaling_configuration == null ? [] : [var.serverless_v2_scaling_configuration]

    content {
      min_capacity             = serverlessv2_scaling_configuration.value.min_capacity
      max_capacity             = serverlessv2_scaling_configuration.value.max_capacity
      seconds_until_auto_pause = serverlessv2_scaling_configuration.value.seconds_until_auto_pause
    }
  }

  dynamic "timeouts" {
    for_each = var.cluster_timeouts == null ? [] : [var.cluster_timeouts]

    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  tags = local.common_tags

  depends_on = [
    aws_cloudwatch_log_group.main,
    aws_iam_role_policy_attachment.monitoring
  ]

  lifecycle {
    precondition {
      condition     = local.is_aurora || var.allocated_storage != null
      error_message = "RDS Multi-AZ DB clusters using engine postgres or mysql require allocated_storage."
    }

    precondition {
      condition     = local.is_multi_az || var.allocated_storage == null
      error_message = "allocated_storage selects RDS Multi-AZ mode and cannot be set for an Aurora engine."
    }

    precondition {
      condition = local.is_multi_az ? (var.storage_type == null ? false : contains(["gp3", "io1", "io2"], var.storage_type)) : (
        var.storage_type == null ? true : contains(["aurora", "aurora-iopt1"], var.storage_type)
      )
      error_message = "Aurora storage_type must be aurora or aurora-iopt1; RDS Multi-AZ storage_type must be gp3, io1, or io2."
    }

    precondition {
      condition     = !local.is_limitless || var.storage_type == "aurora-iopt1"
      error_message = "Aurora Limitless requires storage_type = aurora-iopt1."
    }

    precondition {
      condition = !local.is_multi_az ? true : (
        var.storage_type == null ? false : (
          contains(["io1", "io2"], var.storage_type) ? (
            var.iops == null || var.allocated_storage == null ? false : (
              var.iops / var.allocated_storage >= 0.5 && var.iops / var.allocated_storage <= 50
            )
            ) : (
            var.iops == null ? true : (var.allocated_storage == null ? false : (
              var.iops / var.allocated_storage >= 0.5 && var.iops / var.allocated_storage <= 50
            ))
          )
        )
      )
      error_message = "RDS Multi-AZ io1/io2 storage requires iops, and the IOPS-to-storage ratio must be between 0.5 and 50."
    }

    precondition {
      condition     = !local.is_multi_az || var.cluster_instance_class != null
      error_message = "RDS Multi-AZ DB clusters require cluster_instance_class."
    }

    precondition {
      condition     = local.is_aurora || var.engine_mode == "provisioned"
      error_message = "RDS Multi-AZ DB clusters support only engine_mode = provisioned."
    }

    precondition {
      condition     = !local.create_subnet_group || length(var.subnet_ids) >= 2
      error_message = "Provide at least two subnet IDs when create_db_subnet_group is true."
    }

    precondition {
      condition     = !local.is_multi_az || !local.create_subnet_group || !local.validate_network || length(local.selected_subnet_azs) == 3
      error_message = "RDS Multi-AZ DB clusters require subnets in exactly three Availability Zones."
    }

    precondition {
      condition = var.availability_zones == null ? true : (
        !local.create_subnet_group || !local.validate_network || alltrue([
          for availability_zone in var.availability_zones : contains(local.selected_subnet_azs, availability_zone)
        ])
      )
      error_message = "Each configured availability_zone must have a subnet in the DB subnet group."
    }

    precondition {
      condition     = !local.is_multi_az ? true : (var.availability_zones == null ? true : length(var.availability_zones) == 3)
      error_message = "RDS Multi-AZ DB clusters require exactly three configured availability_zones when the input is set."
    }

    precondition {
      condition     = local.create_subnet_group ? true : (var.db_subnet_group_name == null ? false : trimspace(var.db_subnet_group_name) != "")
      error_message = "db_subnet_group_name is required when create_db_subnet_group is false."
    }

    precondition {
      condition     = !local.create_security_group ? true : (var.vpc_id == null ? false : trimspace(var.vpc_id) != "")
      error_message = "vpc_id is required when create_security_group is true."
    }

    precondition {
      condition     = !local.validate_network || length(var.security_group_ids) == 0 || var.vpc_id != null
      error_message = "vpc_id is required to validate existing security_group_ids."
    }

    precondition {
      condition = !local.validate_network || alltrue([
        for security_group in values(data.aws_security_group.selected) : security_group.vpc_id == var.vpc_id
      ])
      error_message = "Every existing security group must belong to vpc_id."
    }

    precondition {
      condition = !local.create_instances || alltrue([
        for instance in values(var.instances) : (
          instance.instance_class != null || local.is_serverless_v2 || var.cluster_instance_class != null
        )
      ])
      error_message = "Each Aurora instance requires instance_class or a module-level cluster_instance_class."
    }

    precondition {
      condition     = !local.is_serverless_v1 || (local.is_aurora && var.serverless_v2_scaling_configuration == null)
      error_message = "Serverless v1 requires an Aurora engine and cannot use a Serverless v2 scaling configuration."
    }

    precondition {
      condition = var.serverless_v2_scaling_configuration == null ? true : (
        local.is_aurora && var.engine_mode == "provisioned" &&
        (var.cluster_instance_class == null || var.cluster_instance_class == "db.serverless") &&
        alltrue([for instance in values(var.instances) : coalesce(instance.instance_class, "db.serverless") == "db.serverless"])
      )
      error_message = "Serverless v2 requires an Aurora engine, engine_mode = provisioned, and db.serverless instances."
    }

    precondition {
      condition = !local.is_limitless || (
        var.engine == "aurora-postgresql" && var.engine_mode == "provisioned" && var.shard_group != null
      )
      error_message = "Aurora Limitless requires aurora-postgresql, provisioned engine mode, and shard_group."
    }

    precondition {
      condition     = local.is_limitless || var.shard_group == null
      error_message = "shard_group can be set only when cluster_scalability_type is limitless."
    }

    precondition {
      condition     = !local.has_global_cluster || local.is_aurora
      error_message = "Only Aurora engines can join an RDS global cluster."
    }

    precondition {
      condition     = !(var.manage_master_user_password && var.master_password_wo_version != null)
      error_message = "master_password_wo and master_password_wo_version must be omitted when manage_master_user_password is true."
    }

    precondition {
      condition     = !local.use_caller_master_password || var.master_password_wo_version != null
      error_message = "A write-only master_password_wo and positive master_password_wo_version are required for primary global clusters or when manage_master_user_password is false."
    }

    precondition {
      condition     = var.skip_final_snapshot || var.final_snapshot_identifier != null
      error_message = "final_snapshot_identifier is required when skip_final_snapshot is false. Use a unique value for every cluster lifecycle."
    }

    precondition {
      condition = sum([
        var.snapshot_identifier != null ? 1 : 0,
        var.replication_source_identifier != null ? 1 : 0,
        var.restore_to_point_in_time != null ? 1 : 0,
        var.s3_import != null ? 1 : 0
      ]) <= 1
      error_message = "Configure only one creation source: snapshot_identifier, replication_source_identifier, restore_to_point_in_time, or s3_import."
    }

    precondition {
      condition     = var.s3_import == null ? true : (var.engine == "aurora-mysql" && !local.is_serverless_v1)
      error_message = "s3_import is supported only for provisioned Aurora MySQL clusters."
    }

    precondition {
      condition = var.database_insights_mode != "advanced" || (
        var.performance_insights_enabled &&
        var.performance_insights_retention_period >= 465 &&
        var.monitoring_interval > 0
      )
      error_message = "Advanced Database Insights requires Performance Insights, at least 465 days of retention, and Enhanced Monitoring."
    }

    precondition {
      condition = local.is_serverless_v1 || !local.create_instances || alltrue([
        for instance in values(var.instances) :
        coalesce(instance.performance_insights_enabled, var.performance_insights_enabled) == var.performance_insights_enabled &&
        coalesce(instance.performance_insights_retention_period, var.performance_insights_retention_period) == var.performance_insights_retention_period &&
        coalesce(instance.monitoring_interval, var.monitoring_interval) == var.monitoring_interval
      ])
      error_message = "Aurora instances must use the same Performance Insights retention and Enhanced Monitoring settings as the cluster for Database Insights."
    }

    precondition {
      condition     = !var.managed_master_user_secret_rotation.enabled || local.use_managed_master_password
      error_message = "Managed master-user secret rotation requires an RDS-managed password on a primary non-global cluster."
    }

    precondition {
      condition = !var.managed_master_user_secret_rotation.enabled || length([
        for schedule in [
          var.managed_master_user_secret_rotation.automatically_after_days == null ? null : tostring(var.managed_master_user_secret_rotation.automatically_after_days),
          var.managed_master_user_secret_rotation.schedule_expression
        ] : schedule if schedule != null
      ]) == 1
      error_message = "Managed secret rotation requires exactly one of automatically_after_days or schedule_expression."
    }

    precondition {
      condition     = !local.validate_engine ? true : data.aws_rds_engine_version.selected[0].status == "available"
      error_message = "The selected engine version is not currently available in the target Region."
    }

    precondition {
      condition     = !local.validate_engine ? true : (!local.is_serverless_v1 || contains(data.aws_rds_engine_version.selected[0].supported_modes, "serverless"))
      error_message = "The selected engine version does not support Serverless v1."
    }

    precondition {
      condition     = !local.validate_engine ? true : (!local.has_global_cluster || data.aws_rds_engine_version.selected[0].supports_global_databases)
      error_message = "The selected engine version does not support Aurora global databases."
    }

    precondition {
      condition     = !local.validate_engine ? true : (!local.is_limitless || data.aws_rds_engine_version.selected[0].supports_limitless_database)
      error_message = "The selected engine version does not support Aurora Limitless."
    }

    precondition {
      condition = !local.validate_engine ? true : alltrue([
        for instance_class in local.orderable_instance_classes :
        data.aws_rds_orderable_db_instance.selected[instance_class].instance_class == instance_class
      ])
      error_message = "One or more selected DB instance classes are not orderable for the engine version, storage type, and Region."
    }

    precondition {
      condition     = !local.validate_engine ? true : (!var.enable_local_write_forwarding || data.aws_rds_engine_version.selected[0].supports_local_write_forwarding)
      error_message = "The selected engine version does not support local write forwarding."
    }

    precondition {
      condition = !local.validate_engine ? true : length(setsubtract(
        var.enabled_cloudwatch_logs_exports,
        data.aws_rds_engine_version.selected[0].exportable_log_types
      )) == 0
      error_message = "One or more enabled CloudWatch log exports are not supported by the selected engine version."
    }

    precondition {
      condition     = !local.monitoring_requested || local.monitoring_role_arn != null
      error_message = "Enhanced Monitoring requires create_monitoring_role = true or monitoring_role_arn."
    }

    precondition {
      condition     = !var.autoscaling.enabled || (local.is_aurora && !local.is_serverless_v1 && !local.is_limitless)
      error_message = "Reader autoscaling supports standard provisioned Aurora clusters only."
    }
  }
}

resource "aws_rds_cluster_instance" "main" {
  for_each = local.create_instances ? var.instances : {}

  region                                = var.region
  identifier                            = coalesce(each.value.identifier, substr("${var.name}-${each.key}", 0, 63))
  cluster_identifier                    = aws_rds_cluster.main[0].id
  engine                                = var.engine
  engine_version                        = var.engine_version
  instance_class                        = each.value.instance_class != null ? each.value.instance_class : (local.is_serverless_v2 ? "db.serverless" : var.cluster_instance_class)
  db_subnet_group_name                  = local.db_subnet_group_name
  db_parameter_group_name               = local.db_parameter_group_name
  availability_zone                     = each.value.availability_zone
  publicly_accessible                   = each.value.publicly_accessible
  promotion_tier                        = each.value.promotion_tier
  apply_immediately                     = coalesce(each.value.apply_immediately, var.apply_immediately)
  auto_minor_version_upgrade            = coalesce(each.value.auto_minor_version_upgrade, var.auto_minor_version_upgrade)
  ca_cert_identifier                    = each.value.ca_cert_identifier
  monitoring_interval                   = coalesce(each.value.monitoring_interval, var.monitoring_interval)
  monitoring_role_arn                   = coalesce(each.value.monitoring_interval, var.monitoring_interval) > 0 ? coalesce(each.value.monitoring_role_arn, local.monitoring_role_arn) : null
  performance_insights_enabled          = coalesce(each.value.performance_insights_enabled, var.performance_insights_enabled)
  performance_insights_kms_key_id       = coalesce(each.value.performance_insights_enabled, var.performance_insights_enabled) ? (each.value.performance_insights_kms_key_id != null ? each.value.performance_insights_kms_key_id : var.performance_insights_kms_key_id) : null
  performance_insights_retention_period = coalesce(each.value.performance_insights_enabled, var.performance_insights_enabled) ? coalesce(each.value.performance_insights_retention_period, var.performance_insights_retention_period) : null
  preferred_backup_window               = each.value.preferred_backup_window
  preferred_maintenance_window          = each.value.preferred_maintenance_window
  copy_tags_to_snapshot                 = var.copy_tags_to_snapshot

  dynamic "timeouts" {
    for_each = each.value.timeouts == null ? [] : [each.value.timeouts]

    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  tags = merge(local.common_tags, each.value.tags)

  depends_on = [aws_iam_role_policy_attachment.monitoring]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_rds_shard_group" "main" {
  count = local.create_rds && local.is_limitless ? 1 : 0

  region                    = var.region
  db_cluster_identifier     = aws_rds_cluster.main[0].id
  db_shard_group_identifier = coalesce(var.shard_group.identifier, substr("${var.name}-shards", 0, 63))
  max_acu                   = var.shard_group.max_acu
  min_acu                   = var.shard_group.min_acu
  compute_redundancy        = var.shard_group.compute_redundancy
  publicly_accessible       = var.shard_group.publicly_accessible

  dynamic "timeouts" {
    for_each = var.shard_group.timeouts == null ? [] : [var.shard_group.timeouts]

    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  tags = merge(local.common_tags, var.shard_group.tags)
}
