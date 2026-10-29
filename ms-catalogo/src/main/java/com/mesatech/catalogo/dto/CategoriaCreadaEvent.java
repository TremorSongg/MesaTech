package com.mesatech.catalogo.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

// Contrato del evento categoria.creada (JSON)
// fechaEvento: ISO-8601 en UTC, ej. 2026-11-02T23:15:04.123Z
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CategoriaCreadaEvent {

    public static final String TIPO = "CATEGORIA_CREADA";

    private String eventId;
    private String tipoEvento;
    private String fechaEvento;
    private Long categoriaId;
    private String nombre;
}
