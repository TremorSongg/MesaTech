variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "github_repo" {
  description = "URL del repositorio GitHub (los EC2 lo clonan al arrancar; debe tener el codigo de la EP2 publicado)"
  default     = "https://github.com/TremorSongg/MesaTech"
}

variable "github_branch" {
  description = "Rama a desplegar"
  default     = "main"
}

# ---------- Microsoft Entra ID ----------
variable "azure_client_id" {
  description = "Client ID de la app api-cloud-native en Azure AD (scope y JWT audience)"
}

variable "azure_tenant_id" {
  description = "Tenant ID de Azure AD"
}

# ---------- Acceso administrativo ----------
variable "admin_cidrs" {
  description = "IPs autorizadas (CIDR /32) para SSH y para la consola de RabbitMQ (15672). Ej: [\"203.0.113.10/32\"]"
  type        = list(string)

  validation {
    condition     = alltrue([for c in var.admin_cidrs : can(regex("/32$", c))])
    error_message = "Cada IP administrativa debe terminar en /32."
  }
}

variable "ssh_public_key" {
  description = "Clave publica SSH (derivada de labsuser.pem con: ssh-keygen -y -f labsuser.pem)"
}

# ---------- RDS (una instancia exclusiva por microservicio) ----------
variable "rds_master_user" {
  description = "Usuario administrador de ambas RDS (solo para crear el usuario de aplicacion)"
  default     = "rds_admin"
}

variable "catalogo_db_name" {
  default = "catalogo_db"
}

variable "catalogo_db_app_user" {
  default = "catalogo_app"
}

variable "catalogo_db_master_password" {
  description = "Password del administrador de la RDS de Catalogo (alfanumerica, min. 8)"
  sensitive   = true
}

variable "catalogo_db_app_password" {
  description = "Password del usuario de aplicacion de Catalogo (alfanumerica)"
  sensitive   = true
}

variable "solicitudes_db_name" {
  default = "solicitudes_db"
}

variable "solicitudes_db_app_user" {
  default = "solicitudes_app"
}

variable "solicitudes_db_master_password" {
  description = "Password del administrador de la RDS de Solicitudes (alfanumerica, min. 8)"
  sensitive   = true
}

variable "solicitudes_db_app_password" {
  description = "Password del usuario de aplicacion de Solicitudes (alfanumerica)"
  sensitive   = true
}

# ---------- RabbitMQ (los usuarios se crean con rabbitmq/setup-rabbitmq.sh en la EC2 C) ----------
variable "rabbit_publicador_user" {
  default = "catalogo_publicador"
}

variable "rabbit_publicador_password" {
  description = "Password del usuario publicador (debe coincidir con rabbitmq/.env en la EC2 C)"
  sensitive   = true
}

variable "rabbit_consumidor_user" {
  default = "solicitudes_consumidor"
}

variable "rabbit_consumidor_password" {
  description = "Password del usuario consumidor (debe coincidir con rabbitmq/.env en la EC2 C)"
  sensitive   = true
}

# ---------- Tamanos ----------
variable "frontend_instance_type" {
  default = "t3.micro"
}

variable "app_instance_type" {
  description = "EC2 de Catalogo, Solicitudes y BFF (compilan con Maven al arrancar: >= 2 GB de RAM)"
  default     = "t3.small"
}

variable "rabbit_instance_type" {
  description = "EC2 del broker (el laboratorio indica t3.medium)"
  default     = "t3.medium"
}

variable "rds_instance_class" {
  default = "db.t3.micro"
}
