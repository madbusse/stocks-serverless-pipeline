# Stock Retrieval Lambda

## Overview
Lambda function that serves the GET /movers API endpoint, returning the last 7 days of top mover records from DynamoDB.

## Endpoint
`GET /movers`

## Response Format
```json
[
  { "date": "2025-01-01", "ticker": "NVDA", "percentChange": 4.32, "closingPrice": 134.50 },
  { "date": "2024-12-31", "ticker": "TSLA", "percentChange": -3.10, "closingPrice": 248.00 }
]
```

## Logic
1. Query DynamoDB for last 7 days (yesterday through 7 days ago)
2. Sort by date (most recent first)
3. Return as JSON array

## Error Handling
- Returns 500 status on DynamoDB errors
- Handles missing data gracefully (partial results)
- CORS headers included for frontend access

## Environment Variables
- `DYNAMODB_TABLE`: DynamoDB table name
