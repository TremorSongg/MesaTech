package com.mesatech.bff.controller;

import com.mesatech.bff.service.ProxyService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
public class SolicitudesProxyController {

    private final ProxyService proxyService;

    @Value("${services.solicitudes.url}")
    private String solicitudesUrl;

    // ==================== v1 ====================

    @PostMapping("/v1/solicitudes")
    @PreAuthorize("hasAnyRole('CLIENTE', 'OPERADOR', 'ADMINISTRADOR')")
    public ResponseEntity<String> crear(@RequestBody(required = false) String body,
                                        HttpServletRequest request) {
        return proxyService.forward(HttpMethod.POST, solicitudesUrl + "/v1/solicitudes", body, request);
    }

    // Categorias locales de Solicitudes (copia recibida por RabbitMQ); todos los roles autenticados
    @GetMapping("/v1/solicitudes/categorias")
    public ResponseEntity<String> getCategorias(HttpServletRequest request) {
        return proxyService.forward(HttpMethod.GET, solicitudesUrl + "/v1/solicitudes/categorias", null, request);
    }

    @GetMapping("/v1/solicitudes/mias")
    public ResponseEntity<String> getMias(HttpServletRequest request) {
        String url = solicitudesUrl + "/v1/solicitudes/mias" + proxyService.buildQueryString(request);
        return proxyService.forward(HttpMethod.GET, url, null, request);
    }

    @GetMapping("/v1/solicitudes")
    @PreAuthorize("hasAnyRole('OPERADOR', 'ADMINISTRADOR')")
    public ResponseEntity<String> getTodas(HttpServletRequest request) {
        return proxyService.forward(HttpMethod.GET, solicitudesUrl + "/v1/solicitudes", null, request);
    }

    @PatchMapping("/v1/solicitudes/{id}/estado")
    @PreAuthorize("hasAnyRole('OPERADOR', 'ADMINISTRADOR')")
    public ResponseEntity<String> cambiarEstado(@PathVariable Long id,
                                                @RequestBody(required = false) String body,
                                                HttpServletRequest request) {
        String url = solicitudesUrl + "/v1/solicitudes/" + id + "/estado";
        return proxyService.forward(HttpMethod.PATCH, url, body, request);
    }

    // ==================== v2 ====================

    @GetMapping("/v2/solicitudes")
    @PreAuthorize("hasAnyRole('OPERADOR', 'ADMINISTRADOR')")
    public ResponseEntity<String> getTodosPaginado(HttpServletRequest request) {
        String url = solicitudesUrl + "/v2/solicitudes" + proxyService.buildQueryString(request);
        return proxyService.forward(HttpMethod.GET, url, null, request);
    }
}
