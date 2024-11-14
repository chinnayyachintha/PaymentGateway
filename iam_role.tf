#  Define IAM Role for Lambda Function
resource "aws_iam_role" "lambda_execution_role" {
  name = "Payment_Gateway_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
}

#  Define Consolidated IAM Policy
resource "aws_iam_policy" "lambda_execution_policy" {
  name        = "lambda-execution-policy"
  description = "Policy for Lambda execution including CloudWatch logs, DynamoDB access, and Secrets Manager access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # CloudWatch logs permissions
      {
        Action   = "logs:*"
        Resource = "*"
        Effect   = "Allow"
      },
      # DynamoDB permissions
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = "*"
        Effect   = "Allow"
      },
      # Secrets Manager permissions
      {
        Action   = "secretsmanager:GetSecretValue"
        Resource = "*"
        Effect   = "Allow"
      }
    ]
  })
}

#  Attach the Consolidated IAM Policy to Lambda Execution Role
resource "aws_iam_role_policy_attachment" "lambda_execution_role_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_execution_policy.arn
}
