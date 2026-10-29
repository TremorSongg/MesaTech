output "api_gateway_url" {
  description = "URL HTTPS de la app (API Gateway): frontend y API bajo el mismo dominio"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "azure_redirect_uri" {
  description = "Registrar esta URI en Entra ID (Authentication > Redirect URIs, plataforma SPA)"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

# Inventario para la prueba P1 y el informe: instance ID, nombre, IP privada y proceso desplegado
output "inventario_ec2" {
  description = "EC2 desplegadas"
  value = {
    A_catalogo = {
      nombre      = aws_instance.catalogo.tags["Name"]
      instance_id = aws_instance.catalogo.id
      ip_privada  = aws_instance.catalogo.private_ip
      proceso     = "ms-catalogo :8082 (publicador)"
    }
    B_solicitudes = {
      nombre      = aws_instance.solicitudes.tags["Name"]
      instance_id = aws_instance.solicitudes.id
      ip_privada  = aws_instance.solicitudes.private_ip
      proceso     = "ms-solicitudes :8081 (consumidor)"
    }
    C_rabbitmq = {
      nombre      = aws_instance.rabbitmq.tags["Name"]
      instance_id = aws_instance.rabbitmq.id
      ip_privada  = aws_instance.rabbitmq.private_ip
      ip_publica  = aws_eip.rabbitmq.public_ip
      proceso     = "RabbitMQ en Docker :5672/:15672"
    }
    BFF = {
      nombre      = aws_instance.bff.tags["Name"]
      instance_id = aws_instance.bff.id
      ip_privada  = aws_instance.bff.private_ip
      ip_publica  = aws_eip.bff.public_ip
      proceso     = "bff :8080"
    }
    Frontend = {
      nombre      = aws_instance.frontend.tags["Name"]
      instance_id = aws_instance.frontend.id
      ip_privada  = aws_instance.frontend.private_ip
      ip_publica  = aws_eip.frontend.public_ip
      proceso     = "nginx (React) :80"
    }
  }
}

output "inventario_rds" {
  description = "Instancias RDS (identificador, endpoint y base)"
  value = {
    catalogo = {
      identificador = aws_db_instance.catalogo.identifier
      endpoint      = aws_db_instance.catalogo.address
      base          = var.catalogo_db_name
      usuario_app   = var.catalogo_db_app_user
    }
    solicitudes = {
      identificador = aws_db_instance.solicitudes.identifier
      endpoint      = aws_db_instance.solicitudes.address
      base          = var.solicitudes_db_name
      usuario_app   = var.solicitudes_db_app_user
    }
  }
}

output "rabbitmq_consola" {
  description = "Consola de administracion (solo desde las IPs de admin_cidrs)"
  value       = "http://${aws_eip.rabbitmq.public_ip}:15672"
}

output "ssh" {
  description = "Comandos SSH (usuario ubuntu en las EC2 nuevas, ec2-user en el frontend)"
  value = {
    catalogo    = "ssh -i Credenciales/labsuser.pem ubuntu@${aws_instance.catalogo.public_ip}"
    solicitudes = "ssh -i Credenciales/labsuser.pem ubuntu@${aws_instance.solicitudes.public_ip}"
    rabbitmq    = "ssh -i Credenciales/labsuser.pem ubuntu@${aws_eip.rabbitmq.public_ip}"
    bff         = "ssh -i Credenciales/labsuser.pem ubuntu@${aws_eip.bff.public_ip}"
    frontend    = "ssh -i Credenciales/labsuser.pem ec2-user@${aws_eip.frontend.public_ip}"
  }
}
