# EC2 A: Catalogo + publicador de eventos. Usa exclusivamente la RDS de Catalogo.
resource "aws_instance" "catalogo" {
  ami                    = data.aws_ami.ubuntu_2404.id
  instance_type          = var.app_instance_type
  subnet_id              = aws_subnet.public_2.id
  vpc_security_group_ids = [aws_security_group.catalogo.id]
  key_name               = aws_key_pair.mesatech.key_name
  iam_instance_profile   = aws_iam_instance_profile.main.name

  user_data = sensitive(templatefile("${path.module}/templates/springboot-userdata.sh.tpl", {
    service_name  = "ms-catalogo"
    service_dir   = "ms-catalogo"
    hostname      = "mesatech-catalogo"
    port          = 8082
    heap_mb       = 512
    github_repo   = var.github_repo
    github_branch = var.github_branch

    db_setup           = true
    db_host            = aws_db_instance.catalogo.address
    db_name            = var.catalogo_db_name
    db_master_user     = var.rds_master_user
    db_master_password = var.catalogo_db_master_password
    db_app_user        = var.catalogo_db_app_user
    db_app_password    = var.catalogo_db_app_password

    env_file = join("\n", [
      "SPRING_PROFILES_ACTIVE=prod",
      "DB_URL=jdbc:mysql://${aws_db_instance.catalogo.address}:3306/${var.catalogo_db_name}",
      "DB_USER=${var.catalogo_db_app_user}",
      "DB_PASSWORD=${var.catalogo_db_app_password}",
      "RABBITMQ_HOST=${aws_instance.rabbitmq.private_ip}",
      "RABBITMQ_USER=${var.rabbit_publicador_user}",
      "RABBITMQ_PASSWORD=${var.rabbit_publicador_password}",
      "ENTRA_ISSUER_URI=https://login.microsoftonline.com/${var.azure_tenant_id}/v2.0",
      "ENTRA_AUDIENCE=${var.azure_client_id}",
    ])
  }))

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = { Name = "mesatech-catalogo" }
}
