# RDS Multi-AZ DB cluster example

Creates a PostgreSQL RDS Multi-AZ DB cluster (not Aurora). AWS manages its writer and two readable standby instances, so the module does not create `aws_rds_cluster_instance` resources in this mode. Confirm the instance class, storage, IOPS ratio, and engine version are supported in the selected Region.

Provide exactly three subnets in three Availability Zones and a unique final snapshot identifier.
