# Aurora Limitless example

Creates an Aurora PostgreSQL Limitless cluster and DB shard group. Limitless replaces normal writer/reader instances with a shard group and is available only for supported Aurora PostgreSQL versions and Regions. Review ACU and compute-redundancy cost before deployment.

The example uses Aurora I/O-Optimized storage, as required by Limitless, and requires a unique final snapshot identifier.
