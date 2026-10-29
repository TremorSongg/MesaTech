package com.mesatech.solicitudes.dto;

import com.mesatech.solicitudes.entity.CategoriaLocal;
import lombok.Data;

import java.time.LocalDateTime;

// "id" es el id de la categoria en el catalogo, para que el frontend use la misma forma que antes
@Data
public class CategoriaLocalResponse {

    private Long id;
    private String nombre;
    private boolean activo;
    private String eventId;
    private LocalDateTime fechaRecepcion;

    public static CategoriaLocalResponse from(CategoriaLocal c) {
        CategoriaLocalResponse r = new CategoriaLocalResponse();
        r.setId(c.getCategoriaId());
        r.setNombre(c.getNombre());
        r.setActivo(c.isActivo());
        r.setEventId(c.getEventId());
        r.setFechaRecepcion(c.getFechaRecepcion());
        return r;
    }
}
