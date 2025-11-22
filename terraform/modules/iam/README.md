# IAM Module - Comprehensive Guide

## Overview

This module manages all IAM (Identity and Access Management) roles and policies for the ECS infrastructure. It follows the principle of **least privilege** and separates concerns between infrastructure and application permissions.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      IAM MODULE                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Task Execution Role                                  │  │
│  │  (Used by ECS Service - Infrastructure)              │  │
│  ├──────────────────────────────────────────────────────┤  │
│  │  • Pull images from ECR                              │  │
│  │  • Push logs to CloudWatch                           │  │
│  │  • Read secrets from Secrets Manager/SSM             │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Task Role                                            │  │
│  │  (Used by Application Code - Runtime)                │  │
│  ├──────────────────────────────────────────────────────┤  │
│  │  • Access EFS for persistent storage                 │  │
│  │  • Access S3 buckets (optional)                      │  │
│  │  • Write custom CloudWatch logs (optional)           │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  GitHub Actions OIDC Role (Optional)                 │  │
│  │  (Used by CI/CD Pipeline)                            │  │
│  ├──────────────────────────────────────────────────────┤  │
│  │  • Push images to ECR                                │  │
│  │  • Update ECS services                               │  │
│  │  • Register new task definitions                     │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## The Two Main Roles Explained

### 1. Task Execution Role 🔧

**Who uses it?** The **ECS service itself** (AWS infrastructure)

**When is it used?** During container startup and throughout the container lifecycle

**What can it do?**
- Pull Docker images from Amazon ECR
- Send logs to CloudWatch Logs
- Retrieve secrets from AWS Secrets Manager or SSM Parameter Store
- Decrypt KMS-encrypted secrets

**Think of it as:** The "infrastructure admin" - it sets up your container environment

**Example scenario:**
```
1. You deploy a new ECS task
2. ECS uses the Task Execution Role to:
   - Authenticate with ECR
   - Pull your Docker image (e.g., memos:latest)
   - Create CloudWatch log streams
   - Inject environment variables from Secrets Manager
3. Your container starts running
```

**Policy attached:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
```

---

### 2. Task Role 🏃

**Who uses it?** Your **application code** (the software running inside the container)

**When is it used?** While your application is running and needs to access AWS services

**What can it do?**
- Read/write to EFS (Elastic File System) for persistent storage
- Access S3 buckets (if enabled)
- Write custom application logs to CloudWatch (if enabled)
- Any other AWS API calls your application makes

**Think of it as:** The "application user" - your code's identity in AWS

**Example scenario:**
```
1. Your Memos app is running
2. User uploads a file
3. Your code uses the Task Role to:
   - Write the file to EFS (/var/opt/memos/)
   - Optionally backup to S3
   - Log the operation to CloudWatch
```

**Policy example (EFS access):**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite",
        "elasticfilesystem:DescribeFileSystems"
      ],
      "Resource": "arn:aws:elasticfilesystem:eu-west-2:123456789012:file-system/fs-xxxxx"
    }
  ]
}
```

---

## Quick Comparison

| Feature | Task Execution Role | Task Role |
|---------|-------------------|-----------|
| **Used by** | AWS ECS Service | Your application code |
| **Purpose** | Start and manage containers | Access AWS resources |
| **When** | Container startup | Runtime |
| **Example actions** | Pull images, create logs | Read/write data, call APIs |
| **Analogy** | System administrator | Application user |
| **Required?** | Yes (always needed) | Depends on your app |

---

## Trust Policies Explained

Both roles have the same **trust policy** (who can assume the role):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      }
    }
  ]
}
```

**What this means:**
- Only the ECS Tasks service can assume these roles
- No users or other services can use them
- This is a security best practice

---

## Optional Features

### 1. Secrets Access (Task Execution Role)

Enable this if you store sensitive data in AWS Secrets Manager or SSM Parameter Store:

```hcl
module "iam" {
  source = "./modules/iam"

  enable_secrets_access = true
  secrets_arns = [
    "arn:aws:secretsmanager:eu-west-2:123456789012:secret:db-password-xxxxx",
    "arn:aws:ssm:eu-west-2:123456789012:parameter/app/*"
  ]
}
```

**Use case:** Database passwords, API keys, encryption keys

### 2. S3 Access (Task Role)

Enable this if your app needs to read/write to S3:

```hcl
module "iam" {
  source = "./modules/iam"

  enable_s3_access = true
  s3_bucket_arns = [
    "arn:aws:s3:::my-app-backups",
    "arn:aws:s3:::my-app-backups/*"  # Don't forget /* for objects!
  ]
}
```

**Use case:** File backups, user uploads, static assets

### 3. CloudWatch Logs (Task Role)

Enable if your app writes custom logs (beyond standard stdout/stderr):

```hcl
module "iam" {
  source = "./modules/iam"

  enable_cloudwatch_logs = true
}
```

**Use case:** Application metrics, audit logs, custom log groups

### 4. GitHub Actions OIDC

Enable for secure CI/CD without static credentials:

```hcl
module "iam" {
  source = "./modules/iam"

  enable_github_oidc = true
  github_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
  github_repo = "tomakady/ecs-project"
}
```

**Benefits:**
- ✅ No AWS access keys in GitHub secrets
- ✅ Temporary credentials (15 min - 12 hours)
- ✅ Can't be leaked or stolen
- ✅ Follows AWS best practices

---

## Usage Example

```hcl
# In your main.tf
module "iam" {
  source = "./modules/iam"

  # Required
  project_name = "memos"
  environment  = "dev"
  aws_region   = "eu-west-2"

  # EFS access for persistent storage
  enable_efs_access = true
  efs_arn           = module.efs.efs_arn

  # Optional: Enable if needed
  enable_secrets_access  = false
  enable_s3_access       = false
  enable_cloudwatch_logs = false
  enable_github_oidc     = false
}

# Pass outputs to ECS module
module "ecs" {
  source = "./modules/ecs"

  task_execution_role_arn = module.iam.task_execution_role_arn
  task_role_arn           = module.iam.task_role_arn

  # ... other variables
}
```

---

## Security Best Practices ✅

1. **Least Privilege**: Only enable the permissions you actually need
2. **Specific Resources**: Use specific ARNs instead of `*` when possible
3. **Separate Roles**: Never combine execution and task role permissions
4. **Regular Audits**: Review permissions quarterly
5. **OIDC for CI/CD**: Use OIDC instead of static credentials

---

## Common Issues & Solutions

### Issue: "Access Denied" when pulling ECR image

**Cause:** Task Execution Role missing ECR permissions
**Solution:** Ensure `AmazonECSTaskExecutionRolePolicy` is attached

### Issue: App can't write to EFS

**Cause:** Task Role missing EFS permissions
**Solution:** Set `enable_efs_access = true` and pass correct `efs_arn`

### Issue: "Unable to assume role"

**Cause:** Trust policy incorrect
**Solution:** Verify principal is `ecs-tasks.amazonaws.com`

---

## Outputs

| Output | Description | Used By |
|--------|-------------|---------|
| `task_execution_role_arn` | ARN of execution role | ECS Task Definition |
| `task_role_arn` | ARN of task role | ECS Task Definition |
| `task_execution_role_name` | Name of execution role | Policy attachments |
| `task_role_name` | Name of task role | Policy attachments |
| `github_actions_role_arn` | ARN of OIDC role | GitHub Actions workflows |

---

## Real-World Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    Container Lifecycle                          │
└─────────────────────────────────────────────────────────────────┘

1. DEPLOYMENT TRIGGERED (GitHub Actions)
   │
   ├─> GitHub Actions uses OIDC Role
   │   └─> Pushes image to ECR
   │   └─> Updates ECS service
   │
2. ECS STARTS NEW TASK
   │
   ├─> ECS uses Task Execution Role
   │   └─> Pulls image from ECR ✅
   │   └─> Creates CloudWatch log group ✅
   │   └─> Retrieves database password from Secrets Manager ✅
   │
3. CONTAINER IS RUNNING
   │
   ├─> Application uses Task Role
   │   └─> User uploads a file
   │   └─> App writes to EFS ✅
   │   └─> App logs event to CloudWatch ✅
   │   └─> App backs up to S3 ✅
   │
4. MONITORING & LOGS
   │
   └─> CloudWatch shows all container logs
       └─> Created by Task Execution Role
       └─> Written by both roles
```

---

## Next Steps

1. Review the `main.tf` file to see the actual policy definitions
2. Check `variables.tf` to understand configuration options
3. Look at `outputs.tf` to see what values are exported
4. Update your ECS module to use these outputs

**Questions?** Check the comments in `main.tf` - each resource is thoroughly documented!
