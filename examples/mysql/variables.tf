variable "region" {
  description = "AWS Region in which to create the cluster."
  type        = string
  default     = "eu-west-2"
}

variable "name" {
  description = "Aurora MySQL cluster name."
  type        = string
  default     = "example-aurora-mysql"
}

variable "engine_version" {
  description = "Supported Aurora MySQL engine version."
  type        = string
}

variable "final_snapshot_identifier" {
  description = "Unique final snapshot identifier for this cluster lifecycle. Change it before deleting a recreated cluster."
  type        = string
}

variable "database_name" {
  description = "Initial MySQL database name."
  type        = string
  default     = "application"
}

variable "instance_class" {
  description = "Aurora instance class."
  type        = string
  default     = "db.r7g.large"
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
  description = "Private CIDR block allowed to connect to MySQL."
  type        = string
}

variable "tags" {
  description = "Tags applied to created resources."
  type        = map(string)
  default = {
    Environment = "production"
    Engine      = "Aurora MySQL"
  }
}
