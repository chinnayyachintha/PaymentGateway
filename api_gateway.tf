# Define your API Gateway REST API
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
  authorization = "CUSTOM"                                        # Using Custom Lambda Authorizer for authorization
  authorizer_id = aws_api_gateway_authorizer.lambda_authorizer.id # Referencing the Lambda Authorizer
}

# Set up the integration (e.g., Lambda) for handling the POST request
resource "aws_api_gateway_integration" "post_process_payment_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.process_payment.id
  http_method             = aws_api_gateway_method.post_process_payment.http_method
  type                    = "AWS_PROXY"                                           # Assuming Lambda Proxy Integration
  uri                     = aws_lambda_function.process_payment_lambda.invoke_arn # Replace with your Lambda ARN
  integration_http_method = "POST"
}

# Create the API Gateway deployment
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "dev" # Your stage name
  depends_on  = [aws_api_gateway_integration.post_process_payment_integration]
}

# Define the API Gateway stage
resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "dev"
}

# Create a Custom Domain for HTTPS access in API Gateway
resource "aws_api_gateway_domain_name" "custom_domain" {
  domain_name              = "example.com"
  regional_certificate_arn = aws_acm_certificate.api_gateway_cert.arn
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

# Create the SSL Certificate in AWS Certificate Manager (ACM)
resource "aws_acm_certificate" "api_gateway_cert" {
  domain_name       = "example.com"               # Primary domain
  validation_method = "DNS"

  # Add an alternative name (optional, e.g., www.example.com)
  subject_alternative_names = ["www.example.com"]

  lifecycle {
    create_before_destroy = true
  }
}

# DNS Validation record for ACM in Route 53
resource "aws_route53_record" "cert_validation" {
  depends_on = [aws_acm_certificate.api_gateway_cert]

  zone_id = "Z3M3LMPEXAMPLE"  # Replace with your actual Route 53 hosted zone ID for example.com

  # Use for_each to iterate over domain_validation_options set for ACM certificate DNS validation
  for_each = { for idx, val in aws_acm_certificate.api_gateway_cert.domain_validation_options : idx => val }

  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  records = [each.value.resource_record_value]
  ttl     = 60
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
