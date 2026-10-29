package com.mesatech.catalogo.exception;

import lombok.Getter;

// La categoria ya fue guardada en RDS, pero RabbitMQ no confirmo la publicacion del evento
@Getter
public class PublicacionEventoException extends RuntimeException {

    private final Long categoriaId;
    private final String eventId;

    public PublicacionEventoException(String mensaje, Long categoriaId, String eventId, Throwable causa) {
        super(mensaje, causa);
        this.categoriaId = categoriaId;
        this.eventId = eventId;
    }
}
