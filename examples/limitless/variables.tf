variable "region" {
  description = "AWS Region that supports Aurora PostgreSQL Limitless."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Aurora Limitless cluster name."
  type        = string
  default     = "example-aurora-limitless"
}

variable "engine_version" {
  description = "Aurora PostgreSQL Limitless-compatible engine version."
  type        = string
}

variable "final_snapshot_identifier" {
  description = "Unique final snapshot identifier for this cluster lifecycle. Change it before deleting a recreated cluster."
  type        = string
}

variable "database_name" {
  description = "Initial PostgreSQL database name."
  type        = string
  default     = "application"
}

variable "min_acu" {
  description = "Minimum shard-group capacity in Aurora Capacity Units."
  type        = number
  default     = 16
}

variable "max_acu" {
  description = "Maximum shard-group capacity in Aurora Capacity Units."
  type        = number
  default     = 128
}

variable "compute_redundancy" {
  description = "Number of compute standbys per shard-group node: 0, 1, or 2."
  type        = number
  default     = 1
}

variable "vpc_id" {
  description = "Existing VPC ID."
  type        = string
}

variable "subnet_ids" {
  description = "At least two existing private subnet IDs in different Availability Zones."
  type        = list(string)
}

variable "client_cidr_block" {
  description = "Private CIDR block allowed to connect to PostgreSQL."
  type        = string
}

variable "tags" {
  description = "Tags applied to created resources."
  type        = map(string)
  default = {
    Environment = "production"
    Deployment  = "Aurora Limitless"
  }
}
