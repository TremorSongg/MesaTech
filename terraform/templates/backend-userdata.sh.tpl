#!/bin/bash
set -e
exec > >(tee /var/log/userdata.log) 2>&1

echo "=== MesaTech Backend EC2 setup ==="

# Instalar dependencias
dnf update -y
dnf install -y docker git nc
systemctl enable docker
systemctl start docker

# Instalar Docker Compose plugin
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Clonar repositorio
git clone ${github_repo} /app
cd /app

# Aplicar fix del scope (seguridad: corregir typo si el repo aun lo tiene)
sed -i 's/acces_as_user/access_as_user/g' /app/frontend/src/authConfig.js || true

# Crear override de produccion para docker-compose
cat > /app/docker-compose.prod.yml << 'EOF'
version: '3.9'
services:
  ms-catalogo:
    restart: unless-stopped
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - DB_URL=jdbc:postgresql://${db_private_ip}:5432/${db_name}
      - DB_USER=${db_user}
      - DB_PASSWORD=${db_password}
      - ENTRA_ISSUER_URI=https://login.microsoftonline.com/${azure_tenant_id}/v2.0
      - ENTRA_AUDIENCE=${azure_client_id}
      - JAVA_TOOL_OPTIONS=-Xmx400m -Xms200m
    ports:
      - "8082:8082"
  ms-solicitudes:
    restart: unless-stopped
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - DB_URL=jdbc:postgresql://${db_private_ip}:5432/${db_name}
      - DB_USER=${db_user}
      - DB_PASSWORD=${db_password}
      - ENTRA_ISSUER_URI=https://login.microsoftonline.com/${azure_tenant_id}/v2.0
      - ENTRA_AUDIENCE=${azure_client_id}
      - JAVA_TOOL_OPTIONS=-Xmx400m -Xms200m
    ports:
      - "8081:8081"
  bff:
    restart: unless-stopped
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - SOLICITUDES_URL=http://ms-solicitudes:8081
      - CATALOGO_URL=http://ms-catalogo:8082
      - ENTRA_ISSUER_URI=https://login.microsoftonline.com/${azure_tenant_id}/v2.0
      - ENTRA_AUDIENCE=${azure_client_id}
      - CORS_ALLOWED_ORIGIN=${api_gateway_url}
      - JAVA_TOOL_OPTIONS=-Xmx400m -Xms200m
    ports:
      - "8080:8080"
EOF

# Esperar que la base de datos este disponible
echo "Esperando que PostgreSQL este listo en ${db_private_ip}:5432..."
until nc -z -w5 ${db_private_ip} 5432; do
  echo "DB no disponible aun, reintentando en 10s..."
  sleep 10
done
echo "Base de datos disponible"

# Construir y levantar los servicios (sin postgres - usa DB externa)
docker compose -f docker-compose.yml -f docker-compose.prod.yml \
  build bff ms-solicitudes ms-catalogo

docker compose -f docker-compose.yml -f docker-compose.prod.yml \
  up -d --no-deps bff ms-solicitudes ms-catalogo

echo "=== Backend levantado: BFF:8080, ms-solicitudes:8081, ms-catalogo:8082 ==="
