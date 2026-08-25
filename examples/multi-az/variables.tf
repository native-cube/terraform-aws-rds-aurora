variable "region" {
  description = "AWS Region in which to create the Multi-AZ DB cluster."
  type        = string
  default     = "eu-west-2"
}

variable "name" {
  description = "RDS Multi-AZ DB cluster name."
  type        = string
  default     = "example-rds-multi-az"
}

variable "engine_version" {
  description = "Supported RDS PostgreSQL engine version."
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

variable "allocated_storage" {
  description = "Storage allocated to each DB instance in GiB."
  type        = number
  default     = 100
}

variable "iops" {
  description = "Provisioned IOPS."
  type        = number
  default     = 1000
}

variable "instance_class" {
  description = "RDS Multi-AZ DB cluster instance class supported in the selected Region."
  type        = string
  default     = "db.m6gd.large"
}

variable "vpc_id" {
  description = "Existing VPC ID."
  type        = string
}

variable "subnet_ids" {
  description = "Three existing private subnet IDs in exactly three Availability Zones."
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
    Deployment  = "RDS Multi-AZ DB cluster"
  }
}
