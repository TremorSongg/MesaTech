# Runbook de pruebas EP2 (P1 a P8)

Para cada prueba: preparación, comandos, resultado esperado y qué capturar. Las capturas no deben
mostrar contraseñas ni tokens completos.

**Antes de empezar** (datos de la sesión actual; las IPs de A y B cambian si el lab se reinicia):
- Sitio: `https://88kmfyrjt7.execute-api.us-east-1.amazonaws.com`
- SSH: `ssh -i Credenciales/labsuser.pem ubuntu@<IP>`; las IPs salen de `terraform output ssh`
- Consola RabbitMQ: `http://3.224.240.113:15672` (solo desde la IP autorizada)
- Terminales sugeridas: una por EC2 (A catálogo, B solicitudes, C rabbitmq).

Consulta SQL en una EC2 (el script lee las credenciales del servidor, no las muestra):
```bash
sudo bash /opt/mesatech/src/scripts/db-query.sh ms-catalogo    "SELECT id, nombre FROM categorias;"             # en A
sudo bash /opt/mesatech/src/scripts/db-query.sh ms-solicitudes "SELECT categoria_id, nombre, event_id FROM categorias_locales;"   # en B
```
Estado en tiempo real de la cola (en C; la consola web se refresca cada ~5 s):
```bash
docker exec rabbitmq rabbitmqctl list_queues -p mesatech name messages_ready messages_unacknowledged consumers
```

---

## P1. Separación real
**Objetivo:** EC2 A y B distintas y dos RDS distintas, cada proceso con su conexión y tabla.

En cada EC2 (A y B):
```bash
TOKEN=$(curl -s -X PUT http://169.254.169.254/latest/api/token -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id; echo
hostname; hostname -I
systemctl status ms-catalogo --no-pager | head -5        # en B: ms-solicitudes
sudo bash /opt/mesatech/src/scripts/db-query.sh ms-catalogo "SHOW TABLES;"   # en B: ms-solicitudes
```
**Esperado:** instance IDs distintos (A `i-0f835f59c7ed6e716`, B `i-010d45dd009be0b79`), endpoints RDS distintos
(`mesatech-rds-catalogo…` y `mesatech-rds-solicitudes…`), tablas `categorias`/`prioridades` en A y
`categorias_locales`/`solicitudes` en B.
**Capturar:** salida en A y en B, más la consola de AWS (EC2 y RDS) con los identificadores, y los security
groups de ambas RDS (3306 solo desde el SG de su EC2).

## P2. Flujo completo
1. En el sitio, con usuario **ADMINISTRADOR**, Catálogo → **+ Nueva** → nombre nuevo (ej. `Telefonia`) → guardar.
2. En A: `sudo bash /opt/mesatech/src/scripts/db-query.sh ms-catalogo "SELECT id, nombre FROM categorias ORDER BY id DESC LIMIT 3;"`
3. En A: `journalctl -u ms-catalogo --since "-2min" | grep "Evento publicado"` (anotar `eventId` y `categoriaId`).
4. En B: `journalctl -u ms-solicitudes --since "-2min" | grep -E "Evento recibido|Categoria guardada"` (mismo `eventId`).
5. En B: `sudo bash /opt/mesatech/src/scripts/db-query.sh ms-solicitudes "SELECT categoria_id, nombre, event_id FROM categorias_locales ORDER BY categoria_id DESC LIMIT 3;"`
6. En el sitio: **Nueva solicitud** → la categoría aparece en el selector → crear la solicitud.
7. En B: `... ms-solicitudes "SELECT id, titulo, categoria_id, categoria_nombre, estado FROM solicitudes ORDER BY id DESC LIMIT 3;"`

**Esperado:** el mismo `eventId` en el log del publicador, en el log del consumidor y en `categorias_locales`;
la solicitud queda con la categoría recibida. **Relación a documentar:** HTTP POST → `categoriaId` → `eventId`
(= `messageId` del mensaje) → fila en Solicitudes.

## P3. Consumidor detenido
1. En B: `sudo systemctl stop ms-solicitudes`
2. En el sitio, crear otra categoría (ej. `Redes_P3`).
3. En A: consultar que está en `categorias` (RDS Catálogo).
4. En C: `rabbitmqctl list_queues …` → **ready=1, consumers=0**.
5. En B: `… ms-solicitudes "SELECT * FROM categorias_locales WHERE nombre='Redes_P3';"` → vacío.

**Evidencia opcional del mensaje (sin retirarlo):** consola → Queues → `solicitudes.catalogo.queue` → *Get messages*
con **Ack mode = Nack message requeue true**. No usar la opción que confirma (retiraría el mensaje).

## P4. Consumo diferido
1. En B: `sudo systemctl start ms-solicitudes`
2. En B: `journalctl -u ms-solicitudes --since "-1min" | grep -E "Evento recibido|Categoria guardada"`
3. En C: `rabbitmqctl list_queues …` → **ready=0, unacked=0, consumers=1**.
4. En B: la fila de `Redes_P3` ahora existe en `categorias_locales`.

La cola vacía por sí sola no basta: mostrar también la fila guardada y el log.

## P5. Reinicio del broker (conservando el volumen)
1. En B: `sudo systemctl stop ms-solicitudes`; en el sitio crear otra categoría (ej. `Reinicio_P5`).
2. En C: `rabbitmqctl list_queues …` → ready=1.
3. En C (sin borrar volúmenes, **nunca `down -v`**):
   ```bash
   cd ~/rabbitmq
   docker inspect -f '{{.Id}}' rabbitmq | cut -c1-12            # id anterior
   docker compose up -d --force-recreate rabbitmq
   docker inspect -f '{{.Id}}' rabbitmq | cut -c1-12            # id nuevo (distinto)
   docker inspect -f '{{.Config.Hostname}}' rabbitmq            # mismo hostname
   docker exec rabbitmq rabbitmqctl list_vhosts
   docker exec rabbitmq rabbitmqctl list_exchanges -p mesatech name type durable
   docker exec rabbitmq rabbitmqctl list_queues -p mesatech name messages_ready consumers
   ```
4. **Esperado:** siguen el vhost, el exchange, la cola y el mensaje (ready=1).
5. En B: `sudo systemctl start ms-solicitudes` y verificar la fila en `categorias_locales`.

## P6. Reinicio de aplicaciones
1. Antes: consultar los datos en ambas RDS (categorías y solicitudes).
2. En A: `sudo systemctl restart ms-catalogo`; en B: `sudo systemctl restart ms-solicitudes`.
3. Cuando levanten (`systemctl is-active …`, ~15 s): repetir las consultas.

**Esperado:** mismos registros. Catálogo **no republica** eventos al reiniciar (las semillas se marcaron
como publicadas una sola vez): `journalctl -u ms-catalogo --since "-1min" | grep -c "Evento publicado"` → 0.

## P7. Fallo de publicación
1. En C: `cd ~/rabbitmq && docker compose stop`
2. En el sitio, crear una categoría (ej. `SinBroker`). **Esperado:** error controlado (502) que dice que la
   categoría pudo quedar guardada y que no se confirmó la publicación (tarda ~5 s por el timeout de conexión).
3. En A: consultar `categorias` → `SinBroker` **sí está** en la RDS de Catálogo.
4. En A: `journalctl -u ms-catalogo --since "-2min" | grep "Fallo de publicacion"`
5. En C: `docker compose start`; esperar a que esté `healthy` (`docker compose ps`).
6. En B: `categorias_locales` **no** tiene `SinBroker`.

**Explicar:** guardar en RDS y publicar son operaciones distintas; si la segunda falla no se revierte la
primera (no hay transacción distribuida ni outbox). Reintentar la solicitud puede duplicar la categoría
(el nombre es único, así que fallaría); un mensaje reentregado no duplica filas porque el consumidor actualiza
por `categoriaId`, pero no se afirma procesamiento exactamente una vez.

## P8. Continuidad EP1
| Caso | Cómo | Esperado |
|---|---|---|
| Login y consumo autorizado | Iniciar sesión en el sitio y navegar | Dashboard según rol |
| Sin token | `curl -i https://88kmfyrjt7.execute-api.us-east-1.amazonaws.com/v1/solicitudes/categorias` | **401** |
| Permisos insuficientes | Con usuario CLIENTE, `POST /v1/catalogo/categorias` con su token | **403** |
| Regla de estados | Con OPERADOR, `PATCH /v1/solicitudes/{id}/estado` a `RESUELTA` desde `CREADA`/`ASIGNADA` | **422** (no se puede resolver sin `EN_PROCESO`) |
| v1 disponible | `GET /v1/solicitudes` con OPERADOR/ADMIN | 200 |
| v2 disponible | `GET /v2/solicitudes?pagina=0&tamano=5` | 200, con paginación y `siguientesEstados` |

Obtener un token propio para `curl`: en el navegador, F12 → Network → una llamada a `/v1/...` → copiar el valor
de `Authorization: Bearer …` (usar un usuario con el rol que quieras probar). No incluirlo completo en capturas.

---

## Plantilla para el informe (una por prueba)
| Campo | Contenido |
|---|---|
| Prueba | P# y nombre |
| Preparación | Estado inicial (servicios, datos) |
| Datos usados | Categoría, `categoriaId`, `eventId` |
| Resultado esperado | Ver arriba |
| Resultado obtenido | Lo observado |
| Evidencia | Nombre de las capturas |
