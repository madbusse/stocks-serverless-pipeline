output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.stock_movers.name
}

output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = var.aws_region
}

output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_api.stock_api.api_endpoint
}

output "frontend_url" {
  description = "S3 website endpoint for frontend"
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
}

output "ingestion_lambda_name" {
  description = "Name of the ingestion Lambda function"
  value       = aws_lambda_function.stock_ingestion.function_name
}

output "retrieval_lambda_name" {
  description = "Name of the retrieval Lambda function"
  value       = aws_lambda_function.stock_retrieval.function_name
}
