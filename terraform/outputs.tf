output "frontend_url" {
  description = "URL de la app (API Gateway HTTPS) - usar esta para todo"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "frontend_ip" {
  description = "IP publica del frontend — actualizar en Azure AD > Redirect URIs si cambia"
  value       = "http://${aws_eip.frontend.public_ip}"
}

output "azure_redirect_uri" {
  description = "Registrar esta URI en Azure AD (Authentication > Redirect URIs)"
  value       = "http://${aws_eip.frontend.public_ip}"
}

output "api_gateway_url" {
  description = "URL del API Gateway (misma que el frontend)"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "backend_url" {
  description = "URL directa del backend (solo debug)"
  value       = "http://${aws_eip.backend.public_ip}:8080"
}

output "db_private_ip" {
  description = "IP privada del EC2 de base de datos"
  value       = aws_instance.db.private_ip
}

output "ssh_frontend" {
  description = "SSH al EC2 frontend"
  value       = "ssh -i credenciales/labsuser.pem ec2-user@${aws_eip.frontend.public_ip}"
}

output "ssh_backend" {
  description = "SSH al EC2 backend"
  value       = "ssh -i credenciales/labsuser.pem ec2-user@${aws_eip.backend.public_ip}"
}

output "ssh_db" {
  description = "SSH al EC2 base de datos"
  value       = "ssh -i credenciales/labsuser.pem ec2-user@${aws_instance.db.public_ip}"
}
