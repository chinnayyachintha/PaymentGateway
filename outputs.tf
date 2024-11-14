# Output the full API Gateway URL for the /payment-gateway/process-payment endpoint with the custom domain
output "full_api_url" {
  value = "https://${aws_api_gateway_domain_name.custom_domain.domain_name}/${aws_api_gateway_stage.api_stage.stage_name}/payment-gateway/process-payment"
  description = "The full URL for the /payment-gateway/process-payment endpoint with custom domain and stage"
}

# Output the full default API Gateway URL for the /payment-gateway/process-payment endpoint (without custom domain)
output "full_default_api_url" {
  value = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${aws_api_gateway_stage.api_stage.stage_name}/payment-gateway/process-payment"
  description = "The full default URL for the /payment-gateway/process-payment endpoint without custom domain"
}
