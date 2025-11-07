resource "aws_api_gateway_rest_api" "visitor_api" {
    name = "saidoportfolio-visitor-counter-api"
    description = "Public API endpoint for visitor counter Lambda"
}

resource "aws_api_gateway_resource" "visitor_root" {
    rest_api_id = aws_api_gateway_rest_api.visitor_api.id
    parent_id = aws_api_gateway_rest_api.visitor_api.root_resource_id
    path_part = "count"
}

resource "aws_api_gateway_method" "visitor_method" {
    rest_api_id = aws_api_gateway_rest_api.visitor_api.id
    resource_id = aws_api_gateway_resource.visitor_root.id
    http_method = "GET"
    authorization = "NONE"
}

resource "aws_api_gateway_integration" "visitor_api_integration" {
    rest_api_id             = aws_api_gateway_rest_api.visitor_api.id
    resource_id             = aws_api_gateway_resource.visitor_root.id
    http_method             = aws_api_gateway_method.visitor_method.http_method
    integration_http_method = "POST"   # internal AWS Lambda call use POST not GET
    type                    = "AWS_PROXY"
    uri                     = aws_lambda_function.visitor_counter.invoke_arn
}

resource "aws_lambda_permission" "visitor_api_permission" {
    statement_id = "AllowAPIGatewayInvoke"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.visitor_counter.function_name
    principal = "apigateway.amazonaws.com"
    source_arn    = "${aws_api_gateway_rest_api.visitor_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "visitor_deployment" {
  rest_api_id = aws_api_gateway_rest_api.visitor_api.id
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.visitor_api.body))
  } # Trigger deployment when a change occur in "visitor_api"
  depends_on = [aws_api_gateway_integration.visitor_api_integration]
}

resource "aws_api_gateway_stage" "visitor_stage" {
  deployment_id = aws_api_gateway_deployment.visitor_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.visitor_api.id
  stage_name    = "prod"
}

resource "aws_api_gateway_method_settings" "visitor_throttling" {
  rest_api_id = aws_api_gateway_rest_api.visitor_api.id
  stage_name  = aws_api_gateway_stage.visitor_stage.stage_name
  method_path = "*/*"

  settings {
    throttling_burst_limit = 20
    throttling_rate_limit  = 10
  }
}

output "visitor_counter_api_url" {
  description = "Public endpoint for visitor counter API"
  value       = "https://${aws_api_gateway_rest_api.visitor_api.id}.execute-api.us-east-1.amazonaws.com/${aws_api_gateway_stage.visitor_stage.stage_name}/count"
}
