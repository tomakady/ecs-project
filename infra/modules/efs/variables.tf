variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EFS mount targets"
  type        = list(string)
}

variable "efs_security_group_id" {
  description = "Security group ID for EFS mount targets"
  type        = string
}
