# EC2 BFF: seguridad y coordinacion de la EP1. No accede a RDS ni a RabbitMQ.
resource "aws_instance" "bff" {
  ami                    = data.aws_ami.ubuntu_2404.id
  instance_type          = var.app_instance_type
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.bff.id]
  key_name               = aws_key_pair.mesatech.key_name
  iam_instance_profile   = aws_iam_instance_profile.main.name

  user_data = sensitive(templatefile("${path.module}/templates/springboot-userdata.sh.tpl", {
    service_name  = "bff"
    service_dir   = "bff"
    hostname      = "mesatech-bff"
    port          = 8080
    heap_mb       = 512
    github_repo   = var.github_repo
    github_branch = var.github_branch

    db_setup           = false
    db_host            = ""
    db_name            = ""
    db_master_user     = ""
    db_master_password = ""
    db_app_user        = ""
    db_app_password    = ""

    env_file = join("\n", [
      "SPRING_PROFILES_ACTIVE=prod",
      "SOLICITUDES_URL=http://${aws_instance.solicitudes.private_ip}:8081",
      "CATALOGO_URL=http://${aws_instance.catalogo.private_ip}:8082",
      "ENTRA_ISSUER_URI=https://login.microsoftonline.com/${var.azure_tenant_id}/v2.0",
      "ENTRA_AUDIENCE=${var.azure_client_id}",
      "CORS_ALLOWED_ORIGIN=${aws_apigatewayv2_api.main.api_endpoint}",
    ])
  }))

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = { Name = "mesatech-bff" }
}
