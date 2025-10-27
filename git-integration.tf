# Git Integration - Enterprise Plan
# API Gateway for receiving GitHub webhooks

resource "aws_api_gateway_rest_api" "git_webhooks" {
  name        = "${local.name_prefix}-git-webhooks"
  description = "API for receiving Git webhooks"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-git-webhooks"
  })
}

resource "aws_api_gateway_resource" "webhook" {
  rest_api_id = aws_api_gateway_rest_api.git_webhooks.id
  parent_id   = aws_api_gateway_rest_api.git_webhooks.root_resource_id
  path_part   = "webhook"
}

resource "aws_api_gateway_resource" "app_webhook" {
  rest_api_id = aws_api_gateway_rest_api.git_webhooks.id
  parent_id   = aws_api_gateway_resource.webhook.id
  path_part   = "{app_name}"
}

resource "aws_api_gateway_method" "webhook_post" {
  rest_api_id   = aws_api_gateway_rest_api.git_webhooks.id
  resource_id   = aws_api_gateway_resource.app_webhook.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "webhook_lambda" {
  rest_api_id = aws_api_gateway_rest_api.git_webhooks.id
  resource_id = aws_api_gateway_resource.app_webhook.id
  http_method = aws_api_gateway_method.webhook_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.git_webhook_handler.invoke_arn
}

resource "aws_api_gateway_deployment" "webhook_deploy" {
  depends_on = [aws_api_gateway_integration.webhook_lambda]

  rest_api_id = aws_api_gateway_rest_api.git_webhooks.id
  stage_name  = "prod"
}

# Lambda for Git Webhook Handler
resource "aws_iam_role" "webhook_lambda_role" {
  name = "${local.name_prefix}-webhook-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-webhook-lambda-role"
  })
}

resource "aws_iam_role_policy_attachment" "webhook_lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.webhook_lambda_role.name
}

resource "aws_iam_role_policy" "webhook_lambda_policy" {
  name = "${local.name_prefix}-webhook-lambda-policy"
  role = aws_iam_role.webhook_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.code_bucket.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "states:StartExecution"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-webhook-lambda-policy"
  })
}

resource "aws_lambda_function" "git_webhook_handler" {
  function_name    = "${local.name_prefix}-git-webhook-handler"
  role            = aws_iam_role.webhook_lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 60
  
  filename = "webhook_handler.zip"
  source_code_hash = filebase64sha256("webhook_handler.zip")

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-git-webhook-handler"
  })

  environment {
    variables = {
      CODE_BUCKET         = aws_s3_bucket.code_bucket.bucket
      POSTGRES_HOST       = aws_rds_cluster.postgresql.endpoint
      POSTGRES_DB         = "paasdb"
      POSTGRES_USER       = var.db_username
      POSTGRES_PASS       = var.db_password
      STEP_FUNCTION_ARN   = aws_sfn_state_machine.build_state_machine.arn
    }
  }
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.git_webhook_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.git_webhooks.execution_arn}/*/*"
}

