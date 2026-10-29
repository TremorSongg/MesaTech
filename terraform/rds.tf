# Dos instancias RDS independientes (no dos esquemas en una instancia).
# Sin acceso publico, en subnets privadas, accesibles solo desde la EC2 propietaria.

resource "aws_db_instance" "catalogo" {
  identifier     = "mesatech-rds-catalogo"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.rds_instance_class

  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = var.catalogo_db_name
  username = var.rds_master_user
  password = var.catalogo_db_master_password
  port     = 3306

  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds_catalogo.id]
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true

  tags = { Name = "mesatech-rds-catalogo" }
}

resource "aws_db_instance" "solicitudes" {
  identifier     = "mesatech-rds-solicitudes"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.rds_instance_class

  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = var.solicitudes_db_name
  username = var.rds_master_user
  password = var.solicitudes_db_master_password
  port     = 3306

  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds_solicitudes.id]
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true

  tags = { Name = "mesatech-rds-solicitudes" }
}
