package com.mesatech.solicitudes.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.util.List;

@Data
@AllArgsConstructor
public class PagedSolicitudesResponse {
    private List<SolicitudResponse> content;
    private int pagina;
    private int tamano;
    private long totalElements;
    private int totalPages;
}
