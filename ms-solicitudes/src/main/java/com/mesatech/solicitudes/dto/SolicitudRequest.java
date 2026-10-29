package com.mesatech.solicitudes.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class SolicitudRequest {

    @NotBlank(message = "El titulo es obligatorio")
    @Size(max = 200, message = "El titulo no puede superar 200 caracteres")
    private String titulo;

    @NotBlank(message = "La descripcion es obligatoria")
    private String descripcion;

    @NotNull(message = "La categoria es obligatoria")
    private Long categoriaId;

    // Informativo: el nombre real se toma de la copia local de categorias
    private String categoriaNombre;

    @NotNull(message = "La prioridad es obligatoria")
    private Long prioridadId;

    @NotBlank(message = "El nombre de la prioridad es obligatorio")
    private String prioridadNombre;

    @NotNull(message = "El nivel de prioridad es obligatorio")
    private Integer prioridadNivel;

    // Solo usado en perfil dev cuando no hay JWT
    private String usuarioSolicitante;
}
