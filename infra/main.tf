
# # S3 Bucket for Terraform State
# resource "aws_s3_bucket" "terraform_state" {
#   bucket        = "memos-terraform-state"
#   force_destroy = true

#   tags = {
#     Name = "Terraform State Bucket"
#   }
# }

# resource "aws_s3_bucket_versioning" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id

#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id

#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }

# # DynamoDB Table for State Locking
# resource "aws_dynamodb_table" "terraform_locks" {
#   name         = "memos-terraform-locks"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "LockID"

#   attribute {
#     name = "LockID"
#     type = "S"
#   }

#   tags = {
#     Name = "Terraform State Lock Table"
#   }
# }

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

# Security Groups Module
module "sg" {
  source = "./modules/sg"

  project_name   = var.project_name
  environment    = var.environment
  vpc_id         = module.vpc.vpc_id
  container_port = var.container_port

  depends_on = [module.vpc]
}

# Route53 Module
module "route53" {
  source = "./modules/route53"

  project_name = var.project_name
  environment  = var.environment
  domain_name  = var.domain_name
  subdomain    = "tm.${var.domain_name}"
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id
}

# ACM Module
module "acm" {
  source       = "./modules/acm"
  project_name = var.project_name
  environment  = var.environment
  domain_name  = "tm.${var.domain_name}"
  zone_id      = module.route53.zone_id
}

# ALB Module
module "alb" {
  source = "./modules/alb"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.sg.alb_security_group_id
  container_port        = var.container_port
  health_check_path     = var.health_check_path
  certificate_arn       = module.acm.certificate_arn
  enable_https          = true
  depends_on            = [module.sg]
}

# EFS Module
module "efs" {
  source = "./modules/efs"

  project_name          = var.project_name
  environment           = var.environment
  private_subnet_ids    = module.vpc.private_subnet_ids
  efs_security_group_id = module.sg.efs_security_group_id

  depends_on = [module.sg]
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"

  project_name         = var.project_name
  environment          = var.environment
  image_tag_mutability = var.image_tag_mutability
  scan_on_push         = var.scan_on_push
  image_count_to_keep  = var.image_count_to_keep
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  project_name        = var.project_name
  environment         = var.environment
  aws_region          = var.aws_region
  enable_efs_access   = true
  efs_arn             = module.efs.efs_arn
  enable_autoscaling  = true
  enable_github_oidc  = true
  github_oidc_provider_arn = "arn:aws:iam::773913840750:oidc-provider/token.actions.githubusercontent.com"
  github_repo              = "tomakady/ecs-project"

  depends_on = [module.efs]
}
  

# ECS Module
module "ecs" {
  source = "./modules/ecs"

  project_name          = var.project_name
  environment           = var.environment
  aws_region            = var.aws_region
  private_subnet_ids    = module.vpc.private_subnet_ids
  ecs_security_group_id = module.sg.ecs_security_group_id
  target_group_arn      = module.alb.target_group_arn
  alb_listener_arn      = module.alb.alb_arn
  ecr_repository_url    = module.ecr.repository_url
  image_tag             = var.image_tag
  container_name        = var.container_name
  container_port        = var.container_port
  task_cpu              = var.task_cpu
  task_memory           = var.task_memory
  desired_count         = var.desired_count
  efs_id                = module.efs.efs_id
  efs_arn               = module.efs.efs_arn
  efs_access_point_id   = module.efs.access_point_id
  efs_mount_path        = var.efs_mount_path
  log_retention_days    = var.log_retention_days
  environment_variables = var.environment_variables
  task_execution_role_arn = module.iam.task_execution_role_arn
  task_role_arn           = module.iam.task_role_arn          

  depends_on = [module.alb, module.efs, module.ecr, module.sg]
}
