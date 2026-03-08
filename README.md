# 📈 Stocks Serverless Pipeline

Automated serverless pipeline that tracks tech stock movements, identifies daily top movers, and displays 7-day history via a public dashboard.

## Architecture

```
┌─────────────┐
│ EventBridge │ (Daily 4:15 PM ET)
└──────┬──────┘
       │
       ▼
┌─────────────────┐      ┌──────────┐
│ Ingestion Lambda│─────▶│ DynamoDB │
│  (Finnhub API)  │      │  Table   │
└─────────────────┘      └────┬─────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ Retrieval Lambda │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  API Gateway    │
                    │  GET /movers    │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │   S3 Frontend   │
                    │   (Dashboard)   │
                    └─────────────────┘
```

**Watchlist:** AAPL, MSFT, GOOGL, AMZN, TSLA, NVDA

## Prerequisites

- AWS Account with CLI configured
- Terraform >= 1.0
- Python 3.11
- Finnhub API key (free tier: https://finnhub.io)

## Quick Start

### 1. Configure Secrets

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
aws_region     = "us-east-1"
environment    = "dev"
project_name   = "stocks-pipeline"
stock_api_key  = "your-finnhub-api-key"
```

### 2. Deploy Infrastructure

```bash
terraform init
terraform apply
```

This creates:
- DynamoDB table for storing daily top movers
- Ingestion Lambda (triggered daily at 4:15 PM ET)
- Retrieval Lambda (serves API requests)
- API Gateway HTTP API
- S3 bucket for frontend hosting
- IAM roles with least-privilege permissions
- EventBridge cron rule

### 3. Deploy Frontend

```bash
# Get API endpoint
terraform output api_endpoint

# Deploy dashboard
cd ../frontend
./deploy.sh <api-endpoint-url>
```

### 4. Access Dashboard

```bash
cd ../terraform
terraform output frontend_url
```

Visit the URL to see the 7-day top mover history.

## How It Works

1. **Daily Ingestion** (4:15 PM ET):
   - EventBridge triggers ingestion Lambda
   - Fetches open/close prices for 6 tickers from Finnhub
   - Calculates: `% Change = ((Close - Open) / Open) * 100`
   - Identifies ticker with highest absolute % change
   - Stores winner in DynamoDB

2. **API Access**:
   - Frontend calls `GET /movers`
   - Retrieval Lambda queries last 7 days from DynamoDB
   - Returns JSON array sorted by date

3. **Dashboard Display**:
   - Shows table with Date, Ticker, % Change, Closing Price
   - Green for gains, red for losses

## Project Structure

```
.
├── terraform/           # Infrastructure as Code
│   ├── main.tf         # AWS resources
│   ├── variables.tf    # Configuration
│   └── outputs.tf      # Deployment info
├── lambda/
│   ├── ingestion/      # Daily stock fetcher
│   └── retrieval/      # API handler
├── frontend/           # Dashboard SPA
└── SECURITY.md         # Secrets management guide
```

## Tear Down

```bash
cd terraform
terraform destroy
```

## Trade-offs & Notes

- **API Limits**: Finnhub free tier = 60 requests/day (using 6/day)
- **Timing**: Runs at 4:15 PM ET to allow market data to finalize
- **Market Hours**: Automatically skips execution on weekends and US market holidays
- **Storage**: DynamoDB on-demand pricing (cost-effective for low volume)
- **Frontend**: Plain HTML/JS (no build step, instant deployment)
- **Error Handling**: Partial failures don't crash the run; logs to CloudWatch

## Security

- API key stored in Terraform variables (marked sensitive)
- `.gitignore` excludes all credentials and state files
- IAM roles follow least-privilege principle
- See `SECURITY.md` for details

## Monitoring

View logs in CloudWatch:
- Log group: `/aws/lambda/stocks-pipeline-ingestion-dev`
- Log group: `/aws/lambda/stocks-pipeline-retrieval-dev`

## Troubleshooting

### Frontend shows "No data available"

**Cause:** DynamoDB table is empty (ingestion Lambda only runs daily at 4:15 PM ET)

**Solution:** Manually trigger the ingestion Lambda:
```bash
cd terraform
aws lambda invoke --function-name $(terraform output -raw ingestion_lambda_name) \
  --region $(terraform output -raw aws_region) \
  response.json
cat response.json
```

Or use the helper script:
```bash
./trigger-ingestion.sh
```

### API returns empty array

**Check if data exists in DynamoDB:**
```bash
cd terraform
aws dynamodb scan --table-name $(terraform output -raw dynamodb_table_name) \
  --region $(terraform output -raw aws_region)
```

### Frontend shows API error

**Test API directly:**
```bash
cd terraform
curl $(terraform output -raw api_endpoint)/movers
```

**Check if API endpoint was correctly deployed:**
```bash
cd terraform
terraform output api_endpoint
# Verify this matches the URL in your deployed frontend
```

### Lambda not found error

**Verify region matches:**
```bash
cd terraform
terraform output aws_region
aws configure get region
```

If they don't match, update your AWS CLI default region or specify `--region` in commands.

### Check Lambda logs

**Ingestion Lambda:**
```bash
aws logs tail /aws/lambda/stocks-pipeline-ingestion-dev --follow
```

**Retrieval Lambda:**
```bash
aws logs tail /aws/lambda/stocks-pipeline-retrieval-dev --follow
```

