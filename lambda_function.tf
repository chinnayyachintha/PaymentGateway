# Define the Lambda Authorizer for API Gateway
resource "aws_lambda_function" "lambda_authorizer" {
  filename      = "lambda_files/lambda_authorizer.zip" # Path to your Lambda Authorizer code
  function_name = "PaymentGatewayLambdaAuthorizer"
  handler       = "lambda_authorizer.lambda_handler"     # Ensure this matches the function name in your Lambda code
  runtime       = "python3.8"                            # You can update to a newer Python version if desired
  role          = aws_iam_role.lambda_execution_role.arn # IAM role for Lambda execution

  environment {
    variables = {
      JWT_SECRET_KEY = aws_secretsmanager_secret.jwt_secret.arn # Reference the Secret ARN for  JWT secret key
    }
  }

  # Ensure Lambda has permissions to write logs to CloudWatch
  depends_on = [aws_iam_role.lambda_execution_role]
}


# Define the Lambda function for processing payments
resource "aws_lambda_function" "process_payment_lambda" {
  filename      = "lambda_files/Encrypt-ProcessPayment.zip" # Path to your Lambda ZIP file
  function_name = "Encrypt-ProcessPayment"
  handler       = "Encrypt-ProcessPayment.lambda_handler" # Update this with the correct handler function name
  runtime       = "python3.8"                             # You can update the runtime if needed (e.g., python3.9 or newer versions)
  role          = aws_iam_role.lambda_execution_role.arn  # IAM role for Lambda execution

  environment {
    variables = {
      JWT_SECRET_KEY = aws_secretsmanager_secret.jwt_secret.arn # Reference to Secrets Manager for JWT secret key
    }
  }

  # Ensure Lambda has permissions to write logs to CloudWatch
  depends_on = [aws_iam_role.lambda_execution_role]
}
