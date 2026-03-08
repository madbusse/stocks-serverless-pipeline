# Stock Ingestion Lambda

## Overview
Daily Lambda function that fetches stock data from Finnhub API and identifies the top mover by absolute % change.

## Watchlist
- AAPL (Apple)
- MSFT (Microsoft)
- GOOGL (Google)
- AMZN (Amazon)
- TSLA (Tesla)
- NVDA (NVIDIA)

## Logic
1. Fetch previous day's open and close prices for each ticker
2. Calculate: `% Change = ((Close - Open) / Open) * 100`
3. Identify ticker with highest absolute % change
4. Store result in DynamoDB

## Trigger
EventBridge cron: Daily at 4:15 PM ET (9:15 PM UTC)

## Environment Variables
- `DYNAMODB_TABLE`: Target DynamoDB table name
- `FINNHUB_API_KEY`: Finnhub API key

## API Limit
Finnhub free tier: 60 requests/day (6 tickers = 6 requests/day)
