# Frontend Dashboard

## Overview
Minimal SPA that displays 7-day history of daily top stock movers.

## Features
- Fetches data from GET /movers API endpoint
- Table view with Date, Ticker, % Change, Closing Price
- 🟢 Green for positive gains
- 🔴 Red for negative losses
- Responsive design

## Deployment

1. Deploy infrastructure first:
   ```bash
   cd ../terraform
   terraform apply
   ```

2. Get API endpoint from Terraform outputs:
   ```bash
   terraform output api_endpoint
   ```

3. Deploy frontend to S3:
   ```bash
   cd ../frontend
   ./deploy.sh <api-endpoint-url>
   ```

4. Access the dashboard at the URL shown in output

## Tech Stack
- Plain HTML/CSS/JavaScript (no build step required)
- Hosted on S3 Static Website Hosting
