import os
import json
import boto3
from datetime import datetime, timedelta
from decimal import Decimal

DYNAMODB_TABLE = os.environ['DYNAMODB_TABLE']
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(DYNAMODB_TABLE)

def decimal_to_float(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError

def handler(event, context):
    try:
        dates = [(datetime.now() - timedelta(days=i)).strftime('%Y-%m-%d') for i in range(1, 31)]
        
        items = []
        for date in dates:
            try:
                response = table.get_item(Key={'date': date})
                if 'Item' in response:
                    items.append(response['Item'])
            except Exception as e:
                print(f'Error fetching {date}: {str(e)}')
                continue
        
        items.sort(key=lambda x: x['date'], reverse=True)
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(items, default=decimal_to_float)
        }
    except Exception as e:
        print(f'Error: {str(e)}')
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': 'Internal server error'})
        }
