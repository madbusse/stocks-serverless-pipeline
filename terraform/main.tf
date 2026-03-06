terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "stocks-serverless-pipeline"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# DynamoDB Table
resource "aws_dynamodb_table" "stock_movers" {
  name         = "${var.project_name}-movers-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "date"

  attribute {
    name = "date"
    type = "S"
  }
}

# IAM Role for Ingestion Lambda
resource "aws_iam_role" "ingestion_lambda_role" {
  name = "${var.project_name}-ingestion-lambda-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "ingestion_lambda_dynamodb" {
  name = "dynamodb-write"
  role = aws_iam_role.ingestion_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:PutItem",
        "dynamodb:UpdateItem"
      ]
      Resource = aws_dynamodb_table.stock_movers.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ingestion_lambda_logs" {
  role       = aws_iam_role.ingestion_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# IAM Role for Retrieval Lambda
resource "aws_iam_role" "retrieval_lambda_role" {
  name = "${var.project_name}-retrieval-lambda-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "retrieval_lambda_dynamodb" {
  name = "dynamodb-read"
  role = aws_iam_role.retrieval_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:GetItem"
      ]
      Resource = aws_dynamodb_table.stock_movers.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "retrieval_lambda_logs" {
  role       = aws_iam_role.retrieval_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Ingestion Lambda (placeholder)
resource "aws_lambda_function" "stock_ingestion" {
  filename      = "lambda_placeholder.zip"
  function_name = "${var.project_name}-ingestion-${var.environment}"
  role          = aws_iam_role.ingestion_lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 60

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.stock_movers.name
      STOCK_API_KEY  = var.stock_api_key
    }
  }
}

# EventBridge Rule for Daily Trigger
resource "aws_cloudwatch_event_rule" "daily_stock_ingestion" {
  name                = "${var.project_name}-daily-ingestion-${var.environment}"
  description         = "Trigger stock ingestion Lambda daily"
  schedule_expression = "cron(0 22 * * ? *)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_stock_ingestion.name
  target_id = "StockIngestionLambda"
  arn       = aws_lambda_function.stock_ingestion.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stock_ingestion.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_stock_ingestion.arn
}

# Retrieval Lambda (placeholder)
resource "aws_lambda_function" "stock_retrieval" {
  filename      = "lambda_placeholder.zip"
  function_name = "${var.project_name}-retrieval-${var.environment}"
  role          = aws_iam_role.retrieval_lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 30

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.stock_movers.name
    }
  }
}

# API Gateway
resource "aws_apigatewayv2_api" "stock_api" {
  name          = "${var.project_name}-api-${var.environment}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "OPTIONS"]
    allow_headers = ["*"]
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.stock_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "retrieval_lambda" {
  api_id           = aws_apigatewayv2_api.stock_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.stock_retrieval.invoke_arn
}

resource "aws_apigatewayv2_route" "get_movers" {
  api_id    = aws_apigatewayv2_api.stock_api.id
  route_key = "GET /movers"
  target    = "integrations/${aws_apigatewayv2_integration.retrieval_lambda.id}"
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stock_retrieval.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.stock_api.execution_arn}/*/*"
}

# S3 Bucket for Frontend Hosting
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${var.environment}-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.frontend.arn}/*"
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.frontend]
}

data "aws_caller_identity" "current" {}
