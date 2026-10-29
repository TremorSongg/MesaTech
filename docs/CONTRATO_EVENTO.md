# Contrato del evento `categoria.creada`

Catálogo (publicador, EC2 A) informa a Solicitudes (consumidor, EC2 B) cada vez que se crea una categoría.
Se comunican **solo** por RabbitMQ: no hay consultas SQL cruzadas, archivos compartidos ni llamadas HTTP entre ellos.

## Topología en RabbitMQ (EC2 C)

| Recurso | Valor | Propiedades |
|---|---|---|
| Virtual host | `mesatech` | |
| Exchange | `catalogo.exchange` | tipo `direct`, durable, sin auto-eliminación |
| Cola | `solicitudes.catalogo.queue` | tipo `classic`, durable, sin auto-eliminación |
| Binding | exchange → cola | routing key `categoria.creada` |
| Usuario publicador | `catalogo_publicador` | sin tags; solo escritura sobre `catalogo.exchange` |
| Usuario consumidor | `solicitudes_consumidor` | sin tags; solo lectura sobre `solicitudes.catalogo.queue` |

Los recursos se crean con `rabbitmq/setup-rabbitmq.sh` (idempotente). Ninguna aplicación usa `guest` ni tiene privilegios administrativos.

## Mensaje

Cuerpo JSON (`content_type = application/json`):

| Campo | Tipo | Formato / significado |
|---|---|---|
| `eventId` | string | UUID v4 (36 caracteres). Identifica este evento; coincide con `message_id` del mensaje AMQP |
| `tipoEvento` | string | Constante `CATEGORIA_CREADA` |
| `fechaEvento` | string | Instante de publicación en **UTC**, ISO-8601 con fracción de segundo (hasta nanosegundos) y sufijo `Z` |
| `categoriaId` | number (long) | `id` de la categoría en la RDS de Catálogo. Es la **referencia de origen**: la copia local lo guarda en `categoria_id`, no lo reemplaza por una clave autogenerada |
| `nombre` | string | Nombre de la categoría (máx. 100 caracteres, único) |

### Ejemplo real
Mensaje publicado al crear la categoría `Telefonia` desde la web (29-oct-2026). Se puede verificar en las tres partes
del recorrido: log de Catálogo, log de Solicitudes y fila `categorias_locales`.

```json
{
  "eventId": "15b47205-b1bb-437c-9260-f6454aababaf",
  "tipoEvento": "CATEGORIA_CREADA",
  "fechaEvento": "2026-10-29T15:56:18.782953703Z",
  "categoriaId": 7,
  "nombre": "Telefonia"
}
```

### Propiedades AMQP del mensaje
| Propiedad | Valor |
|---|---|
| `delivery_mode` | `2` (persistente) |
| `message_id` | el mismo `eventId` |
| `content_type` | `application/json` |
| `__TypeId__` (header) | clase Java del publicador; el consumidor la **ignora** y deserializa al tipo de su propio método |

El consumidor tolera campos adicionales (`ignoreUnknown`), por lo que se pueden agregar campos sin romperlo.

## Responsabilidades

### Publicador (`ms-catalogo`)
1. Valida la solicitud y **guarda la categoría en su RDS** (commit).
2. Publica en `catalogo.exchange` con la routing key `categoria.creada`, mensaje persistente y `mandatory = true`.
3. Espera la **confirmación del broker** (publisher confirm, máx. 10 s) y comprueba que el mensaje no fue devuelto por falta de ruta.
4. Si no hay confirmación (broker caído, nack, sin ruta o timeout): responde **HTTP 502** con el `categoriaId` y el `eventId`, y un mensaje que indica que *la categoría pudo quedar guardada*. No se revierte el guardado.

Las 5 categorías semilla (Hardware, Software, Red, Seguridad, Accesos) se publican una sola vez al primer arranque con el broker disponible (marca `evento_publicado`), no en cada reinicio.

### Consumidor (`ms-solicitudes`)
1. Escucha `solicitudes.catalogo.queue` (un mensaje a la vez: `prefetch = 1`, `concurrency = 1`).
2. Convierte el JSON y **guarda la categoría en `categorias_locales`** de su propia RDS.
3. Confirma (ack) **después** de persistir: modo `AUTO` de Spring AMQP; si el guardado lanza una excepción, el mensaje no se confirma y se reencola.
4. Si `categoria_id` ya existe, actualiza la fila en lugar de duplicarla (la restricción `UNIQUE` lo garantiza).
5. Expone la copia en `GET /v1/solicitudes/categorias` y la usa para validar `POST /v1/solicitudes` (responde 422 si la categoría aún no llegó).

## Qué garantiza y qué no (límites explícitos)

- La **confirmación del publicador** significa que RabbitMQ aceptó el mensaje; **no** que Solicitudes ya lo escribió en su RDS. El procesamiento es asíncrono y la copia puede llegar con un pequeño retraso (la web muestra "Sincronizando…" y luego "Disponible").
- **Guardar y publicar son operaciones separadas.** Si el guardado tiene éxito y la publicación falla, la categoría queda en Catálogo y no llega a Solicitudes (prueba P7). No hay outbox ni transacción distribuida, y no se reintenta automáticamente.
- Entrega **al menos una vez**: un mensaje puede entregarse de nuevo (por ejemplo, si el consumidor cae antes del ack). Que la copia actualice por `categoriaId` evita filas duplicadas, pero **no se afirma procesamiento exactamente una vez**.
- Reenviar la misma solicitud HTTP de creación puede fallar por el nombre único (y, si el nombre fuera distinto, crearía otra categoría con otro evento).
- Una cola durable conserva su definición; los mensajes sobreviven a un reinicio del broker solo porque se publican como persistentes **y** el volumen `/var/lib/rabbitmq` se conserva (prueba P5).
- Solo se propaga la **creación**. Las actualizaciones y bajas del catálogo mantienen el comportamiento de la EP1 y no generan eventos.
- Sin cola de mensajes muertos (DLQ) ni reintentos avanzados (fuera del alcance de la EP2).
