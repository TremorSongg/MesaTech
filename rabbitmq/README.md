# RabbitMQ de MesaTech Cloud (EC2 C)

Instalación **desde cero** del broker en una EC2 Ubuntu 24.04 sin nada preinstalado
(Terraform la crea vacía a propósito). Cada paso es evidencia para la EP2: ejecutarlos uno a
uno y capturar la salida (sin mostrar contraseñas).

| Archivo | Para qué sirve |
|---|---|
| `compose.yaml` | RabbitMQ oficial con tag explícito, hostname, puertos 5672/15672, volumen y restart |
| `.env.example` | Variables del broker con valores ficticios (el `.env` real no se versiona) |
| `install-docker-ubuntu.sh` | Instalación de Docker Engine + Compose según la documentación oficial |
| `setup-rabbitmq.sh` | Crea vhost, usuarios, permisos, exchange, cola y binding (idempotente) |

## Pasos en la EC2 C

1. **Copiar los archivos** desde tu PC (la IP sale del output `rabbitmq_consola` de Terraform):
   ```bash
   scp -i Credenciales/labsuser.pem -r rabbitmq ubuntu@<IP_RABBITMQ>:~/
   scp -i Credenciales/labsuser.pem Credenciales/rabbitmq.env ubuntu@<IP_RABBITMQ>:~/rabbitmq/.env
   ```
2. **Instalar Docker y Compose** (conectar por SSH y ejecutar):
   ```bash
   cd ~/rabbitmq && bash install-docker-ubuntu.sh
   exit        # volver a entrar por SSH para que aplique el grupo docker
   ```
3. **Validar, descargar y levantar:**
   ```bash
   cd ~/rabbitmq
   docker compose config --quiet && echo "compose.yaml valido"
   docker compose pull
   docker compose up -d
   docker compose ps
   ```
4. **Diagnóstico del broker:**
   ```bash
   docker logs rabbitmq
   docker exec rabbitmq rabbitmq-diagnostics ping
   docker exec rabbitmq rabbitmqctl status
   ss -lnt | grep -E '5672|15672'
   ```
5. **Crear los recursos de mensajería:**
   ```bash
   bash setup-rabbitmq.sh
   ```
6. **Consola web:** `http://<IP_RABBITMQ>:15672` con el usuario administrador del `.env`
   (solo accesible desde las IPs de `admin_cidrs`).

## Reinicio del broker conservando datos (prueba P5)
```bash
docker compose up -d --force-recreate rabbitmq     # NO usar "down -v": borraría el volumen
docker exec rabbitmq rabbitmqctl list_queues -p mesatech name messages_ready consumers
```

## Notas
- Las estadísticas de la consola se refrescan cada ~5 s; para evidencias en tiempo real usar
  `rabbitmqctl list_queues`.
- Para inspeccionar un mensaje desde la consola usar *Get messages* con **Nack message requeue true**,
  para devolverlo a la cola.
- Los usuarios de aplicación no tienen tags de administración. El publicador solo puede escribir en
  `catalogo.exchange` y el consumidor solo leer de `solicitudes.catalogo.queue`.
