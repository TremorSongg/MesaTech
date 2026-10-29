#!/usr/bin/env bash
# Redespliega un microservicio en su EC2 con el codigo mas reciente de la rama configurada:
# git pull, compila con Maven, reemplaza el JAR y reinicia el servicio systemd.
# El user-data de Terraform solo corre en el primer arranque; este script cubre los cambios posteriores.
#
# Uso en la EC2 (como usuario ubuntu):
#   sudo bash /opt/mesatech/src/scripts/redeploy-service.sh ms-catalogo     # EC2 A
#   sudo bash /opt/mesatech/src/scripts/redeploy-service.sh ms-solicitudes  # EC2 B
#   sudo bash /opt/mesatech/src/scripts/redeploy-service.sh bff             # EC2 BFF
set -euo pipefail

SERVICE="${1:?Uso: $0 <ms-catalogo|ms-solicitudes|bff>}"
case "$SERVICE" in ms-catalogo|ms-solicitudes|bff) ;; *) echo "Servicio desconocido: $SERVICE"; exit 1;; esac

cd /opt/mesatech/src
git pull --ff-only
COMMIT=$(git rev-parse --short HEAD)

cd "/opt/mesatech/src/$SERVICE"
MAVEN_OPTS="-Xmx768m" mvn -B -q -DskipTests package
cp target/*.jar "/opt/mesatech/$SERVICE.jar"

# Mantiene al dia el registro de versiones (evidencia del informe)
{
  echo "servicio: $SERVICE"
  echo "commit:   $COMMIT"
  java -version 2>&1 | head -1
  mvn -version | head -1
  grep -m1 -A1 "<artifactId>spring-boot-starter-parent" pom.xml | tail -1 | sed 's/^ *//'
} > /opt/mesatech/versions.txt

systemctl restart "$SERVICE"
sleep 5
echo "$SERVICE redesplegado (commit $COMMIT): $(systemctl is-active "$SERVICE")"
echo "Logs: journalctl -u $SERVICE -f"
