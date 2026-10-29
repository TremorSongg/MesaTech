package com.mesatech.solicitudes.service;

import com.mesatech.solicitudes.dto.CambioEstadoRequest;
import com.mesatech.solicitudes.dto.PagedSolicitudesResponse;
import com.mesatech.solicitudes.dto.SolicitudRequest;
import com.mesatech.solicitudes.dto.SolicitudResponse;
import com.mesatech.solicitudes.entity.CategoriaLocal;
import com.mesatech.solicitudes.entity.EstadoSolicitud;
import com.mesatech.solicitudes.exception.CategoriaNoDisponibleException;
import com.mesatech.solicitudes.repository.CategoriaLocalRepository;
import com.mesatech.solicitudes.entity.Solicitud;
import com.mesatech.solicitudes.repository.SolicitudRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class SolicitudService {

    private final SolicitudRepository solicitudRepository;
    private final EstadoMachine estadoMachine;
    private final CategoriaLocalRepository categoriaLocalRepository;

    @Transactional
    public SolicitudResponse crearSolicitud(SolicitudRequest request, String usuarioSolicitante) {
        // La categoria debe existir en la copia local (recibida por RabbitMQ)
        CategoriaLocal categoria = categoriaLocalRepository.findByCategoriaId(request.getCategoriaId())
                .filter(CategoriaLocal::isActivo)
                .orElseThrow(() -> new CategoriaNoDisponibleException(request.getCategoriaId()));
        request.setCategoriaNombre(categoria.getNombre());

        Solicitud solicitud = new Solicitud();
        solicitud.setTitulo(request.getTitulo());
        solicitud.setDescripcion(request.getDescripcion());
        solicitud.setCategoriaId(request.getCategoriaId());
        solicitud.setCategoriaNombre(request.getCategoriaNombre());
        solicitud.setPrioridadId(request.getPrioridadId());
        solicitud.setPrioridadNombre(request.getPrioridadNombre());
        solicitud.setPrioridadNivel(request.getPrioridadNivel());
        solicitud.setUsuarioSolicitante(usuarioSolicitante);
        solicitud.setEstado(EstadoSolicitud.CREADA);
        solicitud.setFechaCreacion(LocalDateTime.now());

        return SolicitudResponse.from(solicitudRepository.save(solicitud));
    }

    public List<SolicitudResponse> getSolicitudesByUsuario(String usuario) {
        return solicitudRepository
                .findByUsuarioSolicitanteOrderByFechaCreacionDesc(usuario)
                .stream()
                .map(SolicitudResponse::from)
                .collect(Collectors.toList());
    }

    public List<SolicitudResponse> getTodasSolicitudes() {
        return solicitudRepository.findAllByOrderByFechaCreacionDesc()
                .stream()
                .map(SolicitudResponse::from)
                .collect(Collectors.toList());
    }

    @Transactional
    public SolicitudResponse cambiarEstado(Long id, CambioEstadoRequest request) {
        Solicitud solicitud = solicitudRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Solicitud no encontrada: " + id));

        // Valida que la transicion sea legal segun la maquina de estados
        estadoMachine.validarTransicion(solicitud.getEstado(), request.getNuevoEstado());

        solicitud.setEstado(request.getNuevoEstado());
        solicitud.setFechaActualizacion(LocalDateTime.now());

        if (request.getObservaciones() != null) {
            solicitud.setObservaciones(request.getObservaciones());
        }

        // Asignar operador cuando el estado pasa a ASIGNADA
        if (request.getNuevoEstado() == EstadoSolicitud.ASIGNADA && request.getUsuarioAsignado() != null) {
            solicitud.setUsuarioAsignado(request.getUsuarioAsignado());
        }

        return SolicitudResponse.from(solicitudRepository.save(solicitud));
    }

    // Usado por el endpoint v2: devuelve paginacion + campos extra
    public PagedSolicitudesResponse getSolicitudesPaginadas(int pagina, int tamano, String estadoFiltro) {
        PageRequest pageRequest = PageRequest.of(pagina, tamano, Sort.by("fechaCreacion").descending());

        Page<Solicitud> page;
        if (estadoFiltro != null && !estadoFiltro.isBlank()) {
            EstadoSolicitud estado = EstadoSolicitud.valueOf(estadoFiltro.toUpperCase());
            page = solicitudRepository.findByEstado(estado, pageRequest);
        } else {
            page = solicitudRepository.findAll(pageRequest);
        }

        List<SolicitudResponse> contenido = page.getContent().stream()
                .map(s -> enrichV2(SolicitudResponse.from(s)))
                .collect(Collectors.toList());

        return new PagedSolicitudesResponse(contenido, pagina, tamano,
                page.getTotalElements(), page.getTotalPages());
    }

    // Agrega campos extra disponibles solo en v2
    private SolicitudResponse enrichV2(SolicitudResponse response) {
        response.setSiguientesEstados(
            estadoMachine.getSiguientesEstados(response.getEstado())
        );
        if (response.getFechaCreacion() != null) {
            response.setDiasAbierto(
                ChronoUnit.DAYS.between(response.getFechaCreacion(), LocalDateTime.now())
            );
        }
        return response;
    }
}
