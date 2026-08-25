# Codex Instructions

These instructions apply to the whole Terraform Amazon RDS/Aurora module.

## Module Scope

- Keep this as a reusable RDS, Aurora, and Aurora DSQL module, not a complete environment stack.
- Do not create VPCs, subnets, NAT gateways, route tables, KMS keys, Secrets Manager secrets, or AWS provider configuration in the root module. Examples may configure providers.
- Accept existing networking and encryption inputs and expose outputs useful for composition.
- Preserve backward compatibility for existing variables, outputs, and resource addresses unless the user explicitly requests a breaking change.

## Terraform Style

- Run `terraform fmt -recursive` after editing Terraform files.
- Keep root files split by concern: `versions.tf`, `variables.tf`, `locals.tf`, `data.tf`, `network.tf`, `parameters.tf`, `monitoring.tf`, `cluster.tf`, `integrations.tf`, `autoscaling.tf`, `dsql.tf`, and `outputs.tf`.
- Document every variable and output. Validate constrained values and use resource preconditions for cross-variable rules.
- Prefer `for_each` with stable caller-controlled keys for repeatable resources and `count` for optional singletons.
- Use `local.common_tags` for module-created resources.
- Never configure an AWS provider in the root module or hard-code Regions, accounts, credentials, ARNs, VPCs, subnets, or KMS keys.
- Do not expose passwords. Mark credential inputs sensitive and explain Terraform state implications.

## RDS And Aurora Practices

- Keep Aurora instances separate from RDS Multi-AZ DB clusters; AWS manages instances inside a Multi-AZ DB cluster.
- Aurora Serverless v1 uses `engine_mode = "serverless"` and no cluster instances. Serverless v2 uses provisioned engine mode, a Serverless v2 scaling configuration, and `db.serverless` instances.
- Aurora Limitless is Aurora PostgreSQL-only and uses a DB shard group instead of cluster instances.
- Secondary global clusters must not receive primary-only database names or master credentials.
- Keep storage encrypted, private access, IAM database authentication, deletion protection, backups, and final snapshots as production-oriented defaults.
- Use AWS-managed master passwords by default. Caller-managed passwords must use the write-only ephemeral input and a non-ephemeral version input; never reintroduce a state-backed password argument.
- DSQL multi-Region peering requires one peering resource in every participating Region.

## Examples And Documentation

- Keep examples under `examples/`, consuming the root module from `../..`.
- Maintain examples for DSQL, global clusters, RDS Multi-AZ DB clusters, Aurora Limitless, Aurora PostgreSQL, Aurora MySQL, and Serverless.
- Update the README for user-facing behavior. Do not manually edit content between terraform-docs markers.
- Do not commit state, credentials, generated plans, real `terraform.tfvars`, or `.terraform/` directories.

## Verification

Run `make check`, or run formatting, docs, initialization, validation, tests, and validation of every example separately. CI also runs TFLint, Trivy, and minimum/latest compatibility jobs. Never run `terraform apply` or `terraform destroy` unless explicitly requested and the target environment is confirmed.
