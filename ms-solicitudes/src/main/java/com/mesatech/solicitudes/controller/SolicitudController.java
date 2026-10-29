package com.mesatech.solicitudes.controller;

import com.mesatech.solicitudes.dto.CambioEstadoRequest;
import com.mesatech.solicitudes.dto.CategoriaLocalResponse;
import com.mesatech.solicitudes.service.CategoriaLocalService;
import com.mesatech.solicitudes.dto.PagedSolicitudesResponse;
import com.mesatech.solicitudes.dto.SolicitudRequest;
import com.mesatech.solicitudes.dto.SolicitudResponse;
import com.mesatech.solicitudes.service.SolicitudService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
public class SolicitudController {

    private final SolicitudService solicitudService;
    private final CategoriaLocalService categoriaLocalService;

    // ==================== v1 ====================

    // Cualquier usuario autenticado puede crear una solicitud
    @PostMapping("/v1/solicitudes")
    @PreAuthorize("hasAnyRole('CLIENTE', 'OPERADOR', 'ADMINISTRADOR')")
    public ResponseEntity<SolicitudResponse> crear(
            @Valid @RequestBody SolicitudRequest request,
            @AuthenticationPrincipal Jwt jwt) {

        // En prod: usuario del JWT. En dev (jwt=null): del body
        String usuario = jwt != null
                ? jwt.getClaimAsString("preferred_username")
                : request.getUsuarioSolicitante();

        if (usuario == null || usuario.isBlank()) {
            usuario = "dev-usuario@mesatech.cl";
        }

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(solicitudService.crearSolicitud(request, usuario));
    }

    // Categorias disponibles para crear solicitudes: copia local recibida por RabbitMQ.
    // Cualquier usuario autenticado puede consultarlas.
    @GetMapping("/v1/solicitudes/categorias")
    public ResponseEntity<List<CategoriaLocalResponse>> getCategorias() {
        return ResponseEntity.ok(categoriaLocalService.listarActivas());
    }

    // El usuario autenticado ve solo sus propias solicitudes
    @GetMapping("/v1/solicitudes/mias")
    public ResponseEntity<List<SolicitudResponse>> getMias(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(required = false) String usuario) {

        String email = jwt != null
                ? jwt.getClaimAsString("preferred_username")
                : usuario;

        if (email == null || email.isBlank()) {
            email = "dev-usuario@mesatech.cl";
        }

        return ResponseEntity.ok(solicitudService.getSolicitudesByUsuario(email));
    }

    // Operador y Admin ven todas las solicitudes
    @GetMapping("/v1/solicitudes")
    @PreAuthorize("hasAnyRole('OPERADOR', 'ADMINISTRADOR')")
    public ResponseEntity<List<SolicitudResponse>> getTodas() {
        return ResponseEntity.ok(solicitudService.getTodasSolicitudes());
    }

    // Operador y Admin pueden cambiar el estado
    @PatchMapping("/v1/solicitudes/{id}/estado")
    @PreAuthorize("hasAnyRole('OPERADOR', 'ADMINISTRADOR')")
    public ResponseEntity<SolicitudResponse> cambiarEstado(
            @PathVariable Long id,
            @Valid @RequestBody CambioEstadoRequest request) {

        return ResponseEntity.ok(solicitudService.cambiarEstado(id, request));
    }

    // ==================== v2 ====================

    // v2: misma consulta pero con paginacion, dias_abierto y siguientes_estados
    @GetMapping("/v2/solicitudes")
    @PreAuthorize("hasAnyRole('OPERADOR', 'ADMINISTRADOR')")
    public ResponseEntity<PagedSolicitudesResponse> getTodosPaginado(
            @RequestParam(defaultValue = "0") int pagina,
            @RequestParam(defaultValue = "10") int tamano,
            @RequestParam(required = false) String estado) {

        return ResponseEntity.ok(
                solicitudService.getSolicitudesPaginadas(pagina, tamano, estado)
        );
    }
}
