terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # backend "s3" {
  #   bucket         = "memos-terraform-state"
  #   key            = "memos/terraform.tfstate"
  #   region         = "eu-west-2"
  #   dynamodb_table = "memos-terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  bucket = "memos-terraform-state"

  tags = {
    Name = "Terraform State Bucket"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# DynamoDB Table for State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "memos-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform State Lock Table"
  }
}

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

# ACM Module - COMMENTED OUT FOR TESTING
# module "acm" {
#   source = "./modules/acm"
#
#   project_name              = var.project_name
#   environment               = var.environment
#   domain_name               = var.domain_name
#   subject_alternative_names = var.subject_alternative_names
#   route53_zone_id           = var.route53_zone_id
# }

# ALB Module
module "alb" {
  source = "./modules/alb"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.sg.alb_security_group_id
  certificate_arn       = "" # Empty for HTTP-only
  container_port        = var.container_port
  health_check_path     = var.health_check_path

  depends_on = [module.sg]
}

# Route53 Module - COMMENTED OUT FOR TESTING
# module "route53" {
#   source = "./modules/route53"
#
#   project_name     = var.project_name
#   environment      = var.environment
#   route53_zone_id  = var.route53_zone_id
#   domain_name      = var.domain_name
#   alb_dns_name     = module.alb.alb_dns_name
#   alb_zone_id      = module.alb.alb_zone_id
#
#   depends_on = [module.alb]
# }

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

  depends_on = [module.alb, module.efs, module.ecr, module.sg]
}
