output "single_region_cluster" {
  description = "Single-Region DSQL cluster details."
  value       = module.single_region.dsql_clusters["this"]
}

output "multi_region_primary_cluster" {
  description = "First multi-Region DSQL cluster details."
  value       = module.multi_region_primary.dsql_clusters["this"]
}

output "multi_region_secondary_cluster" {
  description = "Second multi-Region DSQL cluster details."
  value       = module.multi_region_secondary.dsql_clusters["this"]
}
