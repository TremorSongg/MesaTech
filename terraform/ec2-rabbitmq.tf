# EC2 C: broker RabbitMQ. Se crea VACIA a proposito (solo Ubuntu 24.04 y hostname):
# la EP2 evalua que Docker, Compose y RabbitMQ se instalen desde cero en esta maquina y se
# documente cada comando. Pasos en rabbitmq/README.md y scripts de apoyo en rabbitmq/.
resource "aws_instance" "rabbitmq" {
  ami                    = data.aws_ami.ubuntu_2404.id
  instance_type          = var.rabbit_instance_type
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.rabbitmq.id]
  key_name               = aws_key_pair.mesatech.key_name
  iam_instance_profile   = aws_iam_instance_profile.main.name

  user_data = <<-EOT
    #!/bin/bash
    hostnamectl set-hostname mesatech-rabbitmq
  EOT

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = { Name = "mesatech-rabbitmq" }
}
