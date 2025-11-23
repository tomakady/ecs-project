# ==============================================================================
# DATA SOURCES
# ==============================================================================

data "aws_caller_identity" "current" {}

# ==============================================================================
# ECS TASK EXECUTION ROLE
# ==============================================================================
resource "aws_iam_role" "ecs_task_execution_role" {
  name        = "${var.project_name}-${var.environment}-execution-role"
  description = "Allows ECS tasks to call AWS services on your behalf (ECR, CloudWatch, etc.)"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-execution-role"
    Environment = var.environment
    Purpose     = "ECS Task Execution - Infrastructure permissions"
  }
}

# ✅ CUSTOM REPLACEMENT for AmazonECSTaskExecutionRolePolicy
# Instead of the managed policy, use this scoped version
resource "aws_iam_role_policy" "ecs_task_execution_policy" {
  name = "${var.project_name}-${var.environment}-execution-policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
        # Note: ecr:GetAuthorizationToken doesn't support resource-level permissions
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/ecs/${var.project_name}-${var.environment}*"
        # ↑ Scoped to only YOUR app's log groups!
      }
    ]
  })
}

# Optional: Secrets Manager access
resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  count = var.enable_secrets_access ? 1 : 0
  name  = "${var.project_name}-${var.environment}-execution-secrets-policy"
  role  = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "ssm:GetParameters",
        "ssm:GetParameter",
        "kms:Decrypt"
      ]
      Resource = var.secrets_arns
    }]
  })
}

# ==============================================================================
# ECS TASK ROLE
# ==============================================================================
resource "aws_iam_role" "ecs_task_role" {
  name        = "${var.project_name}-${var.environment}-task-role"
  description = "Allows ECS tasks (your application) to access AWS resources"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-task-role"
    Environment = var.environment
    Purpose     = "ECS Task - Application permissions"
  }
}

# ✅ CUSTOM REPLACEMENT for CloudWatchLogsFullAccess
# Much more restrictive - only YOUR app's logs
resource "aws_iam_role_policy" "ecs_task_cloudwatch_policy" {
  count = var.enable_cloudwatch_logs ? 1 : 0
  name  = "${var.project_name}-${var.environment}-cloudwatch-policy"
  role  = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ]
      Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/ecs/${var.project_name}-${var.environment}*"
      # ↑ Only YOUR app, not all CloudWatch logs in the account!
    }]
  })
}

# ✅ CUSTOM REPLACEMENT for AmazonSSMManagedInstanceCore (for ECS Exec)
# Scoped to only what's needed for ECS Execute Command
resource "aws_iam_role_policy" "ecs_exec_policy" {
  count = var.enable_ecs_exec ? 1 : 0
  name  = "${var.project_name}-${var.environment}-exec-policy"
  role  = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ]
      Resource = "*"
      # Note: SSM Messages doesn't support resource-level permissions
    }]
  })
}

# EFS access policy
resource "aws_iam_role_policy" "ecs_task_efs_policy" {
  count = var.enable_efs_access ? 1 : 0
  name  = "${var.project_name}-${var.environment}-efs-policy"
  role  = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite",
        "elasticfilesystem:DescribeFileSystems",
        "elasticfilesystem:DescribeMountTargets"
      ]
      Resource = var.efs_arn != "" ? var.efs_arn : "*"
    }]
  })
}

# S3 access policy (optional)
resource "aws_iam_role_policy" "ecs_task_s3_policy" {
  count = var.enable_s3_access ? 1 : 0
  name  = "${var.project_name}-${var.environment}-s3-policy"
  role  = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      Resource = var.s3_bucket_arns
    }]
  })
}

# ==============================================================================
# GITHUB ACTIONS OIDC ROLE
# ==============================================================================
resource "aws_iam_role" "github_actions_role" {
  count       = var.enable_github_oidc ? 1 : 0
  name        = "${var.project_name}-${var.environment}-github-actions-role"
  description = "Role for GitHub Actions to deploy via OIDC"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRoleWithWebIdentity"
      Principal = {
        Federated = var.github_oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
        }
      }
    }]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-github-actions-role"
    Environment = var.environment
    Purpose     = "GitHub Actions OIDC"
  }
}

# ✅ CUSTOM REPLACEMENT for AmazonECS_FullAccess + AmazonEC2ContainerRegistryPowerUser
# MUCH more restrictive - only what GitHub Actions actually needs
resource "aws_iam_role_policy" "github_actions_policy" {
  count = var.enable_github_oidc ? 1 : 0
  name  = "${var.project_name}-${var.environment}-github-actions-policy"
  role  = aws_iam_role.github_actions_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # S3 backend permissions
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::memos-terraform-state",
          "arn:aws:s3:::memos-terraform-state/*"
        ]
      },
      {
        # DynamoDB state locking
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:*:table/memos-terraform-locks"
      },
      {
        # ECR permissions
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:CreateRepository",
          "ecr:DescribeRepositories"
        ]
        Resource = "*"
      },
      {
        # ECS permissions
        Effect = "Allow"
        Action = [
          "ecs:*"
        ]
        Resource = "*"
      },
      {
        # EC2/VPC permissions
        Effect = "Allow"
        Action = [
          "ec2:*"
        ]
        Resource = "*"
      },
      {
        # ELB permissions
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*"
        ]
        Resource = "*"
      },
      {
        # Route53 permissions
        Effect = "Allow"
        Action = [
          "route53:*"
        ]
        Resource = "*"
      },
      {
        # ACM permissions
        Effect = "Allow"
        Action = [
          "acm:*"
        ]
        Resource = "*"
      },
      {
        # CloudWatch permissions
        Effect = "Allow"
        Action = [
          "logs:*"
        ]
        Resource = "*"
      },
      {
        # IAM PassRole
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-${var.environment}-execution-role",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-${var.environment}-task-role"
        ]
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      },
      {
        # EFS permissions
        Effect = "Allow"
        Action = [
          "elasticfilesystem:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# ==============================================================================
# OPTIONAL: Application Auto Scaling Role
# ==============================================================================
# This role allows Application Auto Scaling to scale ECS services automatically
# based on CloudWatch metrics (CPU, memory, custom metrics)



resource "aws_iam_role" "ecs_autoscaling_role" {
  count       = var.enable_autoscaling ? 1 : 0
  name        = "${var.project_name}-${var.environment}-autoscaling-role"
  description = "Role for Application Auto Scaling to manage ECS service scaling"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "application-autoscaling.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-autoscaling-role"
    Environment = var.environment
    Purpose     = "Application Auto Scaling for ECS"
  }
}

# Policy for Auto Scaling role

resource "aws_iam_role_policy" "ecs_autoscaling_policy" {
  count = var.enable_autoscaling ? 1 : 0
  name  = "${var.project_name}-${var.environment}-autoscaling-policy"
  role  = aws_iam_role.ecs_autoscaling_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:UpdateService"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:DeleteAlarms"
        ]
        Resource = "*"
      }
    ]
  })
}