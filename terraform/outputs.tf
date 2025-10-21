# Networking Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

# ALB Outputs
output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.alb.alb_dns_name
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${module.alb.alb_dns_name}" # Changed to use ALB DNS
}

# # ACM Outputs
# output "certificate_arn" {
#   description = "ARN of the SSL certificate"
#   value       = module.acm.certificate_arn
# }

# # Route53 Outputs
# output "domain_fqdn" {
#   description = "Fully qualified domain name"
#   value       = module.route53.fqdn
# }

# EFS Outputs
output "efs_id" {
  description = "ID of the EFS file system"
  value       = module.efs.efs_id
}

output "efs_dns_name" {
  description = "DNS name of the EFS file system"
  value       = module.efs.efs_dns_name
}

# ECR Outputs
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

# ECS Outputs
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs.service_name
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.ecs.log_group_name
}

output "nameservers" {
  value       = module.route53.name_servers
  description = "Nameservers to configure at names.co.uk"
}

output "app_url" {
  value       = "https://tm.${var.domain_name}"
  description = "Application HTTPS URL"
}

output "certificate_arn" {
  value       = module.acm.certificate_arn
  description = "ACM certificate ARN"
}
