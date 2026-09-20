resource "aws_instance" "backend" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.backend_instance_type
  subnet_id              = aws_subnet.public_2.id
  vpc_security_group_ids = [aws_security_group.backend.id]
  key_name               = aws_key_pair.mesatech.key_name
  iam_instance_profile   = aws_iam_instance_profile.main.name

  user_data = templatefile("${path.module}/templates/backend-userdata.sh.tpl", {
    github_repo    = var.github_repo
    db_private_ip  = aws_instance.db.private_ip
    db_name        = var.db_name
    db_user        = var.db_user
    db_password    = var.db_password
    azure_tenant_id = var.azure_tenant_id
    azure_client_id = var.azure_client_id
    api_gateway_url = aws_apigatewayv2_api.main.api_endpoint
  })

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = { Name = "mesatech-backend" }
}
