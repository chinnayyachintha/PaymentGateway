# Lambda function that will receive the card data, encrypt it, and 
# then store the encrypted data in DynamoDB

import json
import boto3
import os
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend
import base64
from botocore.exceptions import ClientError

# DynamoDB client
dynamodb = boto3.client('dynamodb')
table_name = "EncryptedCardData"  # The DynamoDB table to store the encrypted data

# Fetch the secret key from environment variable (or use Secrets Manager if needed)
def encrypt_data(card_data, secret_key):
    # Generate a 128-bit IV (Initialization Vector)
    iv = os.urandom(16)
    
    # Create cipher using AES (you can use another algorithm if desired)
    cipher = Cipher(algorithms.AES(secret_key), modes.CBC(iv), backend=default_backend())
    encryptor = cipher.encryptor()

    # Pad the card data to be a multiple of the block size (16 bytes for AES)
    pad_length = 16 - len(card_data) % 16
    padded_data = card_data + (chr(pad_length) * pad_length).encode()

    # Encrypt the card data
    encrypted_data = encryptor.update(padded_data) + encryptor.finalize()

    # Return the base64-encoded encrypted data along with the IV
    return base64.b64encode(iv + encrypted_data).decode('utf-8')

# Lambda handler function
def lambda_handler(event, context):
    try:
        # Assuming the event contains the card data (e.g., in the body)
        body = json.loads(event['body'])
        card_data = body['card_data']  # The card data to be encrypted
        
        # Fetch the secret key (This could also come from Secrets Manager if needed)
        secret_key = os.environ['JWT_SECRET_KEY']  # For simplicity, using the same secret key, update if needed

        # Encrypt the card data
        encrypted_card_data = encrypt_data(card_data, secret_key)

        # Store encrypted data in DynamoDB
        response = dynamodb.put_item(
            TableName=table_name,
            Item={
                'card_id': {'S': body['card_id']},  # Assuming card_id is passed in the request
                'encrypted_data': {'S': encrypted_card_data},
            }
        )

        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Card data encrypted and stored successfully'})
        }

    except ClientError as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': f"Error storing encrypted data: {str(e)}"})
        }
