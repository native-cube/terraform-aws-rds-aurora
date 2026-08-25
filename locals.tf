locals {
  create_rds          = var.create && var.create_rds_cluster
  is_aurora           = contains(["aurora-postgresql", "aurora-mysql"], var.engine)
  is_multi_az         = contains(["postgres", "mysql"], var.engine)
  is_serverless_v1    = local.is_aurora && var.engine_mode == "serverless"
  is_serverless_v2    = local.is_aurora && var.serverless_v2_scaling_configuration != null
  is_limitless        = local.is_aurora && var.cluster_scalability_type == "limitless"
  create_instances    = local.create_rds && local.is_aurora && !local.is_serverless_v1 && !local.is_limitless
  create_global       = var.create && var.create_global_cluster
  has_global_cluster  = local.create_global || var.global_cluster_identifier != null
  create_subnet_group = local.create_rds && var.create_db_subnet_group
  create_security_group = (
    local.create_rds && var.create_security_group
  )
  validate_network = local.create_rds && var.validate_network_configuration
  validate_engine = (
    local.create_rds && var.validate_engine_capabilities && var.engine_version != null
  )

  port = coalesce(var.port, contains(["aurora-postgresql", "postgres"], var.engine) ? 5432 : 3306)

  global_cluster_identifier = local.create_global ? aws_rds_global_cluster.main[0].id : var.global_cluster_identifier
  db_subnet_group_name      = local.create_subnet_group ? aws_db_subnet_group.main[0].name : var.db_subnet_group_name
  cluster_parameter_group_name = (
    var.cluster_parameter_group != null ? aws_rds_cluster_parameter_group.main[0].name : var.db_cluster_parameter_group_name
  )
  db_parameter_group_name = (
    var.db_parameter_group != null ? aws_db_parameter_group.main[0].name : var.db_parameter_group_name
  )

  instance_monitoring_requested = anytrue([
    for instance in values(var.instances) : coalesce(instance.monitoring_interval, var.monitoring_interval) > 0
  ])
  monitoring_requested = local.create_rds && (
    var.monitoring_interval > 0 ||
    (local.create_instances && local.instance_monitoring_requested)
  )
  create_monitoring_role = (
    local.monitoring_requested && var.create_monitoring_role && var.monitoring_role_arn == null
  )
  monitoring_role_arn = local.create_monitoring_role ? aws_iam_role.monitoring[0].arn : var.monitoring_role_arn

  use_primary_settings = (
    var.is_primary_cluster &&
    var.snapshot_identifier == null &&
    var.replication_source_identifier == null &&
    var.restore_to_point_in_time == null
  )
  use_managed_master_password = (
    local.use_primary_settings && var.manage_master_user_password && !local.has_global_cluster
  )
  use_caller_master_password = (
    local.use_primary_settings && !local.use_managed_master_password
  )
  create_secret_rotation = (
    local.create_rds &&
    var.managed_master_user_secret_rotation.enabled &&
    local.use_managed_master_password
  )

  orderable_instance_classes = local.is_multi_az && var.cluster_instance_class != null ? toset([var.cluster_instance_class]) : (
    local.create_instances ? toset([
      for instance in values(var.instances) :
      instance.instance_class != null ? instance.instance_class : (local.is_serverless_v2 ? "db.serverless" : var.cluster_instance_class)
      if instance.instance_class != null || local.is_serverless_v2 || var.cluster_instance_class != null
    ]) : toset([])
  )

  selected_subnet_vpc_ids = distinct([for subnet in values(data.aws_subnet.selected) : subnet.vpc_id])
  selected_subnet_azs     = distinct([for subnet in values(data.aws_subnet.selected) : subnet.availability_zone])
  selected_vpc_id = length(local.selected_subnet_vpc_ids) == 1 ? local.selected_subnet_vpc_ids[0] : (
    var.vpc_id
  )

  security_group_ids = setunion(
    var.security_group_ids,
    local.create_security_group ? toset([aws_security_group.main[0].id]) : toset([])
  )

  common_tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
      Module    = "terraform-aws-rds-aurora"
    }
  )
}
