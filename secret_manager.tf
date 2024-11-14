resource "aws_secretsmanager_secret" "jwt_secret" {
  name        = "jwt-secret-key"
  description = "JWT Secret Key for Lambda Authorizer"
}

resource "aws_secretsmanager_secret_version" "jwt_secret_value" {
  secret_id = aws_secretsmanager_secret.jwt_secret.id
  secret_string = jsonencode({
    JWT_SECRET_KEY = "your_secret_key" # Store the actual JWT secret key here
  })
}
