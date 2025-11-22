# EFS File System
resource "aws_efs_file_system" "main" {
  creation_token = "${var.project_name}-${var.environment}-efs"
  encrypted      = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-efs"
    Environment = var.environment
  }
}

# EFS Mount Targets (one per private subnet)
resource "aws_efs_mount_target" "main" {
  count           = length(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [var.efs_security_group_id]
}

# EFS Access Point
resource "aws_efs_access_point" "main" {
  file_system_id = aws_efs_file_system.main.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/memos"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-efs-ap"
    Environment = var.environment
  }
}
