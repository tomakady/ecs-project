output "alb_security_group_id" {
  description = "ID of ALB security group"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "ID of ECS security group"
  value       = aws_security_group.ecs.id
}

output "efs_security_group_id" {
  description = "ID of EFS security group"
  value       = aws_security_group.efs.id
}
