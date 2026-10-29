# Elastic IPs de las EC2 que se alcanzan desde fuera de la VPC:
#  - frontend y BFF: destinos de API Gateway (el EIP existe antes que la instancia)
#  - rabbitmq: consola de administracion y SSH con IP estable
# Catalogo y Solicitudes solo reciben trafico del BFF por IP privada (no necesitan EIP).

resource "aws_eip" "frontend" {
  domain = "vpc"
  tags   = { Name = "mesatech-eip-frontend" }
}

resource "aws_eip" "bff" {
  domain = "vpc"
  tags   = { Name = "mesatech-eip-bff" }
}

resource "aws_eip" "rabbitmq" {
  domain = "vpc"
  tags   = { Name = "mesatech-eip-rabbitmq" }
}

resource "aws_eip_association" "frontend" {
  instance_id   = aws_instance.frontend.id
  allocation_id = aws_eip.frontend.id
}

resource "aws_eip_association" "bff" {
  instance_id   = aws_instance.bff.id
  allocation_id = aws_eip.bff.id
}

resource "aws_eip_association" "rabbitmq" {
  instance_id   = aws_instance.rabbitmq.id
  allocation_id = aws_eip.rabbitmq.id
}
