import json
import jwt  # pyjwt library
import os
from jwt import InvalidTokenError, ExpiredSignatureError

def lambda_handler(event, context):
    # Extract the JWT token and methodArn (the API Gateway resource ARN)
    token = event.get('authorizationToken')  # JWT token from the Authorization header
    method_arn = event.get('methodArn')  # The ARN of the method being invoked
    
    if not token:
        # If no token is provided, deny access with a custom message
        return generate_policy("user", "Deny", method_arn, "Missing Authorization Token")
    
    # Fetch the JWT secret key from environment variable
    secret = os.getenv('JWT_SECRET_KEY')  # JWT secret key should be stored securely in environment variables
    if not secret:
        # If secret is missing, deny access
        return generate_policy("user", "Deny", method_arn, "JWT_SECRET_KEY not set")

    algorithm = "HS256"  # Algorithm used to sign the JWT (HS256 or RS256)

    try:
        # Decode and verify the JWT token
        payload = jwt.decode(token, secret, algorithms=[algorithm], options={"require": ["exp", "sub"]})
        
        # Check for specific claims (e.g., 'scope') in the payload
        if payload.get("scope") != "payment:process":
            return generate_policy("user", "Deny", method_arn, "Invalid scope")
        
        # If all checks pass, allow the request by generating an Allow policy
        return generate_policy("user", "Allow", method_arn)
    
    except ExpiredSignatureError:
        # If token has expired, deny access with a message
        return generate_policy("user", "Deny", method_arn, "Token has expired")
    
    except InvalidTokenError:
        # If token is invalid, deny access with a message
        return generate_policy("user", "Deny", method_arn, "Invalid token")
    
def generate_policy(principal_id, effect, resource, message=None):
    """Helper function to generate IAM policy"""
    auth_response = {
        "principalId": principal_id,
        "policyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Action": "execute-api:Invoke",
                    "Effect": effect,
                    "Resource": resource
                }
            ]
        }
    }
    
    # Optionally include a message for debugging or additional context
    if message:
        auth_response['message'] = message

    return auth_response
