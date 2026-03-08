#!/bin/bash

# Manually trigger the ingestion Lambda to populate initial data
# Usage: ./trigger-ingestion.sh

cd terraform

FUNCTION_NAME=$(terraform output -raw ingestion_lambda_name)
REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-east-1")

echo "Triggering ingestion Lambda: $FUNCTION_NAME in region $REGION"
aws lambda invoke --function-name $FUNCTION_NAME --region $REGION response.json

echo ""
echo "Response:"
cat response.json
echo ""

rm response.json

echo ""
echo "✅ Lambda triggered. Check CloudWatch logs for details."
echo "Wait a few seconds, then refresh your frontend."
