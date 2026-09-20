#!/bin/bash
set -e
exec > >(tee /var/log/userdata.log) 2>&1

echo "=== MesaTech Frontend EC2 setup ==="

# Instalar dependencias
dnf update -y
dnf install -y docker git
systemctl enable docker
systemctl start docker

# Clonar repositorio
git clone ${github_repo} /app
cd /app

# Aplicar fix del scope (seguridad: corregir typo si el repo aun lo tiene)
sed -i 's/acces_as_user/access_as_user/g' /app/frontend/src/authConfig.js || true

# Crear .env para el build del frontend (Vite los incorpora en el bundle)
cat > /app/frontend/.env << 'EOF'
VITE_AUTH_ENABLED=true
VITE_AZURE_CLIENT_ID=${azure_client_id}
VITE_AZURE_TENANT_ID=${azure_tenant_id}
VITE_API_URL=${api_gateway_url}
EOF

# Construir imagen Docker del frontend (multi-stage: Node build + nginx serve)
docker build -t mesatech-frontend /app/frontend

# Correr el contenedor mapeando puerto 80 al 3000 interno de nginx
docker run -d \
  --name mesatech-frontend \
  --restart unless-stopped \
  -p 80:3000 \
  mesatech-frontend

echo "=== Frontend disponible en puerto 80 ==="
echo "=== URL de la app: http://${frontend_ip} ==="
echo "=== Agregar en Azure AD como redirect URI: http://${frontend_ip} ==="
