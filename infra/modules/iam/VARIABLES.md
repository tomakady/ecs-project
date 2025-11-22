# IAM Module Variables & Outputs Reference

## 📋 Complete Variables List

### **Required Variables**

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `project_name` | string | Project name for resource naming | `"memos"` |
| `environment` | string | Environment (dev/staging/prod) | `"dev"` |
| `aws_region` | string | AWS region | `"eu-west-2"` |

---

### **Task Execution Role Variables**

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_secrets_access` | bool | `false` | Allow task execution to retrieve secrets |
| `secrets_arns` | list(string) | `["*"]` | ARNs of secrets to access |

**When to enable:**
- ✅ You store database passwords in Secrets Manager
- ✅ You have API keys in SSM Parameter Store
- ✅ You use encrypted environment variables

**Example:**
```hcl
module "iam" {
  enable_secrets_access = true
  secrets_arns = [
    "arn:aws:secretsmanager:eu-west-2:123456789012:secret:db-password-*",
    "arn:aws:ssm:eu-west-2:123456789012:parameter/app/*"
  ]
}
```

---

### **Task Role Variables (Application Access)**

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_efs_access` | bool | `true` | Allow app to read/write EFS | `enable_s3_access` | bool | `false` | Allow app to access S3 buckets |
| `s3_bucket_arns` | list(string) | `[]` | S3 bucket ARNs to access |
| `enable_cloudwatch_logs` | bool | `false` | Allow app to write custom logs |
| `enable_ecs_exec` | bool | `false` | Enable container debugging |
| `efs_arn` | string | `""` | EFS filesystem ARN |

**EFS Access (Enabled by default):**
```hcl
module "iam" {
  enable_efs_access = true
  efs_arn          = module.efs.efs_arn
}
```

**S3 Access (Optional):**
```hcl
module "iam" {
  enable_s3_access = true
  s3_bucket_arns = [
    "arn:aws:s3:::my-app-backups",
    "arn:aws:s3:::my-app-backups/*"  # Don't forget /* for objects!
  ]
}
```

**CloudWatch Custom Logs (Optional):**
```hcl
module "iam" {
  enable_cloudwatch_logs = true
}
```

**ECS Exec Debugging (Highly Recommended):**
```hcl
module "iam" {
  enable_ecs_exec = true
}
```

Then debug with:
```bash
aws ecs execute-command \
  --cluster memos-dev-cluster \
  --task <task-id> \
  --container app \
  --interactive \
  --command "/bin/sh"
```

---

### **GitHub Actions OIDC Variables**

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_github_oidc` | bool | `false` | Enable OIDC for GitHub Actions |
| `github_oidc_provider_arn` | string | `""` | ARN of GitHub OIDC provider |
| `github_repo` | string | `""` | Repository in format `owner/repo` |

**Example:**
```hcl
module "iam" {
  enable_github_oidc       = true
  github_oidc_provider_arn = aws_iam_openid_connect_provider.github.arn
  github_repo              = "tomakady/ecs-project"
}
```

---

### **Advanced Scoping Variables (Optional)**

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ecr_repository_arns` | list(string) | `[]` | Specific ECR repos to access |
| `ecs_cluster_arns` | list(string) | `[]` | Specific ECS clusters to manage |
| `ecs_service_arns` | list(string) | `[]` | Specific ECS services to update |

**For maximum security (optional):**
```hcl
module "iam" {
  ecr_repository_arns = [module.ecr.repository_arn]
  ecs_cluster_arns    = [module.ecs.cluster_arn]
  ecs_service_arns    = [module.ecs.service_arn]
}
```

---

## 📤 Available Outputs

### **Role ARNs (Use these in ECS task definitions)**

```hcl
# In your ECS module:
module "ecs" {
  task_execution_role_arn = module.iam.task_execution_role_arn
  task_role_arn           = module.iam.task_role_arn
}
```

### **All Outputs:**

| Output | Description | Use Case |
|--------|-------------|----------|
| `task_execution_role_arn` | Task execution role ARN | ECS task definition |
| `task_execution_role_name` | Task execution role name | IAM policy attachments |
| `task_execution_role_id` | Task execution role ID | Terraform references |
| `task_role_arn` | Task role ARN | ECS task definition |
| `task_role_name` | Task role name | IAM policy attachments |
| `task_role_id` | Task role ID | Terraform references |
| `github_actions_role_arn` | GitHub Actions role ARN | GitHub workflows |
| `github_actions_role_name` | GitHub Actions role name | Troubleshooting |
| `enabled_features` | Map of enabled features | Documentation |
| `role_summary` | Summary of all roles | Documentation |

### **Example: Viewing outputs after deployment**

```bash
# After terraform apply:
terraform output

# Output:
# enabled_features = {
#   efs_access = true
#   s3_access = false
#   cloudwatch_logs = false
#   secrets_access = false
#   ecs_exec = true
#   github_oidc = true
# }
```

---

## 🎯 Common Configuration Examples

### **1. Minimal Setup (Development)**

```hcl
module "iam" {
  source = "./modules/iam"

  project_name       = "memos"
  environment        = "dev"
  aws_region         = "eu-west-2"
  enable_efs_access  = true
  efs_arn            = module.efs.efs_arn
  enable_github_oidc = false
}
```

---

### **2. Production Setup (All Features)**

```hcl
module "iam" {
  source = "./modules/iam"

  # Required
  project_name = "memos"
  environment  = "prod"
  aws_region   = "eu-west-2"

  # Task Execution Role
  enable_secrets_access = true
  secrets_arns = [
    "arn:aws:secretsmanager:eu-west-2:*:secret:prod/db-*",
    "arn:aws:ssm:eu-west-2:*:parameter/prod/*"
  ]

  # Task Role
  enable_efs_access = true
  efs_arn           = module.efs.efs_arn

  enable_s3_access = true
  s3_bucket_arns = [
    "arn:aws:s3:::memos-prod-backups",
    "arn:aws:s3:::memos-prod-backups/*"
  ]

  enable_cloudwatch_logs = true
  enable_ecs_exec        = true

  # GitHub Actions OIDC
  enable_github_oidc       = true
  github_oidc_provider_arn = aws_iam_openid_connect_provider.github.arn
  github_repo              = "tomakady/ecs-project"
}
```

---

### **3. Multi-Environment Setup**

```hcl
# Dev environment
module "iam_dev" {
  source = "./modules/iam"

  project_name      = "memos"
  environment       = "dev"
  enable_efs_access = true
  enable_ecs_exec   = true  # Enable debugging in dev
  efs_arn           = module.efs_dev.efs_arn
}

# Production environment
module "iam_prod" {
  source = "./modules/iam"

  project_name          = "memos"
  environment           = "prod"
  enable_efs_access     = true
  enable_s3_access      = true
  enable_secrets_access = true
  efs_arn               = module.efs_prod.efs_arn
  s3_bucket_arns        = ["arn:aws:s3:::memos-prod-backups/*"]
}
```

---

## 🔒 Security Best Practices

### **✅ DO:**

1. **Use specific ARNs** when possible:
   ```hcl
   efs_arn = module.efs.efs_arn  # Good - specific resource
   ```

2. **Enable only what you need**:
   ```hcl
   enable_s3_access = false  # Don't enable unless app uses S3
   ```

3. **Use OIDC for CI/CD**:
   ```hcl
   enable_github_oidc = true  # No static credentials!
   ```

4. **Enable ECS Exec for debugging**:
   ```hcl
   enable_ecs_exec = true  # Helps troubleshoot prod issues
   ```

### **❌ DON'T:**

1. **Don't use wildcards unnecessarily**:
   ```hcl
   secrets_arns = ["*"]  # Bad - too broad
   ```

2. **Don't enable unused features**:
   ```hcl
   enable_s3_access = true  # Bad if app doesn't use S3
   ```

3. **Don't use static AWS credentials**:
   ```hcl
   enable_github_oidc = false  # Bad - forces static creds
   ```

---

## 🧪 Testing Your Configuration

### **1. Validate enabled features:**
```bash
terraform output enabled_features
```

### **2. Check role ARNs:**
```bash
terraform output task_execution_role_arn
terraform output task_role_arn
```

### **3. View role summary:**
```bash
terraform output role_summary
```

### **4. Test ECS Exec (if enabled):**
```bash
aws ecs list-tasks --cluster memos-dev-cluster
aws ecs execute-command \
  --cluster memos-dev-cluster \
  --task <task-id> \
  --container app \
  --interactive \
  --command "/bin/sh"
```

---

## 📚 Related Documentation

- [IAM Module README](./README.md) - Architecture and concepts
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [ECS Task IAM Roles](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html)
- [GitHub OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
