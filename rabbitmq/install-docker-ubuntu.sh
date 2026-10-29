#!/usr/bin/env bash
# Instala Docker Engine y el plugin Docker Compose en Ubuntu 24.04 siguiendo la documentacion
# oficial (https://docs.docker.com/engine/install/ubuntu/). Son los pasos 1-18 de la guia del
# laboratorio "instalacion nuevo servidor RabbitMQ". Ejecutar en la EC2 C como usuario ubuntu.
set -euxo pipefail

cat /etc/os-release | head -3

sudo apt update
sudo apt upgrade -y
sudo apt install -y ca-certificates curl

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker

sudo docker run --rm hello-world
docker --version
sudo docker compose version

# Permite usar docker sin sudo (requiere abrir una sesion nueva: salir y volver a entrar por SSH)
sudo usermod -aG docker "$USER"
echo "Listo. Cierra la sesion SSH y vuelve a entrar para usar docker sin sudo."
