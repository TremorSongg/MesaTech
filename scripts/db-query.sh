#!/usr/bin/env bash
# Ejecuta una consulta SQL contra la RDS propia de un microservicio, usando las credenciales de su
# archivo de entorno (/etc/mesatech/<servicio>.env) sin mostrarlas. Pruebas P1, P2, P4 y P6.
#
# Uso en la EC2 del servicio (como ubuntu):
#   sudo bash /opt/mesatech/src/scripts/db-query.sh ms-catalogo    "SELECT id, nombre FROM categorias;"
#   sudo bash /opt/mesatech/src/scripts/db-query.sh ms-solicitudes "SELECT categoria_id, nombre, event_id FROM categorias_locales;"
set -euo pipefail

SERVICE="${1:?Uso: sudo bash db-query.sh <ms-catalogo|ms-solicitudes> \"SQL\"}"
SQL="${2:?Falta la consulta SQL}"

set -a; . "/etc/mesatech/$SERVICE.env"; set +a
HOST=$(echo "$DB_URL" | sed -E 's#jdbc:mysql://([^:/]+).*#\1#')
DB=$(echo "$DB_URL" | sed -E 's#.*/##')

echo "RDS: $HOST | base: $DB | usuario: $DB_USER"
MYSQL_PWD="$DB_PASSWORD" mysql -h "$HOST" -u "$DB_USER" -t "$DB" -e "$SQL"
