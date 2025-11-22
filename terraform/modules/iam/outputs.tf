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
