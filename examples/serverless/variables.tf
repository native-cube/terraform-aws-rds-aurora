variable "region" {
  description = "AWS Region supporting both selected Serverless engine versions."
  type        = string
  default     = "eu-west-2"
}

variable "name" {
  description = "Name prefix for the two Serverless example clusters."
  type        = string
  default     = "example-aurora-serverless"
}

variable "serverless_v1_engine_version" {
  description = "Aurora MySQL engine version supporting Serverless v1 in the selected Region."
  type        = string
}

variable "serverless_v2_engine_version" {
  description = "Aurora PostgreSQL engine version supporting Serverless v2 and auto-pause in the selected Region."
  type        = string
}

variable "serverless_v1_final_snapshot_identifier" {
  description = "Unique final snapshot identifier for the Serverless v1 cluster lifecycle."
  type        = string
}

variable "serverless_v2_final_snapshot_identifier" {
  description = "Unique final snapshot identifier for the Serverless v2 cluster lifecycle."
  type        = string
}

variable "database_name" {
  description = "Initial database name for both clusters."
  type        = string
  default     = "application"
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
  description = "Private CIDR block allowed to connect to both clusters."
  type        = string
}

variable "tags" {
  description = "Tags applied to created resources."
  type        = map(string)
  default = {
    Environment = "example"
    Deployment  = "Aurora Serverless"
  }
}
