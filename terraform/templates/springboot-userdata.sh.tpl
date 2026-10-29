#!/bin/bash
# MesaTech - despliegue de un microservicio Spring Boot como JAR en Ubuntu 24.04.
# Mismo procedimiento que el laboratorio (Java 21 + java -jar), automatizado con systemd.
set -e
exec > >(tee /var/log/userdata.log) 2>&1
export DEBIAN_FRONTEND=noninteractive

echo "=== MesaTech ${service_name} (${hostname}) ==="
hostnamectl set-hostname ${hostname}

apt-get update -y
apt-get install -y openjdk-21-jdk-headless maven git curl netcat-openbsd %{ if db_setup }mysql-client%{ endif }

# ---------- Codigo ----------
git clone --branch ${github_branch} --depth 1 ${github_repo} /opt/mesatech/src
cd /opt/mesatech/src
COMMIT=$(git rev-parse --short HEAD)

%{ if db_setup ~}
# ---------- RDS: esperar disponibilidad y crear el usuario de aplicacion ----------
# La app usa solo su usuario (permisos sobre su base), no el administrador de la RDS.
echo "Esperando RDS ${db_host}:3306 ..."
until mysql -h ${db_host} -u ${db_master_user} -p'${db_master_password}' -e "SELECT 1" >/dev/null 2>&1; do
  echo "RDS no disponible aun, reintentando en 10s..."
  sleep 10
done
mysql -h ${db_host} -u ${db_master_user} -p'${db_master_password}' <<SQL
CREATE DATABASE IF NOT EXISTS ${db_name} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${db_app_user}'@'%' IDENTIFIED BY '${db_app_password}';
ALTER USER '${db_app_user}'@'%' IDENTIFIED BY '${db_app_password}';
GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_app_user}'@'%';
FLUSH PRIVILEGES;
SQL
echo "Usuario de aplicacion ${db_app_user} listo en ${db_name}"
%{ endif ~}

# ---------- Compilar ----------
cd /opt/mesatech/src/${service_dir}
MAVEN_OPTS="-Xmx768m" mvn -B -q -DskipTests package
cp target/*.jar /opt/mesatech/${service_name}.jar

# ---------- Versiones (evidencia para el informe) ----------
{
  echo "servicio: ${service_name}"
  echo "commit:   $COMMIT"
  java -version 2>&1 | head -1
  mvn -version | head -1
  grep -m1 -A1 "<artifactId>spring-boot-starter-parent" pom.xml | tail -1 | sed 's/^ *//'
} > /opt/mesatech/versions.txt
cat /opt/mesatech/versions.txt

# ---------- Configuracion (credenciales fuera del repositorio) ----------
useradd --system --no-create-home --shell /usr/sbin/nologin mesatech || true
mkdir -p /etc/mesatech
cat > /etc/mesatech/${service_name}.env <<'ENVEOF'
${env_file}
ENVEOF
chmod 600 /etc/mesatech/${service_name}.env

# ---------- Servicio systemd ----------
cat > /etc/systemd/system/${service_name}.service <<'UNITEOF'
[Unit]
Description=MesaTech ${service_name}
After=network-online.target
Wants=network-online.target

[Service]
User=mesatech
EnvironmentFile=/etc/mesatech/${service_name}.env
ExecStart=/usr/bin/java -Xms128m -Xmx${heap_mb}m -jar /opt/mesatech/${service_name}.jar
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
UNITEOF

systemctl daemon-reload
systemctl enable --now ${service_name}

echo "=== ${service_name} desplegado (puerto ${port}) - commit $COMMIT ==="
echo "Logs: journalctl -u ${service_name} -f"
