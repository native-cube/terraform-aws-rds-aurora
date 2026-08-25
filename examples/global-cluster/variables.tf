variable "name" {
  description = "RDS global cluster identifier and regional-cluster name prefix."
  type        = string
  default     = "example-aurora-global"
}

variable "primary_region" {
  description = "AWS Region for the primary Aurora cluster."
  type        = string
  default     = "eu-west-2"
}

variable "secondary_region" {
  description = "AWS Region for the secondary Aurora cluster."
  type        = string
  default     = "eu-west-1"
}

variable "engine_version" {
  description = "Aurora PostgreSQL version supported for global databases in both Regions."
  type        = string
}

variable "database_name" {
  description = "Initial database name on the primary cluster."
  type        = string
  default     = "application"
}

variable "master_password_wo" {
  description = "Write-only master password for the global primary. Terraform does not persist this ephemeral value in plans or state."
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "master_password_wo_version" {
  description = "Positive version for the write-only global-primary password. Increment it whenever the password changes."
  type        = number
  default     = 1
}

variable "primary_final_snapshot_identifier" {
  description = "Unique final snapshot identifier for the primary cluster lifecycle."
  type        = string
}

variable "secondary_final_snapshot_identifier" {
  description = "Unique final snapshot identifier for the secondary cluster lifecycle."
  type        = string
}

variable "instance_class" {
  description = "Aurora instance class supported in both Regions."
  type        = string
  default     = "db.r7g.large"
}

variable "primary_vpc_id" {
  description = "Existing VPC ID in the primary Region."
  type        = string
}

variable "primary_subnet_ids" {
  description = "Private subnet IDs in the primary Region."
  type        = list(string)
}

variable "primary_client_cidr_block" {
  description = "Private client CIDR allowed in the primary Region."
  type        = string
}

variable "secondary_vpc_id" {
  description = "Existing VPC ID in the secondary Region."
  type        = string
}

variable "secondary_subnet_ids" {
  description = "Private subnet IDs in the secondary Region."
  type        = list(string)
}

variable "secondary_client_cidr_block" {
  description = "Private client CIDR allowed in the secondary Region."
  type        = string
}

variable "enable_global_write_forwarding" {
  description = "Whether the secondary forwards writes to the primary."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to created resources."
  type        = map(string)
  default = {
    Environment = "production"
    Deployment  = "Aurora Global Database"
  }
}
