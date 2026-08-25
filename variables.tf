variable "create" {
  description = "Whether to create module-managed resources."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name used for the RDS cluster and as a prefix for module-created resources."
  type        = string

  validation {
    condition = (
      can(regex("^[a-z][a-z0-9-]{0,62}$", var.name)) &&
      !endswith(var.name, "-") &&
      !strcontains(var.name, "--")
    )
    error_message = "name must be 1-63 lowercase letters, numbers, and hyphens; start with a letter; and not end with or contain consecutive hyphens."
  }
}

variable "region" {
  description = "Optional AWS Region for resources. When null, the AWS provider Region is used."
  type        = string
  default     = null
}

variable "validate_network_configuration" {
  description = "Whether to query subnet and security-group metadata and reject cross-VPC or invalid Availability Zone topology during planning."
  type        = bool
  default     = true
}

variable "validate_engine_capabilities" {
  description = "Whether to query the selected RDS engine version and regional instance offerings to validate requested capabilities during planning."
  type        = bool
  default     = true
}

variable "create_rds_cluster" {
  description = "Whether to create an RDS/Aurora cluster. Set false for DSQL-only or global-container-only module calls."
  type        = bool
  default     = true
}

variable "engine" {
  description = "Database engine. Aurora uses aurora-postgresql or aurora-mysql; postgres and mysql create RDS Multi-AZ DB clusters."
  type        = string
  default     = "aurora-postgresql"

  validation {
    condition     = contains(["aurora-postgresql", "aurora-mysql", "postgres", "mysql"], var.engine)
    error_message = "engine must be aurora-postgresql, aurora-mysql, postgres, or mysql."
  }
}

variable "engine_mode" {
  description = "Aurora engine mode. Use provisioned for provisioned clusters and Serverless v2, or serverless for Serverless v1."
  type        = string
  default     = "provisioned"

  validation {
    condition     = contains(["provisioned", "serverless"], var.engine_mode)
    error_message = "engine_mode must be provisioned or serverless."
  }
}

variable "engine_version" {
  description = "Database engine version. Specify explicitly in production so upgrades are deliberate."
  type        = string
  default     = null
}

variable "engine_lifecycle_support" {
  description = "Optional RDS Extended Support lifecycle setting."
  type        = string
  default     = null

  validation {
    condition = var.engine_lifecycle_support == null ? true : contains([
      "open-source-rds-extended-support",
      "open-source-rds-extended-support-disabled"
      ], var.engine_lifecycle_support
    )
    error_message = "engine_lifecycle_support must be an RDS open-source extended-support value."
  }
}

variable "cluster_scalability_type" {
  description = "Aurora cluster scalability type. Set to limitless for Aurora PostgreSQL Limitless."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "limitless"], var.cluster_scalability_type)
    error_message = "cluster_scalability_type must be standard or limitless."
  }
}

variable "port" {
  description = "Database port. Defaults to 5432 for PostgreSQL engines and 3306 for MySQL engines."
  type        = number
  default     = null

  validation {
    condition     = var.port == null ? true : (floor(var.port) == var.port && var.port >= 1 && var.port <= 65535)
    error_message = "port must be an integer from 1 to 65535."
  }
}

variable "database_name" {
  description = "Initial database name for a primary cluster."
  type        = string
  default     = null
}

variable "is_primary_cluster" {
  description = "Whether this is a primary cluster. Secondary global clusters omit database and master-user settings."
  type        = bool
  default     = true
}

variable "master_username" {
  description = "Master username for a primary cluster."
  type        = string
  default     = "dbadmin"
}

variable "manage_master_user_password" {
  description = "Whether RDS manages the master password in Secrets Manager. This is the secure default."
  type        = bool
  default     = true
}

variable "master_password_wo" {
  description = "Optional write-only caller-managed master password. Terraform does not persist this ephemeral value in plans or state."
  type        = string
  default     = null
  sensitive   = true
  ephemeral   = true
}

variable "master_password_wo_version" {
  description = "Version used to trigger updates to master_password_wo. Increment this value whenever the write-only password changes."
  type        = number
  default     = null

  validation {
    condition     = var.master_password_wo_version == null ? true : (floor(var.master_password_wo_version) == var.master_password_wo_version && var.master_password_wo_version >= 1)
    error_message = "master_password_wo_version must be a positive whole number when set."
  }
}

variable "master_user_secret_kms_key_id" {
  description = "Optional KMS key ARN or ID used to encrypt the RDS-managed master-user secret."
  type        = string
  default     = null
}

variable "create_global_cluster" {
  description = "Whether to create an RDS global cluster container and attach this cluster to it."
  type        = bool
  default     = false
}

variable "global_cluster_identifier" {
  description = "Existing global cluster identifier to join, or identifier for the global cluster created by this module. Defaults to <name>-global when creating one."
  type        = string
  default     = null
}

variable "global_cluster_source_db_cluster_identifier" {
  description = "Optional source DB cluster ARN or identifier used to create a global cluster from an existing cluster."
  type        = string
  default     = null
}

variable "global_cluster_deletion_protection" {
  description = "Whether deletion protection is enabled for a module-created global cluster."
  type        = bool
  default     = true
}

variable "global_cluster_force_destroy" {
  description = "Whether to remove members from a module-created global cluster when it is destroyed."
  type        = bool
  default     = false
}

variable "global_cluster_timeouts" {
  description = "Optional create, update, and delete timeouts for the global cluster."
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}

variable "availability_zones" {
  description = "Optional Availability Zones for the RDS/Aurora cluster."
  type        = list(string)
  default     = null

  validation {
    condition = var.availability_zones == null ? true : (
      length(var.availability_zones) == length(distinct(var.availability_zones)) &&
      length(var.availability_zones) <= 3
    )
    error_message = "availability_zones must contain at most three unique Availability Zones."
  }
}

variable "subnet_ids" {
  description = "Existing subnet IDs used by a module-created DB subnet group. Supply at least two subnets in different Availability Zones."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.subnet_ids) == length(distinct(var.subnet_ids))
    error_message = "subnet_ids must not contain duplicates."
  }
}

variable "create_db_subnet_group" {
  description = "Whether to create a DB subnet group from subnet_ids."
  type        = bool
  default     = true
}

variable "db_subnet_group_name" {
  description = "Existing DB subnet group name when create_db_subnet_group is false, or an override for the created group."
  type        = string
  default     = null
}

variable "db_subnet_group_description" {
  description = "Description for the module-created DB subnet group."
  type        = string
  default     = "Managed by Terraform"
}

variable "vpc_id" {
  description = "VPC ID for the module-created database security group."
  type        = string
  default     = null
}

variable "create_security_group" {
  description = "Whether to create a security group for the RDS/Aurora cluster."
  type        = bool
  default     = true
}

variable "security_group_name" {
  description = "Optional name for the module-created security group. Defaults to <name>-database."
  type        = string
  default     = null
}

variable "security_group_description" {
  description = "Description for the module-created security group."
  type        = string
  default     = "Controls access to the database cluster"
}

variable "security_group_ids" {
  description = "Existing security group IDs associated with the RDS/Aurora cluster in addition to the optional created group."
  type        = set(string)
  default     = []
}

variable "revoke_rules_on_delete" {
  description = "Whether to revoke all security-group rules before deleting the module-created group."
  type        = bool
  default     = true
}

variable "ingress_rules" {
  description = "Ingress rules for the module-created security group, keyed by a stable name. The database port is used when ports are omitted."
  type = map(object({
    description                  = optional(string)
    from_port                    = optional(number)
    to_port                      = optional(number)
    ip_protocol                  = optional(string, "tcp")
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
    tags                         = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for rule in values(var.ingress_rules) : length([
        for source in [rule.cidr_ipv4, rule.cidr_ipv6, rule.prefix_list_id, rule.referenced_security_group_id] : source
        if source != null
      ]) == 1
    ])
    error_message = "Each ingress rule must set exactly one source: cidr_ipv4, cidr_ipv6, prefix_list_id, or referenced_security_group_id."
  }
}

variable "egress_rules" {
  description = "Egress rules for the module-created security group, keyed by a stable name. No outbound access is allowed by default."
  type = map(object({
    description                  = optional(string)
    from_port                    = optional(number)
    to_port                      = optional(number)
    ip_protocol                  = optional(string, "-1")
    cidr_ipv4                    = optional(string)
    cidr_ipv6                    = optional(string)
    prefix_list_id               = optional(string)
    referenced_security_group_id = optional(string)
    tags                         = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for rule in values(var.egress_rules) : length([
        for destination in [rule.cidr_ipv4, rule.cidr_ipv6, rule.prefix_list_id, rule.referenced_security_group_id] : destination
        if destination != null
      ]) == 1
    ])
    error_message = "Each egress rule must set exactly one destination: cidr_ipv4, cidr_ipv6, prefix_list_id, or referenced_security_group_id."
  }
}

variable "allocated_storage" {
  description = "Storage in GiB for an RDS Multi-AZ DB cluster. Setting this selects Multi-AZ mode and requires engine postgres or mysql."
  type        = number
  default     = null

  validation {
    condition     = var.allocated_storage == null ? true : (floor(var.allocated_storage) == var.allocated_storage && var.allocated_storage > 0)
    error_message = "allocated_storage must be a positive whole number when set."
  }
}

variable "storage_type" {
  description = "Cluster storage type. Aurora supports aurora and aurora-iopt1; RDS Multi-AZ DB clusters commonly use io1, io2, or gp3 according to engine support."
  type        = string
  default     = null

  validation {
    condition     = var.storage_type == null ? true : contains(["aurora", "aurora-iopt1", "gp3", "io1", "io2"], var.storage_type)
    error_message = "storage_type must be aurora, aurora-iopt1, gp3, io1, or io2 when set."
  }
}

variable "iops" {
  description = "Provisioned IOPS for an RDS Multi-AZ DB cluster when required by storage_type."
  type        = number
  default     = null

  validation {
    condition     = var.iops == null ? true : (floor(var.iops) == var.iops && var.iops > 0)
    error_message = "iops must be a positive whole number when set."
  }
}

variable "storage_encrypted" {
  description = "Whether cluster storage is encrypted."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "Optional KMS key ARN for cluster storage encryption."
  type        = string
  default     = null
}

variable "cluster_instance_class" {
  description = "Default Aurora instance class, or the managed instance class for an RDS Multi-AZ DB cluster. Serverless v2 defaults this to db.serverless."
  type        = string
  default     = null
}

variable "instances" {
  description = "Aurora cluster instances keyed by stable names. Ignored for Serverless v1, RDS Multi-AZ DB clusters, and Limitless."
  type = map(object({
    identifier                            = optional(string)
    instance_class                        = optional(string)
    availability_zone                     = optional(string)
    publicly_accessible                   = optional(bool, false)
    promotion_tier                        = optional(number)
    apply_immediately                     = optional(bool)
    auto_minor_version_upgrade            = optional(bool)
    ca_cert_identifier                    = optional(string)
    monitoring_interval                   = optional(number)
    monitoring_role_arn                   = optional(string)
    performance_insights_enabled          = optional(bool)
    performance_insights_kms_key_id       = optional(string)
    performance_insights_retention_period = optional(number)
    preferred_backup_window               = optional(string)
    preferred_maintenance_window          = optional(string)
    tags                                  = optional(map(string), {})
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      delete = optional(string)
    }))
  }))
  default = {
    one = {}
  }

  validation {
    condition = alltrue([
      for key, instance in var.instances : (
        instance.identifier != null || can(regex("^[a-z0-9][a-z0-9-]*$", key))
      )
    ])
    error_message = "Instance map keys used to derive identifiers must contain lowercase letters, numbers, and hyphens, or the instance must provide an explicit identifier."
  }

  validation {
    condition = alltrue([
      for instance in values(var.instances) :
      instance.promotion_tier == null ? true : (floor(instance.promotion_tier) == instance.promotion_tier && instance.promotion_tier >= 0 && instance.promotion_tier <= 15)
    ])
    error_message = "Each instance promotion_tier must be a whole number from 0 to 15."
  }

  validation {
    condition = alltrue([
      for instance in values(var.instances) :
      instance.monitoring_interval == null ? true : contains([0, 1, 5, 10, 15, 30, 60], instance.monitoring_interval)
    ])
    error_message = "Each instance monitoring_interval must be 0, 1, 5, 10, 15, 30, or 60."
  }
}

variable "serverless_v1_scaling_configuration" {
  description = "Aurora Serverless v1 scaling settings. Requires engine_mode = serverless."
  type = object({
    auto_pause               = optional(bool, true)
    max_capacity             = optional(number)
    min_capacity             = optional(number)
    seconds_before_timeout   = optional(number)
    seconds_until_auto_pause = optional(number)
    timeout_action           = optional(string)
  })
  default = null

  validation {
    condition = var.serverless_v1_scaling_configuration == null ? true : (
      (var.serverless_v1_scaling_configuration.min_capacity == null ? true : contains([1, 2, 4, 8, 16, 32, 64, 128, 192, 256, 384], var.serverless_v1_scaling_configuration.min_capacity)) &&
      (var.serverless_v1_scaling_configuration.max_capacity == null ? true : contains([1, 2, 4, 8, 16, 32, 64, 128, 192, 256, 384], var.serverless_v1_scaling_configuration.max_capacity)) &&
      (var.serverless_v1_scaling_configuration.min_capacity == null || var.serverless_v1_scaling_configuration.max_capacity == null ? true : var.serverless_v1_scaling_configuration.max_capacity >= var.serverless_v1_scaling_configuration.min_capacity) &&
      (var.serverless_v1_scaling_configuration.seconds_until_auto_pause == null ? true : (var.serverless_v1_scaling_configuration.seconds_until_auto_pause >= 300 && var.serverless_v1_scaling_configuration.seconds_until_auto_pause <= 86400)) &&
      (var.serverless_v1_scaling_configuration.timeout_action == null ? true : contains(["ForceApplyCapacityChange", "RollbackCapacityChange"], var.serverless_v1_scaling_configuration.timeout_action))
    )
    error_message = "Serverless v1 capacities must be supported ACU values with max >= min, auto-pause must be 300-86400 seconds, and timeout_action must be a supported value."
  }
}

variable "serverless_v2_scaling_configuration" {
  description = "Aurora Serverless v2 capacity settings. Requires engine_mode = provisioned and db.serverless instances."
  type = object({
    min_capacity             = number
    max_capacity             = number
    seconds_until_auto_pause = optional(number)
  })
  default = null

  validation {
    condition = var.serverless_v2_scaling_configuration == null ? true : (
      var.serverless_v2_scaling_configuration.min_capacity >= 0 &&
      var.serverless_v2_scaling_configuration.max_capacity >= 0.5 &&
      var.serverless_v2_scaling_configuration.max_capacity <= 256 &&
      var.serverless_v2_scaling_configuration.max_capacity >= var.serverless_v2_scaling_configuration.min_capacity &&
      floor(var.serverless_v2_scaling_configuration.min_capacity * 2) == var.serverless_v2_scaling_configuration.min_capacity * 2 &&
      floor(var.serverless_v2_scaling_configuration.max_capacity * 2) == var.serverless_v2_scaling_configuration.max_capacity * 2 &&
      (var.serverless_v2_scaling_configuration.seconds_until_auto_pause == null ? true : (var.serverless_v2_scaling_configuration.seconds_until_auto_pause >= 300 && var.serverless_v2_scaling_configuration.seconds_until_auto_pause <= 86400))
    )
    error_message = "Serverless v2 capacities must use 0.5-ACU increments, max_capacity must be 0.5-256 and >= min_capacity, and auto-pause must be 300-86400 seconds."
  }
}

variable "shard_group" {
  description = "Aurora Limitless DB shard group. Required when cluster_scalability_type is limitless."
  type = object({
    identifier          = optional(string)
    max_acu             = number
    min_acu             = optional(number)
    compute_redundancy  = optional(number)
    publicly_accessible = optional(bool, false)
    tags                = optional(map(string), {})
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      delete = optional(string)
    }))
  })
  default = null

  validation {
    condition = var.shard_group == null ? true : (
      var.shard_group.max_acu >= 16 &&
      (var.shard_group.min_acu == null ? true : var.shard_group.min_acu >= 16) &&
      (var.shard_group.compute_redundancy == null ? true : contains([0, 1, 2], var.shard_group.compute_redundancy))
    )
    error_message = "shard_group max_acu and min_acu must be at least 16, and compute_redundancy must be 0, 1, or 2."
  }
}

variable "backup_retention_period" {
  description = "Days to retain automated backups."
  type        = number
  default     = 7

  validation {
    condition     = floor(var.backup_retention_period) == var.backup_retention_period && var.backup_retention_period >= 1 && var.backup_retention_period <= 35
    error_message = "backup_retention_period must be a whole number from 1 to 35."
  }
}

variable "preferred_backup_window" {
  description = "Daily UTC backup window."
  type        = string
  default     = null
}

variable "preferred_maintenance_window" {
  description = "Weekly UTC cluster maintenance window."
  type        = string
  default     = null
}

variable "apply_immediately" {
  description = "Whether cluster modifications are applied immediately instead of during the maintenance window."
  type        = bool
  default     = false
}

variable "allow_major_version_upgrade" {
  description = "Whether major database engine upgrades are allowed."
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Whether eligible minor engine upgrades are applied automatically."
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Whether deletion protection is enabled for the RDS/Aurora cluster."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Whether to skip a final snapshot on cluster deletion. The production default creates a final snapshot."
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "Unique final snapshot identifier. Required when skip_final_snapshot is false; change it before deleting a recreated cluster to avoid snapshot-name collisions."
  type        = string
  default     = null
}

variable "copy_tags_to_snapshot" {
  description = "Whether cluster tags are copied to snapshots."
  type        = bool
  default     = true
}

variable "delete_automated_backups" {
  description = "Whether automated backups are removed immediately after cluster deletion."
  type        = bool
  default     = false
}

variable "snapshot_identifier" {
  description = "Optional snapshot identifier or ARN from which to restore the cluster."
  type        = string
  default     = null
}

variable "restore_to_point_in_time" {
  description = "Optional point-in-time restore configuration. Conflicts with snapshot_identifier, replication_source_identifier, and s3_import."
  type = object({
    source_cluster_identifier  = optional(string)
    source_cluster_resource_id = optional(string)
    restore_type               = optional(string, "full-copy")
    restore_to_time            = optional(string)
    use_latest_restorable_time = optional(bool, false)
  })
  default = null

  validation {
    condition = var.restore_to_point_in_time == null ? true : (
      length([
        for source in [var.restore_to_point_in_time.source_cluster_identifier, var.restore_to_point_in_time.source_cluster_resource_id] : source
        if source != null
      ]) == 1 &&
      contains(["full-copy", "copy-on-write"], var.restore_to_point_in_time.restore_type) &&
      !(var.restore_to_point_in_time.restore_to_time != null && var.restore_to_point_in_time.use_latest_restorable_time)
    )
    error_message = "restore_to_point_in_time requires exactly one source identifier, a supported restore_type, and either restore_to_time or use_latest_restorable_time—not both."
  }
}

variable "s3_import" {
  description = "Optional Aurora MySQL import from an existing S3 backup."
  type = object({
    bucket_name           = string
    bucket_prefix         = optional(string)
    ingestion_role        = string
    source_engine         = optional(string, "mysql")
    source_engine_version = string
  })
  default = null
}

variable "replication_source_identifier" {
  description = "Optional source cluster ARN for an encrypted cross-Region read replica."
  type        = string
  default     = null
}

variable "source_region" {
  description = "Source Region for an encrypted cross-Region replica cluster."
  type        = string
  default     = null
}

variable "cluster_ca_certificate_identifier" {
  description = "Optional CA certificate identifier for the RDS Multi-AZ DB cluster server certificate."
  type        = string
  default     = null
}

variable "backtrack_window" {
  description = "Aurora MySQL backtrack window in seconds. Set zero to disable."
  type        = number
  default     = 0

  validation {
    condition     = floor(var.backtrack_window) == var.backtrack_window && var.backtrack_window >= 0 && var.backtrack_window <= 259200
    error_message = "backtrack_window must be a whole number from 0 to 259200."
  }
}

variable "iam_database_authentication_enabled" {
  description = "Whether IAM database authentication is enabled."
  type        = bool
  default     = true
}

variable "enable_http_endpoint" {
  description = "Whether the RDS Data API HTTP endpoint is enabled for a supported Aurora cluster."
  type        = bool
  default     = false
}

variable "enable_global_write_forwarding" {
  description = "Whether writes from a secondary global cluster are forwarded to the primary cluster."
  type        = bool
  default     = false
}

variable "enable_local_write_forwarding" {
  description = "Whether local write forwarding is enabled on an Aurora MySQL cluster."
  type        = bool
  default     = false
}

variable "network_type" {
  description = "Network stack type, such as IPV4 or DUAL."
  type        = string
  default     = "IPV4"

  validation {
    condition     = contains(["IPV4", "DUAL"], var.network_type)
    error_message = "network_type must be IPV4 or DUAL."
  }
}

variable "cluster_parameter_group" {
  description = "Optional DB cluster parameter group to create."
  type = object({
    name            = optional(string)
    use_name_prefix = optional(bool, true)
    description     = optional(string)
    family          = string
    parameters = optional(list(object({
      name         = string
      value        = string
      apply_method = optional(string, "immediate")
    })), [])
    tags = optional(map(string), {})
  })
  default = null
}

variable "db_cluster_parameter_group_name" {
  description = "Existing DB cluster parameter group name when cluster_parameter_group is null."
  type        = string
  default     = null
}

variable "db_parameter_group" {
  description = "Optional DB instance parameter group to create for Aurora instances."
  type = object({
    name            = optional(string)
    use_name_prefix = optional(bool, true)
    description     = optional(string)
    family          = string
    skip_destroy    = optional(bool, false)
    parameters = optional(list(object({
      name         = string
      value        = string
      apply_method = optional(string, "immediate")
    })), [])
    tags = optional(map(string), {})
  })
  default = null
}

variable "db_parameter_group_name" {
  description = "Existing DB parameter group name for Aurora instances when db_parameter_group is null."
  type        = string
  default     = null
}

variable "enabled_cloudwatch_logs_exports" {
  description = "Database logs exported to CloudWatch Logs, for example postgresql, audit, error, general, or slowquery according to engine support."
  type        = set(string)
  default     = []
}

variable "create_cloudwatch_log_groups" {
  description = "Whether to create CloudWatch log groups for enabled exports so retention and encryption can be controlled."
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Retention in days for module-created CloudWatch log groups."
  type        = number
  default     = 30

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.cloudwatch_log_group_retention_in_days)
    error_message = "cloudwatch_log_group_retention_in_days must be a value supported by CloudWatch Logs."
  }
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "Optional KMS key ARN for module-created CloudWatch log groups."
  type        = string
  default     = null
}

variable "cloudwatch_log_group_skip_destroy" {
  description = "Whether Terraform keeps module-created log groups when removed from configuration."
  type        = bool
  default     = false
}

variable "cloudwatch_log_group_class" {
  description = "Storage class for module-created CloudWatch log groups."
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "INFREQUENT_ACCESS", "DELIVERY"], var.cloudwatch_log_group_class)
    error_message = "cloudwatch_log_group_class must be STANDARD, INFREQUENT_ACCESS, or DELIVERY."
  }
}

variable "cloudwatch_log_group_deletion_protection" {
  description = "Whether deletion protection is enabled for module-created CloudWatch log groups."
  type        = bool
  default     = false
}

variable "monitoring_interval" {
  description = "Enhanced Monitoring interval in seconds for Aurora instances and RDS Multi-AZ DB clusters. Zero disables it."
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "monitoring_interval must be 0, 1, 5, 10, 15, 30, or 60."
  }
}

variable "create_monitoring_role" {
  description = "Whether to create the IAM role needed when Enhanced Monitoring is enabled and no role ARN is supplied."
  type        = bool
  default     = true
}

variable "monitoring_role_arn" {
  description = "Existing IAM role ARN for RDS Enhanced Monitoring."
  type        = string
  default     = null
}

variable "monitoring_role_name" {
  description = "Optional name for the module-created Enhanced Monitoring role. Defaults to <name>-rds-monitoring."
  type        = string
  default     = null
}

variable "monitoring_role_permissions_boundary" {
  description = "Optional permissions boundary ARN for the module-created Enhanced Monitoring role."
  type        = string
  default     = null
}

variable "performance_insights_enabled" {
  description = "Whether Performance Insights is enabled where supported."
  type        = bool
  default     = true
}

variable "performance_insights_kms_key_id" {
  description = "Optional KMS key ARN for Performance Insights."
  type        = string
  default     = null
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period in days."
  type        = number
  default     = 7

  validation {
    condition = (
      var.performance_insights_retention_period == 7 ||
      var.performance_insights_retention_period == 731 ||
      (var.performance_insights_retention_period >= 31 && var.performance_insights_retention_period <= 713 && var.performance_insights_retention_period % 31 == 0)
    )
    error_message = "performance_insights_retention_period must be 7, 731, or a multiple of 31 from 31 through 713."
  }
}

variable "database_insights_mode" {
  description = "CloudWatch Database Insights mode for the cluster: standard or advanced. Advanced mode requires Performance Insights and at least 465 days of retention."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "advanced"], var.database_insights_mode)
    error_message = "database_insights_mode must be standard or advanced."
  }
}

variable "autoscaling" {
  description = "Optional Aurora reader-replica target-tracking autoscaling configuration."
  type = object({
    enabled            = optional(bool, false)
    min_capacity       = optional(number, 1)
    max_capacity       = optional(number, 2)
    predefined_metric  = optional(string, "RDSReaderAverageCPUUtilization")
    target_value       = optional(number, 70)
    scale_in_cooldown  = optional(number, 300)
    scale_out_cooldown = optional(number, 300)
  })
  default = {}

  validation {
    condition = (
      var.autoscaling.min_capacity >= 0 &&
      var.autoscaling.max_capacity >= var.autoscaling.min_capacity &&
      contains(["RDSReaderAverageCPUUtilization", "RDSReaderAverageDatabaseConnections"], var.autoscaling.predefined_metric)
    )
    error_message = "autoscaling capacities must be non-negative with max >= min, and predefined_metric must be an RDS reader metric."
  }
}

variable "custom_endpoints" {
  description = "Aurora custom endpoints keyed by stable names. Member values are keys from the instances map."
  type = map(object({
    identifier       = optional(string)
    type             = optional(string, "READER")
    static_members   = optional(set(string), [])
    excluded_members = optional(set(string), [])
    tags             = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for endpoint in values(var.custom_endpoints) :
      contains(["READER", "ANY"], endpoint.type) &&
      !(length(endpoint.static_members) > 0 && length(endpoint.excluded_members) > 0) &&
      alltrue([for key in setunion(endpoint.static_members, endpoint.excluded_members) : contains(keys(var.instances), key)])
    ])
    error_message = "Custom endpoints must use READER or ANY, cannot combine static and excluded members, and must reference keys from instances."
  }
}

variable "cluster_role_associations" {
  description = "IAM roles to associate with the RDS/Aurora cluster, keyed by stable names."
  type = map(object({
    role_arn     = string
    feature_name = optional(string)
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
    }))
  }))
  default = {}
}

variable "managed_master_user_secret_rotation" {
  description = "Optional rotation schedule for the RDS-managed master-user secret."
  type = object({
    enabled                           = optional(bool, false)
    rotate_immediately                = optional(bool, false)
    automatically_after_days          = optional(number)
    duration                          = optional(string)
    schedule_expression               = optional(string)
    rotation_lambda_arn               = optional(string)
    external_secret_rotation_role_arn = optional(string)
    external_secret_rotation_metadata = optional(map(string), {})
  })
  default = {}

  validation {
    condition = var.managed_master_user_secret_rotation.automatically_after_days == null ? true : (
      floor(var.managed_master_user_secret_rotation.automatically_after_days) == var.managed_master_user_secret_rotation.automatically_after_days &&
      var.managed_master_user_secret_rotation.automatically_after_days >= 1 &&
      var.managed_master_user_secret_rotation.automatically_after_days <= 1000
    )
    error_message = "managed_master_user_secret_rotation.automatically_after_days must be a whole number from 1 to 1000."
  }
}

variable "cluster_timeouts" {
  description = "Optional create, update, and delete timeouts for the RDS/Aurora cluster."
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}

variable "dsql_clusters" {
  description = "Aurora DSQL clusters keyed by stable names. Use one module call per Region when provider aliases are required."
  type = map(object({
    region                      = optional(string)
    deletion_protection_enabled = optional(bool, true)
    force_destroy               = optional(bool, false)
    kms_encryption_key          = optional(string, "AWS_OWNED_KMS_KEY")
    witness_region              = optional(string)
    tags                        = optional(map(string), {})
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      delete = optional(string)
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for cluster in values(var.dsql_clusters) :
      cluster.witness_region == null || cluster.region == null || cluster.witness_region != cluster.region
    ])
    error_message = "A DSQL witness Region must differ from its cluster Region when both are specified."
  }
}

variable "dsql_peerings" {
  description = "Aurora DSQL peering declarations keyed by stable names. Multi-Region clusters need one declaration in each cluster Region."
  type = map(object({
    region         = optional(string)
    identifier     = string
    clusters       = set(string)
    witness_region = string
    create_timeout = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for peering in values(var.dsql_peerings) : length(peering.clusters) > 0])
    error_message = "Each DSQL peering must specify at least one peer cluster ARN."
  }

  validation {
    condition = alltrue([
      for peering in values(var.dsql_peerings) :
      peering.region == null || peering.witness_region != peering.region
    ])
    error_message = "A DSQL peering witness Region must differ from the cluster Region when region is specified."
  }
}

variable "tags" {
  description = "Tags applied to module-created resources."
  type        = map(string)
  default     = {}
}
