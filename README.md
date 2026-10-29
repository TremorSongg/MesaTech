# MesaTech Cloud (DSY1107 – Evaluación 2)

Plataforma de soporte tecnológico cloud native. La EP2 agrega **mensajería asíncrona**: cuando un administrador
crea una categoría, Catálogo la guarda en su base y publica un evento en **RabbitMQ**; Solicitudes lo consume y guarda
una copia en **su propia base**, que usa al registrar solicitudes. Cada microservicio corre en su propia EC2 con su
propia instancia RDS.

- Contrato del evento y límites de entrega: [`docs/CONTRATO_EVENTO.md`](docs/CONTRATO_EVENTO.md)
- Pruebas P1–P8 (comandos y resultados esperados): [`docs/RUNBOOK_PRUEBAS.md`](docs/RUNBOOK_PRUEBAS.md)
- Instalación del broker: [`rabbitmq/README.md`](rabbitmq/README.md)
- Esquemas SQL: [`scripts/sql/`](scripts/sql/)

## Arquitectura

```
React (MSAL) ──► Microsoft Entra ID (login, JWT con roles)
     │
     ▼  HTTPS + JWT
API Gateway (HTTP API, authorizer JWT) ──► BFF (EC2)  :8080   valida JWT y roles, solo hace de proxy
                                             │
                          ┌──────────────────┴──────────────────┐
                          ▼                                     ▼
              ms-catalogo (EC2 A) :8082              ms-solicitudes (EC2 B) :8081
              PUBLICADOR                             CONSUMIDOR
                │             │                         │              │
                ▼             └──► RabbitMQ (EC2 C) ◄───┘              ▼
         RDS Catálogo             catalogo.exchange ─► cola      RDS Solicitudes
        (dueño: Catálogo)         solicitudes.catalogo.queue    (dueño: Solicitudes)
```

| Componente | Dónde | Puertos | Rol |
|---|---|---|---|
| Frontend (React + nginx) | EC2 frontend | 80 | Interfaz; se sirve por API Gateway |
| BFF | EC2 propia | 8080 | Seguridad y coordinación; **no** accede a RDS ni a RabbitMQ |
| ms-catalogo | **EC2 A** | 8082 | Categorías y prioridades; **publica** eventos |
| ms-solicitudes | **EC2 B** | 8081 | Solicitudes y estados; **consume** eventos |
| RabbitMQ | **EC2 C** (Ubuntu 24.04, Docker) | 5672 (AMQP), 15672 (consola) | Broker |
| RDS Catálogo / RDS Solicitudes | 2 instancias MySQL independientes, privadas | 3306 | Una por microservicio |

React solo accede a las funciones de negocio por API Gateway.

## Versiones usadas

| Pieza | Versión |
|---|---|
| Java | OpenJDK 21 (21.0.12.1 en las EC2) |
| Spring Boot | 3.2.5 (Spring AMQP 3.1.4, Spring Security / OAuth2 Resource Server) |
| Maven | 3.8.7 en las EC2 (3.9 en las imágenes Docker locales) |
| Sistema operativo EC2 | Ubuntu Server 24.04.5 LTS (frontend: Amazon Linux 2023) |
| Docker Engine / Compose | 29.9.2 / v5.6.1 (EC2 C) |
| RabbitMQ | 3.13.7 con consola (`rabbitmq:3.13.7-management`, Erlang 26.2.5.16) |
| Base de datos | Amazon RDS MySQL 8.0.46 (`db.t3.micro`); `mysql:8.0` en local |
| Frontend | React 18.3, Vite 5, MSAL (browser 3.10 / react 2.1), Node 20 para compilar |
| Terraform | 1.15.5 con proveedor AWS 5.100 (`~> 5.0`) |

> **Diferencia con la guía de clase.** La guía usa Spring Boot 4 (`JacksonJsonMessageConverter`, `confirm.ack()`).
> Este proyecto sigue en Spring Boot 3.2.5, donde los equivalentes son `Jackson2JsonMessageConverter` y
> `confirm.isAck()`. El patrón (confirmaciones del publicador, ack tras persistir) es el mismo.

## Requisitos

- Para desarrollo local: Docker Desktop (Compose v2.20+).
- Para compilar sin Docker: JDK 21 y Maven 3.8+ (microservicios y BFF); Node 20 (frontend).
- Para AWS: Terraform ≥ 1.0, credenciales del Learner Lab y una *app registration* en Entra ID con el scope
  `api://<client-id>/access_as_user` y los roles `CLIENTE`, `OPERADOR`, `ADMINISTRADOR`.

## Estructura del repositorio

```
bff/  ms-catalogo/  ms-solicitudes/  frontend/       aplicaciones
rabbitmq/        compose.yaml, setup-rabbitmq.sh, install-docker-ubuntu.sh, .env.example
terraform/       2 RDS, 5 EC2, security groups, API Gateway
scripts/         redeploy-service.sh, db-query.sh, sql/ (esquemas)
docs/            contrato del evento y runbook de pruebas
docker-compose.yml   entorno local completo      .env.example   variables (valores ficticios)
```

## Ejecución local (todo en Docker)

```bash
cp .env.example .env            # reemplazar los valores ficticios; usar contraseñas alfanuméricas
docker compose up -d rabbitmq mysql-catalogo mysql-solicitudes
bash rabbitmq/setup-rabbitmq.sh .env      # crea vhost, usuarios, permisos, exchange, cola y binding
docker compose up -d --build              # microservicios, BFF y frontend
```

Frontend en <http://localhost:3001> (sin login: rol simulado `VITE_MOCK_ROLE`), consola de RabbitMQ en
<http://localhost:15672>. En local los servicios usan el perfil `dev` (sin JWT).

## Variables de configuración

Los valores reales **nunca** se versionan (`.env`, `terraform.tfvars` y `Credenciales/` están en `.gitignore`).
Plantillas con valores ficticios: [`.env.example`](.env.example), [`rabbitmq/.env.example`](rabbitmq/.env.example),
[`terraform/terraform.tfvars.example`](terraform/terraform.tfvars.example).

| Variable | Usada por | Descripción |
|---|---|---|
| `DB_URL`, `DB_USER`, `DB_PASSWORD` | ms-catalogo, ms-solicitudes | **Solo** la RDS propia de cada servicio |
| `RABBITMQ_HOST`, `RABBITMQ_VHOST` (`mesatech`) | ms-catalogo, ms-solicitudes | Broker (IP privada de la EC2 C en AWS) |
| `RABBITMQ_USER`, `RABBITMQ_PASSWORD` | ambos | Publicador en Catálogo, consumidor en Solicitudes |
| `RABBITMQ_EXCHANGE`, `RABBITMQ_ROUTING_KEY` | ms-catalogo | `catalogo.exchange`, `categoria.creada` |
| `RABBITMQ_QUEUE` | ms-solicitudes | `solicitudes.catalogo.queue` |
| `SOLICITUDES_URL`, `CATALOGO_URL` | BFF | URLs internas (IP privada) |
| `ENTRA_ISSUER_URI`, `ENTRA_AUDIENCE` | los tres, perfil `prod` | Validación del JWT de Entra ID |
| `SPRING_PROFILES_ACTIVE` | los tres | `dev` (sin JWT) o `prod` |

## Despliegue en AWS

1. **Infraestructura.** `terraform/terraform.tfvars` a partir del ejemplo (IDs de Entra, tu IP `/32`, claves de las RDS
   y de RabbitMQ) y, con las credenciales del lab cargadas como variables de entorno:
   ```bash
   cd terraform && terraform init && terraform plan -out=tfplan && terraform apply tfplan
   ```
   Crea 2 RDS MySQL (subnets privadas, sin acceso público), 5 EC2, 3 IP elásticas, security groups y API Gateway.
   Los security groups usan otros security groups como origen (el BFF llega a A y B; A y B llegan al 5672; cada RDS
   acepta el 3306 solo desde su EC2). SSH y la consola 15672 solo desde las IP `/32` de `admin_cidrs`.
2. **Entra ID.** Registrar la URL de API Gateway (`terraform output azure_redirect_uri`) como *Redirect URI* de
   plataforma **Single-page application**.
3. **Aplicaciones (EC2 A, B y BFF).** El *user-data* instala Java 21 y Maven, clona la rama definida en `github_branch`,
   compila, crea el usuario de aplicación en su RDS y deja el servicio como unidad `systemd`
   (`ms-catalogo`, `ms-solicitudes`, `bff`; reinicio automático). Los logs están en `journalctl -u <servicio>`.
4. **RabbitMQ (EC2 C).** Se crea **vacía** a propósito: se instala desde cero siguiendo [`rabbitmq/README.md`](rabbitmq/README.md)
   (Docker + Compose, `docker compose pull/up -d`, `setup-rabbitmq.sh`).
5. **Cambios posteriores de código.** Tras `git push`, en cada EC2:
   ```bash
   sudo git -C /opt/mesatech/src pull --ff-only
   sudo bash /opt/mesatech/src/scripts/redeploy-service.sh <ms-catalogo|ms-solicitudes|bff>
   ```

## Arranque, detención y recuperación

El Learner Lab **detiene las EC2 al terminar la sesión y no las vuelve a encender**: hay que iniciarlas a mano.

**Orden de arranque / recuperación**
1. Las dos **RDS** (esperar a que estén `available`).
2. **EC2 C (RabbitMQ).** Con `restart: unless-stopped` el contenedor vuelve solo al arrancar la máquina; si se
   detuvo a mano: `cd ~/rabbitmq && docker compose start`. Esperar a `healthy`.
3. **EC2 A (Catálogo)** y **EC2 B (Solicitudes)** ~30 s después. Los servicios arrancan solos (`systemd`); reintentan
   hasta que la RDS y el broker respondan.
4. **BFF** y **frontend**.
5. Verificar: la cola debe mostrar `consumers = 1`
   (`docker exec rabbitmq rabbitmqctl list_queues -p mesatech name messages_ready consumers`); si da 0,
   `sudo systemctl restart ms-solicitudes` en B. Esperar unos minutos antes de probar el sitio.

Las IP públicas de A y B cambian al reiniciar (solo afecta al SSH); las de BFF, frontend y RabbitMQ son elásticas.

**Detención:** frontend/BFF → `sudo systemctl stop ms-catalogo ms-solicitudes` → en C `docker compose stop`
(**nunca** `docker compose down -v`: borraría el volumen y los mensajes pendientes) → detener EC2/RDS en la consola.

## Endpoints (a través de API Gateway → BFF)

| Método y ruta | Roles | Notas |
|---|---|---|
| `GET /v1/catalogo`, `/v1/catalogo/categorias`, `/v1/catalogo/prioridades` | autenticados | |
| `POST/PUT/DELETE /v1/catalogo/categorias[/{id}]`, `POST/PUT/DELETE /v1/catalogo/prioridades[/{id}]` | ADMINISTRADOR | `POST` categorías publica el evento; **502** si el broker no lo confirma |
| `GET /v1/solicitudes/categorias` | autenticados | Copia local de categorías (recibida por RabbitMQ) |
| `POST /v1/solicitudes` | CLIENTE, OPERADOR, ADMINISTRADOR | **422** si la categoría aún no llegó |
| `GET /v1/solicitudes/mias` | autenticados | Solo las propias |
| `GET /v1/solicitudes` | OPERADOR, ADMINISTRADOR | v1: lista simple |
| `GET /v2/solicitudes?pagina&tamano&estado` | OPERADOR, ADMINISTRADOR | v2: paginación, `siguientesEstados`, `diasAbierto` |
| `PATCH /v1/solicitudes/{id}/estado` | OPERADOR, ADMINISTRADOR | **422** si la transición no es válida |

Estados: `CREADA → ASIGNADA → EN_PROCESO → RESUELTA → CERRADA` (y `CANCELADA` desde `CREADA`, `ASIGNADA` o
`EN_PROCESO`). No se puede resolver sin pasar por `EN_PROCESO`.
Respuestas de seguridad: sin token **401** (API Gateway), rol insuficiente **403** (BFF y microservicios).

## Limitaciones conocidas

- Guardar en la RDS y publicar son operaciones separadas: si la publicación falla, la categoría queda guardada en
  Catálogo y no llega a Solicitudes (no hay outbox, reintentos automáticos ni DLQ). Ver el contrato.
- Entrega al menos una vez: un mensaje reentregado actualiza la misma fila de la copia local, sin afirmar
  procesamiento exactamente una vez.
- Solo la creación de categorías genera eventos; actualizaciones y bajas siguen como en la EP1.
- Las contraseñas de las bases y de RabbitMQ viajan en el *user-data* de las EC2 y en el estado de Terraform
  (laboratorio académico); en producción se usaría un gestor de secretos.
- Sin TLS en AMQP ni en la consola (solo red privada y acceso restringido por IP, como indica el enunciado).
