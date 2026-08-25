# Aurora global cluster example

Creates an Aurora PostgreSQL global database with a primary cluster in one Region and a secondary cluster in another. The global primary uses a caller-supplied write-only password because the RDS API does not accept managed-master-password configuration while attaching a new cluster to a global cluster. Terraform passes the ephemeral value to the provider without persisting it in plans or state; increment its version input whenever the password changes.

The example uses provider aliases because each Region also has distinct VPC and subnet inputs. Confirm the chosen engine version and instance class are supported for Aurora Global Database in both Regions.

Supply separate, unique final snapshot identifiers for the primary and secondary clusters.
