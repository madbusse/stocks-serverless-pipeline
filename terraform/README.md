# Terraform Deployment Guide

## Prerequisites

- AWS CLI configured with credentials
- Terraform >= 1.0 installed
- Stock API key (e.g., from Alpha Vantage, Polygon.io, or similar)

## Quick Start

1. **Configure variables:**
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Review the plan:**
   ```bash
   terraform plan
   ```

4. **Deploy infrastructure:**
   ```bash
   terraform apply
   ```

5. **View outputs:**
   ```bash
   terraform output
   ```

## Resources Created

- **DynamoDB Table**: Stores daily top mover records
- **Lambda Functions**: 
  - Ingestion Lambda (triggered daily by EventBridge)
  - Retrieval Lambda (serves API requests)
- **IAM Roles**: Least-privilege roles for each Lambda
- **EventBridge Rule**: Daily cron trigger at 10 PM UTC
- **API Gateway**: HTTP API with GET /movers endpoint
- **S3 Bucket**: Static website hosting for frontend

## Tear Down

```bash
terraform destroy
```

## Notes

- Lambda functions use placeholder code; actual implementation needed
- Stock API key stored as Lambda environment variable
- All resources tagged with Project, Environment, and ManagedBy
