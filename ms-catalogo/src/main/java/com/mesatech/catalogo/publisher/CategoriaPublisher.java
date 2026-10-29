package com.mesatech.catalogo.publisher;

import com.mesatech.catalogo.dto.CategoriaCreadaEvent;
import com.mesatech.catalogo.entity.Categoria;
import com.mesatech.catalogo.exception.PublicacionEventoException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.core.MessageDeliveryMode;
import org.springframework.amqp.rabbit.connection.CorrelationData;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.UUID;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

@Component
@Slf4j
public class CategoriaPublisher {

    @Autowired
    private RabbitTemplate rabbitTemplate;

    @Value("${app.rabbitmq.exchange}")
    private String exchange;

    @Value("${app.rabbitmq.routing-key}")
    private String routingKey;

    @Value("${app.rabbitmq.confirm-timeout-ms}")
    private long confirmTimeoutMs;

    // Publica el evento y espera la confirmacion del broker (publisher confirm).
    // La confirmacion indica que RabbitMQ acepto el mensaje, no que Solicitudes ya lo proceso.
    public String publicarCategoriaCreada(Categoria categoria) {

        String eventId = UUID.randomUUID().toString();

        CategoriaCreadaEvent evento = new CategoriaCreadaEvent(
                eventId,
                CategoriaCreadaEvent.TIPO,
                Instant.now().toString(),
                categoria.getId(),
                categoria.getNombre());

        CorrelationData correlationData = new CorrelationData(eventId);

        try {
            rabbitTemplate.convertAndSend(
                    exchange,
                    routingKey,
                    evento,
                    message -> {
                        message.getMessageProperties()
                                .setDeliveryMode(MessageDeliveryMode.PERSISTENT);

                        message.getMessageProperties()
                                .setMessageId(eventId);

                        return message;
                    },
                    correlationData
            );

            CorrelationData.Confirm confirm =
                    correlationData.getFuture().get(confirmTimeoutMs, TimeUnit.MILLISECONDS);

            if (!confirm.isAck()) {
                throw falla("RabbitMQ no confirmo la publicacion: " + confirm.getReason(),
                        categoria, eventId, null);
            }

            if (correlationData.getReturned() != null) {
                throw falla("RabbitMQ no pudo dirigir el mensaje a una cola (sin ruta)",
                        categoria, eventId, null);
            }

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw falla("Se interrumpio la espera de confirmacion", categoria, eventId, e);

        } catch (ExecutionException | TimeoutException e) {
            throw falla("No se pudo confirmar la publicacion en RabbitMQ", categoria, eventId, e);

        } catch (org.springframework.amqp.AmqpException e) {
            throw falla("No se pudo publicar en RabbitMQ: " + e.getMessage(), categoria, eventId, e);
        }

        log.info("Evento publicado y confirmado: eventId={} tipo={} categoriaId={} exchange={} routingKey={}",
                eventId, CategoriaCreadaEvent.TIPO, categoria.getId(), exchange, routingKey);
        return eventId;
    }

    private PublicacionEventoException falla(String detalle, Categoria categoria, String eventId, Throwable causa) {
        log.error("Fallo de publicacion: eventId={} categoriaId={} detalle={}",
                eventId, categoria.getId(), detalle);
        return new PublicacionEventoException(detalle, categoria.getId(), eventId, causa);
    }
}
