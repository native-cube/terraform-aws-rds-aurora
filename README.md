# Terraform AWS RDS Aurora Module

Reusable Terraform module for production-oriented Amazon Aurora, RDS Multi-AZ DB clusters, and Aurora DSQL. It supports:

- Aurora PostgreSQL and Aurora MySQL provisioned clusters
- Aurora Serverless v1 and v2
- Aurora PostgreSQL Limitless with DB shard groups
- Aurora global databases across Regions
- PostgreSQL and MySQL RDS Multi-AZ DB clusters
- Single-Region and multi-Region Aurora DSQL clusters and peering
- Snapshot, point-in-time, and Aurora MySQL S3 restore paths
- Custom cluster endpoints, IAM role associations, managed-secret rotation, Database Insights, and reader autoscaling
- Module-managed subnet groups, security groups, parameter groups, log groups, and Enhanced Monitoring roles

The module does not create a VPC, subnets, KMS keys, Secrets Manager secrets, or provider configuration. Normal RDS/Aurora deployments are private, encrypted, deletion-protected, backed up for seven days, and use an RDS-managed master password by default.

## Deployment modes

| Deployment | Key settings | Compute resources |
| --- | --- | --- |
| Aurora provisioned | `engine = "aurora-postgresql"` or `"aurora-mysql"` | Entries in `instances` |
| Serverless v1 | `engine_mode = "serverless"` and `serverless_v1_scaling_configuration` | No instances |
| Serverless v2 | `engine_mode = "provisioned"` and `serverless_v2_scaling_configuration` | `db.serverless` instances |
| Aurora Limitless | `cluster_scalability_type = "limitless"` and `shard_group` | DB shard group, no normal instances |
| RDS Multi-AZ DB cluster | `engine = "postgres"` or `"mysql"`, plus `allocated_storage` | AWS-managed writer and two readable standbys |
| Aurora DSQL | `create_rds_cluster = false` and `dsql_clusters` | DSQL-managed distributed compute |

## Usage

```hcl
module "database" {
  source = "./terraform-aws-rds-aurora"

  name                   = "orders-production"
  engine                 = "aurora-postgresql"
  engine_version         = "17.5"
  database_name          = "orders"
  cluster_instance_class = "db.r7g.large"

  instances = {
    writer = {}
    reader = {
      promotion_tier = 1
    }
  }

  vpc_id = "vpc-0123456789abcdef0"
  subnet_ids = [
    "subnet-0123456789abcdef0",
    "subnet-0fedcba9876543210"
  ]

  ingress_rules = {
    application = {
      description                  = "Application database access"
      referenced_security_group_id = "sg-0123456789abcdef0"
    }
  }

  enabled_cloudwatch_logs_exports = ["postgresql"]
  monitoring_interval             = 60
  final_snapshot_identifier       = "orders-production-final-20260825"

  tags = {
    Environment = "production"
    Service     = "orders"
  }
}
```

## Security and operations

- No ingress or egress is created by default. Each rule accepts exactly one IPv4 CIDR, IPv6 CIDR, prefix list, or referenced security group. Omitted ingress ports default to the selected database port.
- RDS manages the master password in Secrets Manager by default. When caller-managed credentials are required, use the ephemeral `master_password_wo` input with `master_password_wo_version`; Terraform sends the write-only value without persisting it in plan or state.
- Storage encryption, deletion protection, automated-backup preservation, snapshot tag copying, and a final snapshot are enabled by default. A unique `final_snapshot_identifier` is required because an existing snapshot name cannot be reused.
- `apply_immediately = false` defers disruptive modifications to the maintenance window.
- Database Insights standard or advanced mode can be configured with consistent Performance Insights retention and Enhanced Monitoring settings. Advanced mode requires Performance Insights, at least 465 days of retention, and Enhanced Monitoring.
- CloudWatch log groups are created before log export is enabled so retention, KMS settings, log class, and deletion protection remain under Terraform control.
- Live capability checks validate the engine version, log exports, instance class, VPC, subnet Availability Zones, and existing security-group VPC before AWS starts creating the cluster. Set the validation switches to `false` only for offline plans or intentionally mocked tests.

## Global databases

Set `create_global_cluster = true` in the primary module call. Secondary calls use its `global_cluster_id`, set `is_primary_cluster = false`, and use a provider configured for the secondary Region. Secondary clusters omit database and master-user settings. When the selected global-cluster workflow requires caller-managed credentials, the example uses the ephemeral write-only password input. Global deployment support varies by engine version, Region, and instance class.

## Aurora Limitless

Limitless supports Aurora PostgreSQL only and uses an `aws_rds_shard_group` instead of `aws_rds_cluster_instance` resources. The module requires at least 16 ACUs and accepts compute redundancy of 0, 1, or 2. Capacity and redundant compute can create substantial cost; review the example values before applying.

## Restore and integrations

Choose only one cluster creation source: `snapshot_identifier`, `replication_source_identifier`, `restore_to_point_in_time`, or `s3_import`. S3 import is limited to provisioned Aurora MySQL. Restore and replica workflows omit settings that AWS inherits from the source.

`custom_endpoints` creates reader or any-type endpoints from stable `instances` map keys. `cluster_role_associations` attaches existing IAM roles to supported database features. `managed_master_user_secret_rotation` configures rotation for the RDS-managed secret after the cluster exposes it.

## Aurora DSQL

DSQL is independent from RDS clusters and VPC subnet groups. Set `create_rds_cluster = false` and declare `dsql_clusters`. A multi-Region deployment needs two cluster Regions, a third witness Region, and one `dsql_peerings` declaration executed through the provider for each participating cluster Region. See the DSQL example for the symmetric topology.

## Examples

- `examples/postgresql` - provisioned Aurora PostgreSQL writer and reader.
- `examples/mysql` - provisioned Aurora MySQL with I/O-Optimized storage and backtracking.
- `examples/serverless` - Aurora Serverless v1 and v2 side by side.
- `examples/multi-az` - PostgreSQL RDS Multi-AZ DB cluster, not Aurora.
- `examples/limitless` - Aurora PostgreSQL Limitless with a DB shard group.
- `examples/global-cluster` - cross-Region Aurora PostgreSQL global database.
- `examples/dsql` - single-Region and symmetric multi-Region Aurora DSQL deployments.

Examples require existing networking where applicable and intentionally leave engine versions as required variables so upgrades and Region compatibility are reviewed rather than silently assumed.

## Development

Run `make check` to verify formatting, generated documentation, initialization, native mocked plans, and every example. Run `make lint` and `make security` for TFLint and Trivy checks. Run `make docs` after changing resources, inputs, outputs, or version constraints.

The GitHub Actions workflow applies the same checks on pull requests and `main`, then tests the minimum supported Terraform/provider combination and the latest Terraform release with the newest AWS provider in the supported major line.

## Module documentation

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.4 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.61.0, < 7.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.61.0, < 7.0.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_appautoscaling_policy.readers](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy) | resource |
| [aws_appautoscaling_target.readers](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target) | resource |
| [aws_cloudwatch_log_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_db_parameter_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group) | resource |
| [aws_db_subnet_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_dsql_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dsql_cluster) | resource |
| [aws_dsql_cluster_peering.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dsql_cluster_peering) | resource |
| [aws_iam_role.monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_rds_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster) | resource |
| [aws_rds_cluster_endpoint.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_endpoint) | resource |
| [aws_rds_cluster_instance.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_instance) | resource |
| [aws_rds_cluster_parameter_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_parameter_group) | resource |
| [aws_rds_cluster_role_association.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_role_association) | resource |
| [aws_rds_global_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_global_cluster) | resource |
| [aws_rds_shard_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_shard_group) | resource |
| [aws_secretsmanager_secret_rotation.master](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_rotation) | resource |
| [aws_security_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allocated_storage"></a> [allocated\_storage](#input\_allocated\_storage) | Storage in GiB for an RDS Multi-AZ DB cluster. Setting this selects Multi-AZ mode and requires engine postgres or mysql. | `number` | `null` | no |
| <a name="input_allow_major_version_upgrade"></a> [allow\_major\_version\_upgrade](#input\_allow\_major\_version\_upgrade) | Whether major database engine upgrades are allowed. | `bool` | `false` | no |
| <a name="input_apply_immediately"></a> [apply\_immediately](#input\_apply\_immediately) | Whether cluster modifications are applied immediately instead of during the maintenance window. | `bool` | `false` | no |
| <a name="input_auto_minor_version_upgrade"></a> [auto\_minor\_version\_upgrade](#input\_auto\_minor\_version\_upgrade) | Whether eligible minor engine upgrades are applied automatically. | `bool` | `true` | no |
| <a name="input_autoscaling"></a> [autoscaling](#input\_autoscaling) | Optional Aurora reader-replica target-tracking autoscaling configuration. | <pre>object({<br/>    enabled            = optional(bool, false)<br/>    min_capacity       = optional(number, 1)<br/>    max_capacity       = optional(number, 2)<br/>    predefined_metric  = optional(string, "RDSReaderAverageCPUUtilization")<br/>    target_value       = optional(number, 70)<br/>    scale_in_cooldown  = optional(number, 300)<br/>    scale_out_cooldown = optional(number, 300)<br/>  })</pre> | `{}` | no |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | Optional Availability Zones for the RDS/Aurora cluster. | `list(string)` | `null` | no |
| <a name="input_backtrack_window"></a> [backtrack\_window](#input\_backtrack\_window) | Aurora MySQL backtrack window in seconds. Set zero to disable. | `number` | `0` | no |
| <a name="input_backup_retention_period"></a> [backup\_retention\_period](#input\_backup\_retention\_period) | Days to retain automated backups. | `number` | `7` | no |
| <a name="input_cloudwatch_log_group_class"></a> [cloudwatch\_log\_group\_class](#input\_cloudwatch\_log\_group\_class) | Storage class for module-created CloudWatch log groups. | `string` | `"STANDARD"` | no |
| <a name="input_cloudwatch_log_group_deletion_protection"></a> [cloudwatch\_log\_group\_deletion\_protection](#input\_cloudwatch\_log\_group\_deletion\_protection) | Whether deletion protection is enabled for module-created CloudWatch log groups. | `bool` | `false` | no |
| <a name="input_cloudwatch_log_group_kms_key_id"></a> [cloudwatch\_log\_group\_kms\_key\_id](#input\_cloudwatch\_log\_group\_kms\_key\_id) | Optional KMS key ARN for module-created CloudWatch log groups. | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_retention_in_days"></a> [cloudwatch\_log\_group\_retention\_in\_days](#input\_cloudwatch\_log\_group\_retention\_in\_days) | Retention in days for module-created CloudWatch log groups. | `number` | `30` | no |
| <a name="input_cloudwatch_log_group_skip_destroy"></a> [cloudwatch\_log\_group\_skip\_destroy](#input\_cloudwatch\_log\_group\_skip\_destroy) | Whether Terraform keeps module-created log groups when removed from configuration. | `bool` | `false` | no |
| <a name="input_cluster_ca_certificate_identifier"></a> [cluster\_ca\_certificate\_identifier](#input\_cluster\_ca\_certificate\_identifier) | Optional CA certificate identifier for the RDS Multi-AZ DB cluster server certificate. | `string` | `null` | no |
| <a name="input_cluster_instance_class"></a> [cluster\_instance\_class](#input\_cluster\_instance\_class) | Default Aurora instance class, or the managed instance class for an RDS Multi-AZ DB cluster. Serverless v2 defaults this to db.serverless. | `string` | `null` | no |
| <a name="input_cluster_parameter_group"></a> [cluster\_parameter\_group](#input\_cluster\_parameter\_group) | Optional DB cluster parameter group to create. | <pre>object({<br/>    name            = optional(string)<br/>    use_name_prefix = optional(bool, true)<br/>    description     = optional(string)<br/>    family          = string<br/>    parameters = optional(list(object({<br/>      name         = string<br/>      value        = string<br/>      apply_method = optional(string, "immediate")<br/>    })), [])<br/>    tags = optional(map(string), {})<br/>  })</pre> | `null` | no |
| <a name="input_cluster_role_associations"></a> [cluster\_role\_associations](#input\_cluster\_role\_associations) | IAM roles to associate with the RDS/Aurora cluster, keyed by stable names. | <pre>map(object({<br/>    role_arn     = string<br/>    feature_name = optional(string)<br/>    timeouts = optional(object({<br/>      create = optional(string)<br/>      delete = optional(string)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_cluster_scalability_type"></a> [cluster\_scalability\_type](#input\_cluster\_scalability\_type) | Aurora cluster scalability type. Set to limitless for Aurora PostgreSQL Limitless. | `string` | `"standard"` | no |
| <a name="input_cluster_timeouts"></a> [cluster\_timeouts](#input\_cluster\_timeouts) | Optional create, update, and delete timeouts for the RDS/Aurora cluster. | <pre>object({<br/>    create = optional(string)<br/>    update = optional(string)<br/>    delete = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_copy_tags_to_snapshot"></a> [copy\_tags\_to\_snapshot](#input\_copy\_tags\_to\_snapshot) | Whether cluster tags are copied to snapshots. | `bool` | `true` | no |
| <a name="input_create"></a> [create](#input\_create) | Whether to create module-managed resources. | `bool` | `true` | no |
| <a name="input_create_cloudwatch_log_groups"></a> [create\_cloudwatch\_log\_groups](#input\_create\_cloudwatch\_log\_groups) | Whether to create CloudWatch log groups for enabled exports so retention and encryption can be controlled. | `bool` | `true` | no |
| <a name="input_create_db_subnet_group"></a> [create\_db\_subnet\_group](#input\_create\_db\_subnet\_group) | Whether to create a DB subnet group from subnet\_ids. | `bool` | `true` | no |
| <a name="input_create_global_cluster"></a> [create\_global\_cluster](#input\_create\_global\_cluster) | Whether to create an RDS global cluster container and attach this cluster to it. | `bool` | `false` | no |
| <a name="input_create_monitoring_role"></a> [create\_monitoring\_role](#input\_create\_monitoring\_role) | Whether to create the IAM role needed when Enhanced Monitoring is enabled and no role ARN is supplied. | `bool` | `true` | no |
| <a name="input_create_rds_cluster"></a> [create\_rds\_cluster](#input\_create\_rds\_cluster) | Whether to create an RDS/Aurora cluster. Set false for DSQL-only or global-container-only module calls. | `bool` | `true` | no |
| <a name="input_create_security_group"></a> [create\_security\_group](#input\_create\_security\_group) | Whether to create a security group for the RDS/Aurora cluster. | `bool` | `true` | no |
| <a name="input_custom_endpoints"></a> [custom\_endpoints](#input\_custom\_endpoints) | Aurora custom endpoints keyed by stable names. Member values are keys from the instances map. | <pre>map(object({<br/>    identifier       = optional(string)<br/>    type             = optional(string, "READER")<br/>    static_members   = optional(set(string), [])<br/>    excluded_members = optional(set(string), [])<br/>    tags             = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_database_insights_mode"></a> [database\_insights\_mode](#input\_database\_insights\_mode) | CloudWatch Database Insights mode for the cluster: standard or advanced. Advanced mode requires Performance Insights and at least 465 days of retention. | `string` | `"standard"` | no |
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | Initial database name for a primary cluster. | `string` | `null` | no |
| <a name="input_db_cluster_parameter_group_name"></a> [db\_cluster\_parameter\_group\_name](#input\_db\_cluster\_parameter\_group\_name) | Existing DB cluster parameter group name when cluster\_parameter\_group is null. | `string` | `null` | no |
| <a name="input_db_parameter_group"></a> [db\_parameter\_group](#input\_db\_parameter\_group) | Optional DB instance parameter group to create for Aurora instances. | <pre>object({<br/>    name            = optional(string)<br/>    use_name_prefix = optional(bool, true)<br/>    description     = optional(string)<br/>    family          = string<br/>    skip_destroy    = optional(bool, false)<br/>    parameters = optional(list(object({<br/>      name         = string<br/>      value        = string<br/>      apply_method = optional(string, "immediate")<br/>    })), [])<br/>    tags = optional(map(string), {})<br/>  })</pre> | `null` | no |
| <a name="input_db_parameter_group_name"></a> [db\_parameter\_group\_name](#input\_db\_parameter\_group\_name) | Existing DB parameter group name for Aurora instances when db\_parameter\_group is null. | `string` | `null` | no |
| <a name="input_db_subnet_group_description"></a> [db\_subnet\_group\_description](#input\_db\_subnet\_group\_description) | Description for the module-created DB subnet group. | `string` | `"Managed by Terraform"` | no |
| <a name="input_db_subnet_group_name"></a> [db\_subnet\_group\_name](#input\_db\_subnet\_group\_name) | Existing DB subnet group name when create\_db\_subnet\_group is false, or an override for the created group. | `string` | `null` | no |
| <a name="input_delete_automated_backups"></a> [delete\_automated\_backups](#input\_delete\_automated\_backups) | Whether automated backups are removed immediately after cluster deletion. | `bool` | `false` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Whether deletion protection is enabled for the RDS/Aurora cluster. | `bool` | `true` | no |
| <a name="input_dsql_clusters"></a> [dsql\_clusters](#input\_dsql\_clusters) | Aurora DSQL clusters keyed by stable names. Use one module call per Region when provider aliases are required. | <pre>map(object({<br/>    region                      = optional(string)<br/>    deletion_protection_enabled = optional(bool, true)<br/>    force_destroy               = optional(bool, false)<br/>    kms_encryption_key          = optional(string, "AWS_OWNED_KMS_KEY")<br/>    witness_region              = optional(string)<br/>    tags                        = optional(map(string), {})<br/>    timeouts = optional(object({<br/>      create = optional(string)<br/>      update = optional(string)<br/>      delete = optional(string)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_dsql_peerings"></a> [dsql\_peerings](#input\_dsql\_peerings) | Aurora DSQL peering declarations keyed by stable names. Multi-Region clusters need one declaration in each cluster Region. | <pre>map(object({<br/>    region         = optional(string)<br/>    identifier     = string<br/>    clusters       = set(string)<br/>    witness_region = string<br/>    create_timeout = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_egress_rules"></a> [egress\_rules](#input\_egress\_rules) | Egress rules for the module-created security group, keyed by a stable name. No outbound access is allowed by default. | <pre>map(object({<br/>    description                  = optional(string)<br/>    from_port                    = optional(number)<br/>    to_port                      = optional(number)<br/>    ip_protocol                  = optional(string, "-1")<br/>    cidr_ipv4                    = optional(string)<br/>    cidr_ipv6                    = optional(string)<br/>    prefix_list_id               = optional(string)<br/>    referenced_security_group_id = optional(string)<br/>    tags                         = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_enable_global_write_forwarding"></a> [enable\_global\_write\_forwarding](#input\_enable\_global\_write\_forwarding) | Whether writes from a secondary global cluster are forwarded to the primary cluster. | `bool` | `false` | no |
| <a name="input_enable_http_endpoint"></a> [enable\_http\_endpoint](#input\_enable\_http\_endpoint) | Whether the RDS Data API HTTP endpoint is enabled for a supported Aurora cluster. | `bool` | `false` | no |
| <a name="input_enable_local_write_forwarding"></a> [enable\_local\_write\_forwarding](#input\_enable\_local\_write\_forwarding) | Whether local write forwarding is enabled on an Aurora MySQL cluster. | `bool` | `false` | no |
| <a name="input_enabled_cloudwatch_logs_exports"></a> [enabled\_cloudwatch\_logs\_exports](#input\_enabled\_cloudwatch\_logs\_exports) | Database logs exported to CloudWatch Logs, for example postgresql, audit, error, general, or slowquery according to engine support. | `set(string)` | `[]` | no |
| <a name="input_engine"></a> [engine](#input\_engine) | Database engine. Aurora uses aurora-postgresql or aurora-mysql; postgres and mysql create RDS Multi-AZ DB clusters. | `string` | `"aurora-postgresql"` | no |
| <a name="input_engine_lifecycle_support"></a> [engine\_lifecycle\_support](#input\_engine\_lifecycle\_support) | Optional RDS Extended Support lifecycle setting. | `string` | `null` | no |
| <a name="input_engine_mode"></a> [engine\_mode](#input\_engine\_mode) | Aurora engine mode. Use provisioned for provisioned clusters and Serverless v2, or serverless for Serverless v1. | `string` | `"provisioned"` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | Database engine version. Specify explicitly in production so upgrades are deliberate. | `string` | `null` | no |
| <a name="input_final_snapshot_identifier"></a> [final\_snapshot\_identifier](#input\_final\_snapshot\_identifier) | Unique final snapshot identifier. Required when skip\_final\_snapshot is false; change it before deleting a recreated cluster to avoid snapshot-name collisions. | `string` | `null` | no |
| <a name="input_global_cluster_deletion_protection"></a> [global\_cluster\_deletion\_protection](#input\_global\_cluster\_deletion\_protection) | Whether deletion protection is enabled for a module-created global cluster. | `bool` | `true` | no |
| <a name="input_global_cluster_force_destroy"></a> [global\_cluster\_force\_destroy](#input\_global\_cluster\_force\_destroy) | Whether to remove members from a module-created global cluster when it is destroyed. | `bool` | `false` | no |
| <a name="input_global_cluster_identifier"></a> [global\_cluster\_identifier](#input\_global\_cluster\_identifier) | Existing global cluster identifier to join, or identifier for the global cluster created by this module. Defaults to <name>-global when creating one. | `string` | `null` | no |
| <a name="input_global_cluster_source_db_cluster_identifier"></a> [global\_cluster\_source\_db\_cluster\_identifier](#input\_global\_cluster\_source\_db\_cluster\_identifier) | Optional source DB cluster ARN or identifier used to create a global cluster from an existing cluster. | `string` | `null` | no |
| <a name="input_global_cluster_timeouts"></a> [global\_cluster\_timeouts](#input\_global\_cluster\_timeouts) | Optional create, update, and delete timeouts for the global cluster. | <pre>object({<br/>    create = optional(string)<br/>    update = optional(string)<br/>    delete = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_iam_database_authentication_enabled"></a> [iam\_database\_authentication\_enabled](#input\_iam\_database\_authentication\_enabled) | Whether IAM database authentication is enabled. | `bool` | `true` | no |
| <a name="input_ingress_rules"></a> [ingress\_rules](#input\_ingress\_rules) | Ingress rules for the module-created security group, keyed by a stable name. The database port is used when ports are omitted. | <pre>map(object({<br/>    description                  = optional(string)<br/>    from_port                    = optional(number)<br/>    to_port                      = optional(number)<br/>    ip_protocol                  = optional(string, "tcp")<br/>    cidr_ipv4                    = optional(string)<br/>    cidr_ipv6                    = optional(string)<br/>    prefix_list_id               = optional(string)<br/>    referenced_security_group_id = optional(string)<br/>    tags                         = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_instances"></a> [instances](#input\_instances) | Aurora cluster instances keyed by stable names. Ignored for Serverless v1, RDS Multi-AZ DB clusters, and Limitless. | <pre>map(object({<br/>    identifier                            = optional(string)<br/>    instance_class                        = optional(string)<br/>    availability_zone                     = optional(string)<br/>    publicly_accessible                   = optional(bool, false)<br/>    promotion_tier                        = optional(number)<br/>    apply_immediately                     = optional(bool)<br/>    auto_minor_version_upgrade            = optional(bool)<br/>    ca_cert_identifier                    = optional(string)<br/>    monitoring_interval                   = optional(number)<br/>    monitoring_role_arn                   = optional(string)<br/>    performance_insights_enabled          = optional(bool)<br/>    performance_insights_kms_key_id       = optional(string)<br/>    performance_insights_retention_period = optional(number)<br/>    preferred_backup_window               = optional(string)<br/>    preferred_maintenance_window          = optional(string)<br/>    tags                                  = optional(map(string), {})<br/>    timeouts = optional(object({<br/>      create = optional(string)<br/>      update = optional(string)<br/>      delete = optional(string)<br/>    }))<br/>  }))</pre> | <pre>{<br/>  "one": {}<br/>}</pre> | no |
| <a name="input_iops"></a> [iops](#input\_iops) | Provisioned IOPS for an RDS Multi-AZ DB cluster when required by storage\_type. | `number` | `null` | no |
| <a name="input_is_primary_cluster"></a> [is\_primary\_cluster](#input\_is\_primary\_cluster) | Whether this is a primary cluster. Secondary global clusters omit database and master-user settings. | `bool` | `true` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | Optional KMS key ARN for cluster storage encryption. | `string` | `null` | no |
| <a name="input_manage_master_user_password"></a> [manage\_master\_user\_password](#input\_manage\_master\_user\_password) | Whether RDS manages the master password in Secrets Manager. This is the secure default. | `bool` | `true` | no |
| <a name="input_managed_master_user_secret_rotation"></a> [managed\_master\_user\_secret\_rotation](#input\_managed\_master\_user\_secret\_rotation) | Optional rotation schedule for the RDS-managed master-user secret. | <pre>object({<br/>    enabled                           = optional(bool, false)<br/>    rotate_immediately                = optional(bool, false)<br/>    automatically_after_days          = optional(number)<br/>    duration                          = optional(string)<br/>    schedule_expression               = optional(string)<br/>    rotation_lambda_arn               = optional(string)<br/>    external_secret_rotation_role_arn = optional(string)<br/>    external_secret_rotation_metadata = optional(map(string), {})<br/>  })</pre> | `{}` | no |
| <a name="input_master_password_wo"></a> [master\_password\_wo](#input\_master\_password\_wo) | Optional write-only caller-managed master password. Terraform does not persist this ephemeral value in plans or state. | `string` | `null` | no |
| <a name="input_master_password_wo_version"></a> [master\_password\_wo\_version](#input\_master\_password\_wo\_version) | Version used to trigger updates to master\_password\_wo. Increment this value whenever the write-only password changes. | `number` | `null` | no |
| <a name="input_master_user_secret_kms_key_id"></a> [master\_user\_secret\_kms\_key\_id](#input\_master\_user\_secret\_kms\_key\_id) | Optional KMS key ARN or ID used to encrypt the RDS-managed master-user secret. | `string` | `null` | no |
| <a name="input_master_username"></a> [master\_username](#input\_master\_username) | Master username for a primary cluster. | `string` | `"dbadmin"` | no |
| <a name="input_monitoring_interval"></a> [monitoring\_interval](#input\_monitoring\_interval) | Enhanced Monitoring interval in seconds for Aurora instances and RDS Multi-AZ DB clusters. Zero disables it. | `number` | `0` | no |
| <a name="input_monitoring_role_arn"></a> [monitoring\_role\_arn](#input\_monitoring\_role\_arn) | Existing IAM role ARN for RDS Enhanced Monitoring. | `string` | `null` | no |
| <a name="input_monitoring_role_name"></a> [monitoring\_role\_name](#input\_monitoring\_role\_name) | Optional name for the module-created Enhanced Monitoring role. Defaults to <name>-rds-monitoring. | `string` | `null` | no |
| <a name="input_monitoring_role_permissions_boundary"></a> [monitoring\_role\_permissions\_boundary](#input\_monitoring\_role\_permissions\_boundary) | Optional permissions boundary ARN for the module-created Enhanced Monitoring role. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name used for the RDS cluster and as a prefix for module-created resources. | `string` | n/a | yes |
| <a name="input_network_type"></a> [network\_type](#input\_network\_type) | Network stack type, such as IPV4 or DUAL. | `string` | `"IPV4"` | no |
| <a name="input_performance_insights_enabled"></a> [performance\_insights\_enabled](#input\_performance\_insights\_enabled) | Whether Performance Insights is enabled where supported. | `bool` | `true` | no |
| <a name="input_performance_insights_kms_key_id"></a> [performance\_insights\_kms\_key\_id](#input\_performance\_insights\_kms\_key\_id) | Optional KMS key ARN for Performance Insights. | `string` | `null` | no |
| <a name="input_performance_insights_retention_period"></a> [performance\_insights\_retention\_period](#input\_performance\_insights\_retention\_period) | Performance Insights retention period in days. | `number` | `7` | no |
| <a name="input_port"></a> [port](#input\_port) | Database port. Defaults to 5432 for PostgreSQL engines and 3306 for MySQL engines. | `number` | `null` | no |
| <a name="input_preferred_backup_window"></a> [preferred\_backup\_window](#input\_preferred\_backup\_window) | Daily UTC backup window. | `string` | `null` | no |
| <a name="input_preferred_maintenance_window"></a> [preferred\_maintenance\_window](#input\_preferred\_maintenance\_window) | Weekly UTC cluster maintenance window. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | Optional AWS Region for resources. When null, the AWS provider Region is used. | `string` | `null` | no |
| <a name="input_replication_source_identifier"></a> [replication\_source\_identifier](#input\_replication\_source\_identifier) | Optional source cluster ARN for an encrypted cross-Region read replica. | `string` | `null` | no |
| <a name="input_restore_to_point_in_time"></a> [restore\_to\_point\_in\_time](#input\_restore\_to\_point\_in\_time) | Optional point-in-time restore configuration. Conflicts with snapshot\_identifier, replication\_source\_identifier, and s3\_import. | <pre>object({<br/>    source_cluster_identifier  = optional(string)<br/>    source_cluster_resource_id = optional(string)<br/>    restore_type               = optional(string, "full-copy")<br/>    restore_to_time            = optional(string)<br/>    use_latest_restorable_time = optional(bool, false)<br/>  })</pre> | `null` | no |
| <a name="input_revoke_rules_on_delete"></a> [revoke\_rules\_on\_delete](#input\_revoke\_rules\_on\_delete) | Whether to revoke all security-group rules before deleting the module-created group. | `bool` | `true` | no |
| <a name="input_s3_import"></a> [s3\_import](#input\_s3\_import) | Optional Aurora MySQL import from an existing S3 backup. | <pre>object({<br/>    bucket_name           = string<br/>    bucket_prefix         = optional(string)<br/>    ingestion_role        = string<br/>    source_engine         = optional(string, "mysql")<br/>    source_engine_version = string<br/>  })</pre> | `null` | no |
| <a name="input_security_group_description"></a> [security\_group\_description](#input\_security\_group\_description) | Description for the module-created security group. | `string` | `"Controls access to the database cluster"` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | Existing security group IDs associated with the RDS/Aurora cluster in addition to the optional created group. | `set(string)` | `[]` | no |
| <a name="input_security_group_name"></a> [security\_group\_name](#input\_security\_group\_name) | Optional name for the module-created security group. Defaults to <name>-database. | `string` | `null` | no |
| <a name="input_serverless_v1_scaling_configuration"></a> [serverless\_v1\_scaling\_configuration](#input\_serverless\_v1\_scaling\_configuration) | Aurora Serverless v1 scaling settings. Requires engine\_mode = serverless. | <pre>object({<br/>    auto_pause               = optional(bool, true)<br/>    max_capacity             = optional(number)<br/>    min_capacity             = optional(number)<br/>    seconds_before_timeout   = optional(number)<br/>    seconds_until_auto_pause = optional(number)<br/>    timeout_action           = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_serverless_v2_scaling_configuration"></a> [serverless\_v2\_scaling\_configuration](#input\_serverless\_v2\_scaling\_configuration) | Aurora Serverless v2 capacity settings. Requires engine\_mode = provisioned and db.serverless instances. | <pre>object({<br/>    min_capacity             = number<br/>    max_capacity             = number<br/>    seconds_until_auto_pause = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_shard_group"></a> [shard\_group](#input\_shard\_group) | Aurora Limitless DB shard group. Required when cluster\_scalability\_type is limitless. | <pre>object({<br/>    identifier          = optional(string)<br/>    max_acu             = number<br/>    min_acu             = optional(number)<br/>    compute_redundancy  = optional(number)<br/>    publicly_accessible = optional(bool, false)<br/>    tags                = optional(map(string), {})<br/>    timeouts = optional(object({<br/>      create = optional(string)<br/>      update = optional(string)<br/>      delete = optional(string)<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_skip_final_snapshot"></a> [skip\_final\_snapshot](#input\_skip\_final\_snapshot) | Whether to skip a final snapshot on cluster deletion. The production default creates a final snapshot. | `bool` | `false` | no |
| <a name="input_snapshot_identifier"></a> [snapshot\_identifier](#input\_snapshot\_identifier) | Optional snapshot identifier or ARN from which to restore the cluster. | `string` | `null` | no |
| <a name="input_source_region"></a> [source\_region](#input\_source\_region) | Source Region for an encrypted cross-Region replica cluster. | `string` | `null` | no |
| <a name="input_storage_encrypted"></a> [storage\_encrypted](#input\_storage\_encrypted) | Whether cluster storage is encrypted. | `bool` | `true` | no |
| <a name="input_storage_type"></a> [storage\_type](#input\_storage\_type) | Cluster storage type. Aurora supports aurora and aurora-iopt1; RDS Multi-AZ DB clusters commonly use io1, io2, or gp3 according to engine support. | `string` | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Existing subnet IDs used by a module-created DB subnet group. Supply at least two subnets in different Availability Zones. | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to module-created resources. | `map(string)` | `{}` | no |
| <a name="input_validate_engine_capabilities"></a> [validate\_engine\_capabilities](#input\_validate\_engine\_capabilities) | Whether to query the selected RDS engine version and regional instance offerings to validate requested capabilities during planning. | `bool` | `true` | no |
| <a name="input_validate_network_configuration"></a> [validate\_network\_configuration](#input\_validate\_network\_configuration) | Whether to query subnet and security-group metadata and reject cross-VPC or invalid Availability Zone topology during planning. | `bool` | `true` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID for the module-created database security group. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | RDS/Aurora cluster ARN, or null when cluster creation is disabled. |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Writer endpoint for the RDS/Aurora cluster, or null when cluster creation is disabled. |
| <a name="output_cluster_engine_version_actual"></a> [cluster\_engine\_version\_actual](#output\_cluster\_engine\_version\_actual) | Actual engine version reported for the RDS/Aurora cluster. |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | RDS/Aurora cluster identifier, or null when cluster creation is disabled. |
| <a name="output_cluster_instances"></a> [cluster\_instances](#output\_cluster\_instances) | Aurora cluster instances keyed by the caller-controlled instances map keys. |
| <a name="output_cluster_parameter_group_id"></a> [cluster\_parameter\_group\_id](#output\_cluster\_parameter\_group\_id) | ID of the module-created cluster parameter group, or null when not created. |
| <a name="output_cluster_port"></a> [cluster\_port](#output\_cluster\_port) | Database port for the RDS/Aurora cluster. |
| <a name="output_cluster_reader_endpoint"></a> [cluster\_reader\_endpoint](#output\_cluster\_reader\_endpoint) | Reader endpoint for the Aurora cluster, or null when unavailable. |
| <a name="output_cluster_resource_id"></a> [cluster\_resource\_id](#output\_cluster\_resource\_id) | RDS/Aurora cluster resource ID, or null when cluster creation is disabled. |
| <a name="output_cluster_role_association_ids"></a> [cluster\_role\_association\_ids](#output\_cluster\_role\_association\_ids) | RDS cluster IAM role-association IDs keyed by caller-controlled keys. |
| <a name="output_custom_endpoints"></a> [custom\_endpoints](#output\_custom\_endpoints) | Aurora custom endpoints keyed by the caller-controlled custom\_endpoints map keys. |
| <a name="output_db_parameter_group_id"></a> [db\_parameter\_group\_id](#output\_db\_parameter\_group\_id) | ID of the module-created DB instance parameter group, or null when not created. |
| <a name="output_db_subnet_group_name"></a> [db\_subnet\_group\_name](#output\_db\_subnet\_group\_name) | Created or external DB subnet group name used by the RDS/Aurora cluster. |
| <a name="output_dsql_clusters"></a> [dsql\_clusters](#output\_dsql\_clusters) | Aurora DSQL clusters keyed by the caller-controlled dsql\_clusters map keys. |
| <a name="output_dsql_peering_ids"></a> [dsql\_peering\_ids](#output\_dsql\_peering\_ids) | Aurora DSQL cluster identifiers whose peering configuration is managed by this module. |
| <a name="output_global_cluster_arn"></a> [global\_cluster\_arn](#output\_global\_cluster\_arn) | ARN of the module-created global cluster, or null when creation is disabled. |
| <a name="output_global_cluster_id"></a> [global\_cluster\_id](#output\_global\_cluster\_id) | Created or external global cluster identifier used by this cluster. |
| <a name="output_global_cluster_members"></a> [global\_cluster\_members](#output\_global\_cluster\_members) | Members reported by the module-created global cluster. |
| <a name="output_managed_master_user_secret_rotation_id"></a> [managed\_master\_user\_secret\_rotation\_id](#output\_managed\_master\_user\_secret\_rotation\_id) | Secrets Manager rotation resource ID for the RDS-managed master-user secret, or null when disabled. |
| <a name="output_master_user_secret"></a> [master\_user\_secret](#output\_master\_user\_secret) | RDS-managed master-user secret metadata. The secret value is not exposed. |
| <a name="output_monitoring_role_arn"></a> [monitoring\_role\_arn](#output\_monitoring\_role\_arn) | Created or external Enhanced Monitoring role ARN used by the cluster and instances. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the module-created security group, or null when creation is disabled. |
| <a name="output_security_group_ids"></a> [security\_group\_ids](#output\_security\_group\_ids) | All security group IDs associated with the RDS/Aurora cluster. |
| <a name="output_shard_group"></a> [shard\_group](#output\_shard\_group) | Aurora Limitless shard-group connection and identity details, or null when Limitless is disabled. |
<!-- END_TF_DOCS -->
