# ==============================================================================
# ECS TASK EXECUTION ROLE
# ==============================================================================
# This role is used BY AWS ECS SERVICE to:
# - Pull container images from ECR
# - Push logs to CloudWatch Logs
# - Retrieve secrets from Secrets Manager/SSM Parameter Store
# Think of this as the "infrastructure" role - it's what ECS needs to START your container

resource "aws_iam_role" "ecs_task_execution_role" {
  name        = "${var.project_name}-${var.environment}-execution-role"
  description = "Allows ECS tasks to call AWS services on your behalf (ECR, CloudWatch, etc.)"

  # Trust policy: Who can assume this role?
  # Answer: The ECS Tasks service
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-execution-role"
    Environment = var.environment
    Purpose     = "ECS Task Execution - Infrastructure permissions"
  }
}

# Attach AWS managed policy for standard ECS execution permissions
# This policy includes permissions for:
# - ecr:GetAuthorizationToken, ecr:BatchCheckLayerAvailability, ecr:GetDownloadUrlForLayer, ecr:BatchGetImage
# - logs:CreateLogStream, logs:PutLogEvents
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Optional: Custom policy for Secrets Manager access (if you use secrets)
resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  count = var.enable_secrets_access ? 1 : 0
  name  = "${var.project_name}-${var.environment}-execution-secrets-policy"
  role  = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "ssm:GetParameters",
          "ssm:GetParameter",
          "kms:Decrypt"
        ]
        Resource = var.secrets_arns
      }
    ]
  })
}

# ==============================================================================
# ECS TASK ROLE
# ==============================================================================
# This role is used BY YOUR APPLICATION CODE to:
# - Access S3 buckets
# - Write to DynamoDB
# - Send emails via SES
# - Access EFS, etc.
# Think of this as the "application" role - it's what your running code uses

resource "aws_iam_role" "ecs_task_role" {
  name        = "${var.project_name}-${var.environment}-task-role"
  description = "Allows ECS tasks (your application) to access AWS resources"

  # Trust policy: Who can assume this role?
  # Answer: The ECS Tasks service
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-task-role"
    Environment = var.environment
    Purpose     = "ECS Task - Application permissions"
  }
}

# Custom policy for EFS access (since your app uses EFS for persistent storage)
resource "aws_iam_role_policy" "ecs_task_efs_policy" {
  count = var.enable_efs_access ? 1 : 0
  name  = "${var.project_name}-${var.environment}-efs-policy"
  role  = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:DescribeMountTargets"
        ]
        Resource = var.efs_arn != "" ? var.efs_arn : "*"
      }
    ]
  })
}

# Optional: S3 access policy (if your app needs to read/write to S3)
resource "aws_iam_role_policy" "ecs_task_s3_policy" {
  count = var.enable_s3_access ? 1 : 0
  name  = "${var.project_name}-${var.environment}-s3-policy"
  role  = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = var.s3_bucket_arns
      }
    ]
  })
}

# Optional: CloudWatch Logs policy (if your app writes custom logs)
resource "aws_iam_role_policy" "ecs_task_cloudwatch_policy" {
  count = var.enable_cloudwatch_logs ? 1 : 0
  name  = "${var.project_name}-${var.environment}-cloudwatch-policy"
  role  = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/ecs/${var.project_name}-${var.environment}*"
      }
    ]
  })
}

# ==============================================================================
# OPTIONAL: GitHub Actions OIDC Role
# ==============================================================================
# This role allows GitHub Actions to deploy without static AWS credentials
# Uses OpenID Connect (OIDC) for secure, temporary access

resource "aws_iam_role" "github_actions_role" {
  count       = var.enable_github_oidc ? 1 : 0
  name        = "${var.project_name}-${var.environment}-github-actions-role"
  description = "Role for GitHub Actions to deploy via OIDC"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
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
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-github-actions-role"
    Environment = var.environment
    Purpose     = "GitHub Actions OIDC"
  }
}

# Policies for GitHub Actions role
resource "aws_iam_role_policy" "github_actions_policy" {
  count = var.enable_github_oidc ? 1 : 0
  name  = "${var.project_name}-${var.environment}-github-actions-policy"
  role  = aws_iam_role.github_actions_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition"
        ]
        Resource = "*"
      }
    ]
  })
}
