#!/bin/bash

# Deploy frontend to S3
# Usage: ./deploy.sh <api-endpoint-url>

if [ -z "$1" ]; then
    echo "Usage: ./deploy.sh <api-endpoint-url>"
    echo "Example: ./deploy.sh https://abc123.execute-api.us-east-1.amazonaws.com"
    exit 1
fi

API_ENDPOINT=$1

# Update API endpoint in index.html
sed "s|API_ENDPOINT_PLACEHOLDER|$API_ENDPOINT|g" index.html > index_deploy.html

# Get S3 bucket name from Terraform output
cd ../terraform
BUCKET_NAME=$(terraform output -raw frontend_url | cut -d'.' -f1 | cut -d'/' -f3)

# Upload to S3
aws s3 cp ../frontend/index_deploy.html s3://$BUCKET_NAME/index.html --content-type "text/html"

# Clean up
rm ../frontend/index_deploy.html

echo "Frontend deployed to S3"
echo "URL: http://$(terraform output -raw frontend_url)"
