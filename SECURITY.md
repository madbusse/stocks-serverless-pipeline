# Security & Secrets Management

## Secrets Protection

### What's Protected
- ✅ `.env` files excluded from git
- ✅ `terraform.tfvars` excluded (contains API keys)
- ✅ `*.tfstate` files excluded (may contain sensitive data)
- ✅ AWS credentials files excluded
- ✅ Private keys (*.pem, *.key) excluded

### Stock API Key Storage
The Stock API key is stored as a Terraform variable and passed to Lambda as an environment variable:
- Marked as `sensitive = true` in `variables.tf`
- Set in `terraform.tfvars` (git-ignored)
- Injected into Lambda environment at deployment

### Configuration Steps
1. Copy the example file:
   ```bash
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your API key:
   ```hcl
   stock_api_key = "your-actual-api-key"
   ```

3. Never commit `terraform.tfvars` to version control

## IAM Least-Privilege Roles

### Ingestion Lambda Role
**Permissions:** Write-only to DynamoDB
- `dynamodb:PutItem`
- `dynamodb:UpdateItem`
- CloudWatch Logs (basic execution)

### Retrieval Lambda Role
**Permissions:** Read-only from DynamoDB
- `dynamodb:Query`
- `dynamodb:Scan`
- `dynamodb:GetItem`
- CloudWatch Logs (basic execution)

Each Lambda has the minimum permissions needed for its specific function.

## Best Practices
- Never commit credentials to git
- Use AWS IAM roles instead of access keys where possible
- Rotate API keys regularly
- Review `.gitignore` before each commit
