resource "aws_key_pair" "mesatech" {
  key_name   = "mesatech-key"
  public_key = var.ssh_public_key
}
