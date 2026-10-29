package com.mesatech.solicitudes.service;

import com.mesatech.solicitudes.dto.CategoriaLocalResponse;
import com.mesatech.solicitudes.entity.CategoriaLocal;
import com.mesatech.solicitudes.dto.CategoriaCreadaMensaje;
import com.mesatech.solicitudes.repository.CategoriaLocalRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CategoriaLocalService {

    private final CategoriaLocalRepository repository;

    // Si la categoria ya existe (mensaje reentregado) se actualiza en vez de duplicarla.
    // No es una garantia de procesamiento exactamente-una-vez, solo evita filas repetidas.
    @Transactional
    public CategoriaLocal guardarDesdeEvento(CategoriaCreadaMensaje evento) {
        CategoriaLocal categoria = repository.findByCategoriaId(evento.getCategoriaId())
                .orElseGet(CategoriaLocal::new);
        categoria.setCategoriaId(evento.getCategoriaId());
        categoria.setNombre(evento.getNombre());
        categoria.setActivo(true);
        categoria.setEventId(evento.getEventId());
        categoria.setFechaEvento(evento.getFechaEvento());
        categoria.setFechaRecepcion(LocalDateTime.now());
        return repository.save(categoria);
    }

    public List<CategoriaLocalResponse> listarActivas() {
        return repository.findByActivoTrueOrderByNombreAsc().stream()
                .map(CategoriaLocalResponse::from)
                .collect(Collectors.toList());
    }
}
