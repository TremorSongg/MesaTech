package com.mesatech.solicitudes.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

// Contrato del evento categoria.creada publicado por ms-catalogo
@Data
@NoArgsConstructor
@AllArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class CategoriaCreadaMensaje {

    private String eventId;
    private String tipoEvento;
    private String fechaEvento;
    private Long categoriaId;
    private String nombre;
}
