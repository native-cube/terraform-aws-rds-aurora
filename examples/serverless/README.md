# Aurora Serverless example

Creates both Serverless generations for comparison:

- Aurora MySQL Serverless v1 uses `engine_mode = "serverless"`, a v1 scaling block, and no DB instances.
- Aurora PostgreSQL Serverless v2 uses provisioned engine mode, ACU scaling, and `db.serverless` writer/reader instances.

Serverless v1 availability is limited and engine-specific. Serverless v2 auto-pause at zero or low minimum ACUs also depends on the selected engine version; confirm current Region support before applying.

Supply separate, unique final snapshot identifiers for the v1 and v2 clusters.
