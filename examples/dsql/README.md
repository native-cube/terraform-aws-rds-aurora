# Aurora DSQL example

Creates one single-Region DSQL cluster and a two-Region DSQL cluster with a third witness Region. DSQL generates cluster identifiers and does not use RDS subnet groups, RDS instances, or database security groups.

Multi-Region setup is intentionally split into cluster and peering module calls. DSQL requires symmetric peering in both participating Regions, so each peering call uses the matching provider alias and references the other cluster ARN. Deletion protection is enabled and `force_destroy` is disabled by default.
