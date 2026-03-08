variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "stocks-pipeline"
}

variable "finnhub_api_key" {
  description = "API key for stock data provider"
  type        = string
  sensitive   = true
}
