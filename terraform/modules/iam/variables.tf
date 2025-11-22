# ==============================================================================
# REQUIRED VARIABLES
# ==============================================================================

variable "project_name" {
  description = "Name of the project (e.g., 'memos')"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., 'dev', 'staging', 'prod')"
  type        = string
}

variable "aws_region" {
  description = "AWS region for CloudWatch logs and other regional resources"
  type        = string
  default     = "eu-west-2"
}

# ==============================================================================
# EFS ACCESS VARIABLES
# ==============================================================================

variable "enable_efs_access" {
  description = "Enable EFS access policy for the task role"
  type        = bool
  default     = true
}

variable "efs_arn" {
  description = "ARN of the EFS file system (if enable_efs_access is true)"
  type        = string
  default     = ""
}

# ==============================================================================
# SECRETS ACCESS VARIABLES
# ==============================================================================

variable "enable_secrets_access" {
  description = "Enable Secrets Manager/SSM Parameter Store access for task execution role"
  type        = bool
  default     = false
}

variable "secrets_arns" {
  description = "List of ARNs for secrets that the task execution role can access"
  type        = list(string)
  default     = ["*"]
}

# ==============================================================================
# S3 ACCESS VARIABLES
# ==============================================================================

variable "enable_s3_access" {
  description = "Enable S3 access policy for the task role"
  type        = bool
  default     = false
}

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs (including bucket/* for objects) that the task role can access"
  type        = list(string)
  default     = []
}

# ==============================================================================
# CLOUDWATCH LOGS VARIABLES
# ==============================================================================

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch Logs access policy for the task role"
  type        = bool
  default     = false
}

# ==============================================================================
# GITHUB ACTIONS OIDC VARIABLES
# ==============================================================================

variable "enable_github_oidc" {
  description = "Enable GitHub Actions OIDC role for CI/CD"
  type        = bool
  default     = false
}

variable "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider (if enable_github_oidc is true)"
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub repository in format 'owner/repo' (e.g., 'tomakady/ecs-project')"
  type        = string
  default     = ""
}
