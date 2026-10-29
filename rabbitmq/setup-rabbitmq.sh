#!/usr/bin/env bash
# Crea (o actualiza, es idempotente) los recursos de RabbitMQ de MesaTech mediante la API de
# administracion: virtual host, usuarios de aplicacion, permisos, exchange, cola y binding.
# Equivale a los pasos manuales de la guia del laboratorio hechos desde el panel web.
#
# Uso (en la EC2 del broker, con el contenedor ya levantado):
#   ./setup-rabbitmq.sh [ruta/al/archivo.env]     # por defecto, .env junto al script
set -euo pipefail

ENV_FILE="${1:-$(dirname "$0")/.env}"
[ -f "$ENV_FILE" ] || { echo "No existe $ENV_FILE (copiar .env.example a .env)"; exit 1; }
set -a; . "$ENV_FILE"; set +a

API="http://${RABBITMQ_MGMT_HOST:-localhost}:15672/api"
AUTH="${RABBITMQ_ADMIN_USER}:${RABBITMQ_ADMIN_PASSWORD}"

api() {  # api METODO ruta [cuerpo-json]
  curl -sS -f -u "$AUTH" -H "content-type: application/json" -X "$1" "$API/$2" ${3:+-d "$3"} >/dev/null
}

echo "Esperando a que la API de administracion responda..."
for i in $(seq 1 30); do
  curl -sS -f -u "$AUTH" "$API/overview" >/dev/null 2>&1 && break
  [ "$i" -eq 30 ] && { echo "RabbitMQ no responde en $API"; exit 1; }
  sleep 4
done

echo "1) Virtual host: $RABBITMQ_VHOST"
api PUT "vhosts/$RABBITMQ_VHOST" '{}'

echo "2) Usuarios de aplicacion (sin tags: no tienen acceso a la administracion)"
api PUT "users/$RABBITMQ_PUBLICADOR_USER" "{\"password\":\"$RABBITMQ_PUBLICADOR_PASSWORD\",\"tags\":\"\"}"
api PUT "users/$RABBITMQ_CONSUMIDOR_USER" "{\"password\":\"$RABBITMQ_CONSUMIDOR_PASSWORD\",\"tags\":\"\"}"

# Permisos por expresion regular sobre los recursos del vhost:
#   configure = crear/borrar recursos, write = publicar, read = consumir.
# Los recursos los crea este script, por eso las aplicaciones no necesitan "configure".
echo "3) Permisos sobre el vhost"
EXCHANGE_RE="^${RABBITMQ_EXCHANGE//./[.]}\$"
QUEUE_RE="^${RABBITMQ_QUEUE//./[.]}\$"
# Publicador: solo escribe en el exchange
api PUT "permissions/$RABBITMQ_VHOST/$RABBITMQ_PUBLICADOR_USER" \
  "{\"configure\":\"^\$\",\"write\":\"$EXCHANGE_RE\",\"read\":\"^\$\"}"
# Consumidor: solo lee de su cola
api PUT "permissions/$RABBITMQ_VHOST/$RABBITMQ_CONSUMIDOR_USER" \
  "{\"configure\":\"^\$\",\"write\":\"^\$\",\"read\":\"$QUEUE_RE\"}"
# Administrador: acceso total al vhost para operar desde el panel
api PUT "permissions/$RABBITMQ_VHOST/$RABBITMQ_ADMIN_USER" \
  '{"configure":".*","write":".*","read":".*"}'

echo "4) Exchange direct durable: $RABBITMQ_EXCHANGE"
api PUT "exchanges/$RABBITMQ_VHOST/$RABBITMQ_EXCHANGE" \
  '{"type":"direct","durable":true,"auto_delete":false,"internal":false,"arguments":{}}'

echo "5) Cola classic durable sin autoeliminacion: $RABBITMQ_QUEUE"
api PUT "queues/$RABBITMQ_VHOST/$RABBITMQ_QUEUE" \
  '{"durable":true,"auto_delete":false,"arguments":{"x-queue-type":"classic"}}'

echo "6) Binding: $RABBITMQ_EXCHANGE --[$RABBITMQ_ROUTING_KEY]--> $RABBITMQ_QUEUE"
api POST "bindings/$RABBITMQ_VHOST/e/$RABBITMQ_EXCHANGE/q/$RABBITMQ_QUEUE" \
  "{\"routing_key\":\"$RABBITMQ_ROUTING_KEY\",\"arguments\":{}}"

echo
echo "Listo. Permisos configurados en el vhost $RABBITMQ_VHOST:"
curl -sS -f -u "$AUTH" "$API/vhosts/$RABBITMQ_VHOST/permissions" \
  | python3 -c 'import sys,json; [print("  %-22s configure=%-6s write=%-28s read=%s" % (p["user"],p["configure"],p["write"],p["read"])) for p in json.load(sys.stdin)]' 2>/dev/null || true
