variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "account_id" {
  description = "AWS Account ID"
  default     = "073701333896"
}

variable "github_repo" {
  description = "URL del repositorio GitHub"
  default     = "https://github.com/TremorSongg/MesaTech"
}

variable "azure_client_id" {
  description = "Client ID de la app api-cloud-native en Azure AD (usado para scope y JWT audience)"
}

variable "azure_tenant_id" {
  description = "Tenant ID de Azure AD"
}

variable "db_password" {
  description = "Contraseña de PostgreSQL"
  sensitive   = true
}

variable "db_name" {
  default = "mesatech"
}

variable "db_user" {
  default = "mesatech"
}

variable "frontend_instance_type" {
  default = "t3.micro"
}

variable "backend_instance_type" {
  default = "t3.medium"
}

variable "db_instance_type" {
  default = "t3.micro"
}

variable "ssh_public_key" {
  description = "Clave publica SSH para acceder a los EC2"
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD0o4xaEvb3Fh6P/B7bUtUO/TJqfnf32H48ctX37pWSop+3AY6eyS7nQ4zRYvpIOh21G75dbIlwUxW9/YBPhNMuejg1AsbKbaNh927iNbzkcW59EIZhDwuvIt56to+ZKiysw7wEfLAc4TgvMScSa4jI3asCP1p2tqg9NSek2Uz/TLS0hpTEkqCutD0710I2XUZG6t+rmiLl2o3yl2Po7PpJRR7cds1EIgtrvJ+AmFsD+bTKmc2dXljOBeReuBW3WeF66O7hSaK4Jn7kqPNaJDmHusTS6zt2sRSXnqqCk8Vb4oQdfqkP25i4KVnvkbS6ZyIYzSKLYcQx/d9X8Z4HWdbJ"
}
