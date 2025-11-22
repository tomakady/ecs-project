# ==============================================================================
# ECS TASK EXECUTION ROLE OUTPUTS
# ==============================================================================

output "task_execution_role_arn" {
  description = "ARN of the ECS task execution role (used by ECS to pull images, push logs)"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "task_execution_role_name" {
  description = "Name of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.name
}

output "task_execution_role_id" {
  description = "ID of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.id
}

# ==============================================================================
# ECS TASK ROLE OUTPUTS
# ==============================================================================

output "task_role_arn" {
  description = "ARN of the ECS task role (used by application code to access AWS resources)"
  value       = aws_iam_role.ecs_task_role.arn
}

output "task_role_name" {
  description = "Name of the ECS task role"
  value       = aws_iam_role.ecs_task_role.name
}

output "task_role_id" {
  description = "ID of the ECS task role"
  value       = aws_iam_role.ecs_task_role.id
}

# ==============================================================================
# GITHUB ACTIONS OIDC ROLE OUTPUTS
# ==============================================================================

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions OIDC role (if enabled)"
  value       = var.enable_github_oidc ? aws_iam_role.github_actions_role[0].arn : null
}

output "github_actions_role_name" {
  description = "Name of the GitHub Actions OIDC role (if enabled)"
  value       = var.enable_github_oidc ? aws_iam_role.github_actions_role[0].name : null
}

# ==============================================================================
# POLICY ATTACHMENT STATUS (for debugging/validation)
# ==============================================================================

output "enabled_features" {
  description = "Map of enabled IAM features"
  value = {
    efs_access         = var.enable_efs_access
    s3_access          = var.enable_s3_access
    cloudwatch_logs    = var.enable_cloudwatch_logs
    secrets_access     = var.enable_secrets_access
    ecs_exec           = var.enable_ecs_exec
    github_oidc        = var.enable_github_oidc
  }
}

# ==============================================================================
# ROLE SUMMARY (for documentation)
# ==============================================================================

output "role_summary" {
  description = "Summary of all IAM roles created"
  value = {
    task_execution = {
      arn  = aws_iam_role.ecs_task_execution_role.arn
      name = aws_iam_role.ecs_task_execution_role.name
      purpose = "Pull images from ECR, push logs to CloudWatch"
    }
    task_role = {
      arn  = aws_iam_role.ecs_task_role.arn
      name = aws_iam_role.ecs_task_role.name
      purpose = "Application access to AWS resources (EFS, S3, etc.)"
    }
    github_actions = var.enable_github_oidc ? {
      arn  = aws_iam_role.github_actions_role[0].arn
      name = aws_iam_role.github_actions_role[0].name
      purpose = "CI/CD deployments via OIDC (no static credentials)"
    } : null
  }
}
