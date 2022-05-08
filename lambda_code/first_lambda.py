import json

def lambda_handler(event, context):
    print('Message from SQS queue:'+str(event['Records'][0]['body']))
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }