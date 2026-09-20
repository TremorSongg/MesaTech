# Elastic IPs para frontend y backend
# Se asignan antes de crear los EC2 para poder inyectar las IPs en los user_data

resource "aws_eip" "frontend" {
  domain = "vpc"
  tags   = { Name = "mesatech-eip-frontend" }
}

resource "aws_eip" "backend" {
  domain = "vpc"
  tags   = { Name = "mesatech-eip-backend" }
}

resource "aws_eip_association" "frontend" {
  instance_id   = aws_instance.frontend.id
  allocation_id = aws_eip.frontend.id
}

resource "aws_eip_association" "backend" {
  instance_id   = aws_instance.backend.id
  allocation_id = aws_eip.backend.id
}
