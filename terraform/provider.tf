terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.1.4"
    }
  }

  backend "s3" {
    bucket         = "memos-terraform-state"
    key            = "memos/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "memos-terraform-locks"
    encrypt        = true
  }
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
