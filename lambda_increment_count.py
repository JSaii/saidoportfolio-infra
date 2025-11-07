import boto3
import json
from datetime import datetime, timezone

dynamodb = boto3.client("dynamodb")

def lambda_handler(event, context):
    TABLE_NAME = "VisitorCount"
    ITEM_ID = "usercount"
    ip = event["requestContext"]["identity"]["sourceIp"]
    now = datetime.now(timezone.utc)

    # Get last visit for this IP
    ip_item = dynamodb.get_item(
        TableName=TABLE_NAME,
        Key={"id": {"S": f"ip#{ip}"}}
    )

    # Get current count (always)
    current_item = dynamodb.get_item(
        TableName=TABLE_NAME,
        Key={"id": {"S": ITEM_ID}}
    )
    current_count = int(current_item["Item"]["count"]["N"]) if "Item" in current_item else 0

    # If this IP visited within 60s → don't increment
    if "Item" in ip_item:
        last = datetime.fromisoformat(ip_item["Item"]["lastUpdated"]["S"])
        if (now - last).total_seconds() < 60:
            return {
                "statusCode": 200,
                "headers": {"Content-Type": "application/json",
                            "Access-Control-Allow-Origin": "*",
                            "Access-Control-Allow-Headers": "*",
                            "Access-Control-Allow-Methods": "GET,OPTIONS"},
                "body": json.dumps({
                    "message": "Already counted recently",
                    "count": current_count,
                    "timestamp": now.isoformat()
                })
            }

    # Otherwise increment counter
    resp = dynamodb.update_item(
        TableName=TABLE_NAME,
        Key={"id": {"S": ITEM_ID}},
        UpdateExpression="ADD #c :inc SET lastUpdated = :t",
        ExpressionAttributeNames={"#c": "count"},
        ExpressionAttributeValues={
            ":inc": {"N": "1"},
            ":t": {"S": now.isoformat()}
        },
        ReturnValues="UPDATED_NEW"
    )

    # Record this IP’s timestamp
    dynamodb.put_item(
        TableName=TABLE_NAME,
        Item={
            "id": {"S": f"ip#{ip}"},
            "lastUpdated": {"S": now.isoformat()}
        }
    )

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Headers": "*",
                    "Access-Control-Allow-Methods": "GET,OPTIONS"},
        "body": json.dumps({
            "newCount": int(resp["Attributes"]["count"]["N"]),
            "timestamp": now.isoformat()
        })
    }
