variable "name" {
  description = "Name prefix used in DSQL tags and module calls. DSQL generates cluster identifiers."
  type        = string
  default     = "example-dsql"
}

variable "primary_region" {
  description = "Region for the single-Region example and first multi-Region cluster."
  type        = string
  default     = "eu-west-2"
}

variable "secondary_region" {
  description = "Region for the second multi-Region DSQL cluster."
  type        = string
  default     = "eu-west-1"
}

variable "witness_region" {
  description = "Third DSQL Region used as the multi-Region cluster witness."
  type        = string
  default     = "eu-central-1"
}

variable "tags" {
  description = "Tags applied to DSQL clusters."
  type        = map(string)
  default = {
    Environment = "production"
    Service     = "Aurora DSQL"
  }
}
