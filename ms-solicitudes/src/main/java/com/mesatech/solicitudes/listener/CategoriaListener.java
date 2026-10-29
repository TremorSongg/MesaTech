package com.mesatech.solicitudes.listener;

import com.mesatech.solicitudes.dto.CategoriaCreadaMensaje;
import com.mesatech.solicitudes.service.CategoriaLocalService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class CategoriaListener {

    private static final Logger logger =
            LoggerFactory.getLogger(CategoriaListener.class);

    @Autowired
    private CategoriaLocalService categoriaLocalService;

    // Modo de ack AUTO: Spring envia el ack cuando este metodo retorna, es decir, despues de
    // persistir en RDS. Si guardar lanza una excepcion, se propaga y el mensaje no se confirma.
    @RabbitListener(queues = "${app.rabbitmq.queue}")
    public void consumirCategoria(CategoriaCreadaMensaje mensaje) {

        logger.info("Evento recibido: eventId={} tipo={} categoriaId={}",
                mensaje.getEventId(), mensaje.getTipoEvento(), mensaje.getCategoriaId());

        categoriaLocalService.guardarDesdeEvento(mensaje);

        logger.info("Categoria guardada en RDS local: eventId={} categoriaId={} nombre={}",
                mensaje.getEventId(), mensaje.getCategoriaId(), mensaje.getNombre());
    }
}
