# Regla general: los origenes se expresan como otro security group (no como IP), salvo
# el acceso administrativo, que se limita a las IPs /32 de var.admin_cidrs.

# ---------- Frontend (nginx) ----------
resource "aws_security_group" "frontend" {
  name        = "mesatech-sg-frontend"
  description = "Frontend EC2: HTTP (API Gateway) + SSH administrativo"
  vpc_id      = aws_vpc.main.id

  # API Gateway (HTTP API) no tiene IPs de origen fijas ni se conecta por red privada
  ingress {
    description = "HTTP desde API Gateway"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH administrativo"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "mesatech-sg-frontend" }
}

# ---------- BFF ----------
resource "aws_security_group" "bff" {
  name        = "mesatech-sg-bff"
  description = "BFF EC2: 8080 desde API Gateway + SSH administrativo"
  vpc_id      = aws_vpc.main.id

  # El BFF valida el JWT de Entra ID por si mismo, aunque el puerto este abierto a API Gateway
  ingress {
    description = "BFF desde API Gateway"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH administrativo"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "mesatech-sg-bff" }
}

# ---------- EC2 A: Catalogo (publicador) ----------
resource "aws_security_group" "catalogo" {
  name        = "mesatech-sg-catalogo"
  description = "Catalogo EC2: 8082 solo desde el BFF + SSH administrativo"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "API de Catalogo desde el BFF"
    from_port       = 8082
    to_port         = 8082
    protocol        = "tcp"
    security_groups = [aws_security_group.bff.id]
  }

  ingress {
    description = "SSH administrativo"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "mesatech-sg-catalogo" }
}

# ---------- EC2 B: Solicitudes (consumidor) ----------
resource "aws_security_group" "solicitudes" {
  name        = "mesatech-sg-solicitudes"
  description = "Solicitudes EC2: 8081 solo desde el BFF + SSH administrativo"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "API de Solicitudes desde el BFF"
    from_port       = 8081
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.bff.id]
  }

  ingress {
    description = "SSH administrativo"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "mesatech-sg-solicitudes" }
}

# ---------- EC2 C: RabbitMQ ----------
resource "aws_security_group" "rabbitmq" {
  name        = "mesatech-sg-rabbitmq"
  description = "RabbitMQ EC2: AMQP solo desde Catalogo y Solicitudes; consola y SSH solo administrativos"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "AMQP 5672 desde Catalogo (publicador)"
    from_port       = 5672
    to_port         = 5672
    protocol        = "tcp"
    security_groups = [aws_security_group.catalogo.id]
  }

  ingress {
    description     = "AMQP 5672 desde Solicitudes (consumidor)"
    from_port       = 5672
    to_port         = 5672
    protocol        = "tcp"
    security_groups = [aws_security_group.solicitudes.id]
  }

  ingress {
    description = "Consola de administracion 15672 (IP administrativa /32)"
    from_port   = 15672
    to_port     = 15672
    protocol    = "tcp"
    cidr_blocks = var.admin_cidrs
  }

  ingress {
    description = "SSH administrativo"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "mesatech-sg-rabbitmq" }
}

# ---------- RDS: cada una acepta 3306 solo desde la EC2 de su microservicio ----------
resource "aws_security_group" "rds_catalogo" {
  name        = "mesatech-sg-rds-catalogo"
  description = "RDS Catalogo: MySQL 3306 solo desde la EC2 de Catalogo"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL desde EC2 Catalogo"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.catalogo.id]
  }

  tags = { Name = "mesatech-sg-rds-catalogo" }
}

resource "aws_security_group" "rds_solicitudes" {
  name        = "mesatech-sg-rds-solicitudes"
  description = "RDS Solicitudes: MySQL 3306 solo desde la EC2 de Solicitudes"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL desde EC2 Solicitudes"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.solicitudes.id]
  }

  tags = { Name = "mesatech-sg-rds-solicitudes" }
}
