resource "aws_instance" "frontend" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.frontend_instance_type
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.frontend.id]
  key_name               = aws_key_pair.mesatech.key_name
  iam_instance_profile   = aws_iam_instance_profile.main.name

  user_data = templatefile("${path.module}/templates/frontend-userdata.sh.tpl", {
    github_repo     = var.github_repo
    azure_client_id = var.azure_client_id
    azure_tenant_id = var.azure_tenant_id
    api_gateway_url = aws_apigatewayv2_api.main.api_endpoint
    frontend_ip     = aws_eip.frontend.public_ip
  })

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  depends_on = [aws_apigatewayv2_stage.default]

  tags = { Name = "mesatech-frontend" }
}
