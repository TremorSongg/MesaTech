resource "aws_apigatewayv2_api" "main" {
  name          = "mesatech-api"
  protocol_type = "HTTP"

  # Frontend y API comparten el mismo dominio HTTPS -> no hay CORS cross-origin
  cors_configuration {
    allow_origins  = ["*"]
    allow_methods  = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    allow_headers  = ["Authorization", "Content-Type", "Accept"]
    expose_headers = ["*"]
    max_age        = 300
  }

  tags = { Name = "mesatech-api-gateway" }
}

resource "aws_apigatewayv2_authorizer" "jwt" {
  api_id           = aws_apigatewayv2_api.main.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "entra-id-authorizer"

  jwt_configuration {
    issuer   = "https://login.microsoftonline.com/${var.azure_tenant_id}/v2.0"
    audience = ["${var.azure_client_id}"]
  }
}

# Integracion al BFF (rutas /v1 y /v2)
resource "aws_apigatewayv2_integration" "backend" {
  api_id             = aws_apigatewayv2_api.main.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = "http://${aws_eip.backend.public_ip}:8080/"

  request_parameters = {
    "overwrite:path" = "$request.path"
  }

  depends_on = [aws_eip_association.backend]
}

# Integracion al frontend EC2 (ruta $default)
resource "aws_apigatewayv2_integration" "frontend" {
  api_id             = aws_apigatewayv2_api.main.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = "http://${aws_eip.frontend.public_ip}/"

  # Pasar el path original al nginx del EC2
  request_parameters = {
    "overwrite:path" = "$request.path"
  }

  depends_on = [aws_eip_association.frontend]
}

resource "aws_apigatewayv2_route" "v1" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "ANY /v1/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.backend.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
}

resource "aws_apigatewayv2_route" "v2" {
  api_id             = aws_apigatewayv2_api.main.id
  route_key          = "ANY /v2/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.backend.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
}

# Ruta catch-all: sirve el frontend para cualquier path no cubierto por v1/v2
resource "aws_apigatewayv2_route" "frontend_default" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.frontend.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  tags = { Name = "mesatech-apigw-stage" }
}
