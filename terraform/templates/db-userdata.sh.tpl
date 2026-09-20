#!/bin/bash
set -e
exec > >(tee /var/log/userdata.log) 2>&1

echo "=== MesaTech DB EC2 setup ==="

# Instalar Docker
dnf update -y
dnf install -y docker
systemctl enable docker
systemctl start docker

# Esperar que Docker este listo
sleep 5

# Levantar PostgreSQL
docker run -d \
  --name mesatech-postgres \
  --restart unless-stopped \
  -e POSTGRES_DB=${db_name} \
  -e POSTGRES_USER=${db_user} \
  -e POSTGRES_PASSWORD=${db_password} \
  -p 5432:5432 \
  -v postgres_data:/var/lib/postgresql/data \
  postgres:15-alpine

echo "=== PostgreSQL levantado en puerto 5432 ==="
