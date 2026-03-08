import os
import json
import boto3
import time
from datetime import datetime, timedelta
from urllib import request, error
from decimal import Decimal

WATCHLIST = ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'TSLA', 'NVDA']
FINNHUB_API_KEY = os.environ['FINNHUB_API_KEY']
DYNAMODB_TABLE = os.environ['DYNAMODB_TABLE']

# US Market holidays 2024-2025 (NYSE)
MARKET_HOLIDAYS = [
    '2024-01-01', '2024-01-15', '2024-02-19', '2024-03-29', '2024-05-27',
    '2024-06-19', '2024-07-04', '2024-09-02', '2024-11-28', '2024-12-25',
    '2025-01-01', '2025-01-20', '2025-02-17', '2025-04-18', '2025-05-26',
    '2025-06-19', '2025-07-04', '2025-09-01', '2025-11-27', '2025-12-25'
]

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(DYNAMODB_TABLE)

def is_market_open():
    now = datetime.now()
    date_str = now.strftime('%Y-%m-%d')
    
    # Check if weekend
    if now.weekday() >= 5:  # Saturday=5, Sunday=6
        return False
    
    # Check if holiday
    if date_str in MARKET_HOLIDAYS:
        return False
    
    return True

def fetch_with_retry(url, max_retries=3):
    for attempt in range(max_retries):
        try:
            with request.urlopen(url, timeout=10) as response:
                if response.status == 429:
                    wait_time = 2 ** attempt
                    print(f'Rate limit hit, retrying in {wait_time}s')
                    time.sleep(wait_time)
                    continue
                return json.loads(response.read())
        except error.HTTPError as e:
            if e.code == 429 and attempt < max_retries - 1:
                wait_time = 2 ** attempt
                print(f'Rate limit (429), retrying in {wait_time}s')
                time.sleep(wait_time)
            else:
                raise
        except Exception as e:
            if attempt < max_retries - 1:
                time.sleep(1)
            else:
                raise
    raise Exception('Max retries exceeded')

def handler(event, context):
    # Check if market is open
    if not is_market_open():
        print('Market is closed (weekend or holiday). Skipping execution.')
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Market closed, skipped execution'})
        }
    
    yesterday = (datetime.now() - timedelta(days=1)).strftime('%Y-%m-%d')
    movers = []
    failed_tickers = []
    
    for ticker in WATCHLIST:
        try:
            url = f'https://finnhub.io/api/v1/quote?symbol={ticker}&token={FINNHUB_API_KEY}'
            data = fetch_with_retry(url)
            
            open_price = data.get('o')
            close_price = data.get('c')
            
            if not open_price or not close_price or open_price <= 0:
                print(f'Invalid data for {ticker}: open={open_price}, close={close_price}')
                failed_tickers.append(ticker)
                continue
                
            percent_change = ((close_price - open_price) / open_price) * 100
            movers.append({
                'ticker': ticker,
                'percentChange': Decimal(str(round(percent_change, 2))),
                'closingPrice': Decimal(str(round(close_price, 2))),
                'absChange': abs(percent_change)
            })
            print(f'{ticker}: {percent_change:.2f}%')
        except Exception as e:
            print(f'Error fetching {ticker}: {str(e)}')
            failed_tickers.append(ticker)
            continue
    
    if not movers:
        error_msg = f'No valid data fetched. Failed tickers: {failed_tickers}'
        print(error_msg)
        return {'statusCode': 500, 'body': error_msg}
    
    top_mover = max(movers, key=lambda x: x['absChange'])
    
    try:
        table.put_item(Item={
            'date': yesterday,
            'ticker': top_mover['ticker'],
            'percentChange': top_mover['percentChange'],
            'closingPrice': top_mover['closingPrice']
        })
        print(f'Stored top mover: {top_mover["ticker"]} ({top_mover["percentChange"]}%)')
    except Exception as e:
        print(f'DynamoDB error: {str(e)}')
        return {'statusCode': 500, 'body': f'Failed to store data: {str(e)}'}
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'date': yesterday,
            'topMover': top_mover['ticker'],
            'percentChange': float(top_mover['percentChange']),
            'successfulTickers': len(movers),
            'failedTickers': failed_tickers
        })
    }
