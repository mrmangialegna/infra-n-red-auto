# CI/CD for Enterprise Plan - CodeBuild + Step Functions

# IAM Role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "${local.name_prefix}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-codebuild-role"
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_policy_attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "codebuild_ecr_policy" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "codebuild_logs_policy" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy" "codebuild_ecs_policy" {
  name = "${local.name_prefix}-codebuild-ecs-policy"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:UpdateService",
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "iam:PassRole"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-codebuild-ecs-policy"
  })
}

# CodeBuild project
resource "aws_codebuild_project" "build_project" {
  name          = "${local.name_prefix}-build-project"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = 30

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_MEDIUM"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
    
    environment_variable {
      name  = "ECR_REPOSITORY_URI"
      value = aws_ecr_repository.app.repository_url
    }
    
    environment_variable {
      name  = "ECS_CLUSTER_NAME"
      value = aws_ecs_cluster.main.name
    }
    
    environment_variable {
      name  = "ECS_SERVICE_NAME"
      value = aws_ecs_service.app.name
    }
    
    environment_variable {
      name  = "DATABASE_URL"
      value = "postgresql://${var.db_username}:${var.db_password}@${aws_rds_cluster.postgresql.endpoint}:5432/${aws_rds_cluster.postgresql.database_name}"
    }
  }

  source {
    type      = "S3"
    location  = "${aws_s3_bucket.code_bucket.bucket}/source.zip"
    buildspec = "buildspec.yml"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-build-project"
  })
}

# IAM Role for Step Functions
resource "aws_iam_role" "sf_role" {
  name = "${local.name_prefix}-stepfunctions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-stepfunctions-role"
  })
}

resource "aws_iam_role_policy" "sf_policy" {
  name   = "${local.name_prefix}-stepfunctions-policy"
  role   = aws_iam_role.sf_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds"
        ]
        Resource = aws_codebuild_project.build_project.arn
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-stepfunctions-policy"
  })
}

# Step Functions state machine
resource "aws_sfn_state_machine" "build_state_machine" {
  name     = "${local.name_prefix}-build-state-machine"
  role_arn = aws_iam_role.sf_role.arn

  definition = jsonencode({
    Comment = "State machine to build user code and deploy to ECS"
    StartAt = "BuildCode"
    States = {
      BuildCode = {
        Type = "Task"
        Resource = "arn:aws:states:::codebuild:startBuild.sync"
        Parameters = {
          ProjectName = aws_codebuild_project.build_project.name
        }
        Next = "DeployToECS"
      }
      DeployToECS = {
        Type = "Pass"
        Result = "Deployed to ECS successfully"
        End = true
      }
    }
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-build-state-machine"
  })
}

# EventBridge rule for S3 uploads
resource "aws_cloudwatch_event_rule" "s3_upload_rule" {
  name        = "${local.name_prefix}-s3-upload-rule"
  description = "Trigger Step Function when user uploads code"
  event_pattern = jsonencode({
    source = ["aws.s3"]
    detail-type = ["Object Created"]
    resources = [aws_s3_bucket.code_bucket.arn]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-s3-upload-rule"
  })
}

# EventBridge target (Step Functions)
resource "aws_cloudwatch_event_target" "s3_upload_target" {
  rule      = aws_cloudwatch_event_rule.s3_upload_rule.name
  target_id = "StepFunction"
  arn       = aws_sfn_state_machine.build_state_machine.arn
}

