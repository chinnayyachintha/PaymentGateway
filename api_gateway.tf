# Define the API Gateway REST API
resource "aws_api_gateway_rest_api" "api" {
  name        = "payment-gateway-api"
  description = "API for processing payments securely"
}

# Create the /payment-gateway resource
resource "aws_api_gateway_resource" "payment_gateway" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "payment-gateway"
}

# Create the /process-payment sub-resource under /payment-gateway
resource "aws_api_gateway_resource" "process_payment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.payment_gateway.id
  path_part   = "process-payment"
}

# Define the POST method for the /payment-gateway/process-payment endpoint
resource "aws_api_gateway_method" "post_process_payment" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.process_payment.id
  http_method   = "POST"
  authorization = "CUSTOM"  # Using Custom Lambda Authorizer for authorization
  authorizer_id = aws_api_gateway_authorizer.lambda_authorizer.id  # Referencing the Lambda Authorizer
}

# Set up the integration (Lambda) for handling the POST request
resource "aws_api_gateway_integration" "post_process_payment_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.process_payment.id
  http_method             = aws_api_gateway_method.post_process_payment.http_method
  type                    = "AWS_PROXY"  # Assuming Lambda Proxy Integration
  uri                     = aws_lambda_function.process_payment_lambda.invoke_arn  # Replace with your Lambda ARN
  integration_http_method = "POST"
}

# Create the API Gateway deployment
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "dev"  # Changed stage name to avoid conflict
  depends_on  = [aws_api_gateway_integration.post_process_payment_integration]
}

# Define the API Gateway stage
resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "dev"  # Changed stage name to avoid conflict
}

# Use your existing ACM certificate ARN
resource "aws_api_gateway_domain_name" "custom_domain" {
  domain_name              = "payment.dev.flyflair.com"  # New sub-domain for the API
  regional_certificate_arn = "arn:aws:acm:ca-central-1:017820679929:certificate/8c578eec-1175-4232-b983-80d8982ee9a4"  # Replace with your ACM certificate ARN
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Associate the Custom Domain with the API Gateway Stage
resource "aws_api_gateway_base_path_mapping" "base_path_mapping" {
  domain_name = aws_api_gateway_domain_name.custom_domain.domain_name
  api_id      = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.api_stage.stage_name
}

# Create a DNS record in Route 53 for the new subdomain
resource "aws_route53_record" "api_gateway_record" {
  zone_id = "Z06424622C954HY52QYPT"  # Replace with your actual Route 53 hosted zone ID
  name    = "api.payment.dev.flyflair.com"  # Your sub-domain
  type    = "A"
  alias {
    name                   = aws_api_gateway_domain_name.custom_domain.cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.custom_domain.cloudfront_zone_id
    evaluate_target_health = true
  }
}

# Define the API Gateway Lambda Authorizer
resource "aws_api_gateway_authorizer" "lambda_authorizer" {
  name                             = "Payment-gateway-lambda-authorizer"
  rest_api_id                      = aws_api_gateway_rest_api.api.id
  authorizer_uri                   = aws_lambda_function.lambda_authorizer.invoke_arn
  authorizer_credentials           = aws_iam_role.lambda_execution_role.arn
  authorizer_result_ttl_in_seconds = 300
  identity_source                  = "method.request.header.Authorization"
  type                             = "TOKEN"
}

