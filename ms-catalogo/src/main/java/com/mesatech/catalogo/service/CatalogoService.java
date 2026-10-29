package com.mesatech.catalogo.service;

import com.mesatech.catalogo.dto.CategoriaRequest;
import com.mesatech.catalogo.dto.CatalogoResponse;
import com.mesatech.catalogo.dto.PrioridadRequest;
import com.mesatech.catalogo.entity.Categoria;
import com.mesatech.catalogo.entity.Prioridad;
import com.mesatech.catalogo.publisher.CategoriaPublisher;
import com.mesatech.catalogo.repository.CategoriaRepository;
import com.mesatech.catalogo.repository.PrioridadRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class CatalogoService {

    private final CategoriaRepository categoriaRepository;
    private final PrioridadRepository prioridadRepository;
    private final CategoriaPublisher categoriaPublisher;

    public CatalogoResponse getCatalogo() {
        CatalogoResponse response = new CatalogoResponse();
        response.setCategorias(categoriaRepository.findByActivoTrue());
        response.setPrioridades(prioridadRepository.findByActivoTrueOrderByNivelAsc());
        return response;
    }

    public List<Categoria> getCategorias() {
        return categoriaRepository.findByActivoTrue();
    }

    // Sin @Transactional a proposito: save() hace commit antes de publicar, asi el consumidor nunca
    // recibe el evento de una categoria que aun no esta confirmada en RDS. Guardar y publicar son
    // operaciones separadas: si la publicacion falla, la categoria queda guardada (no hay rollback).
    public Categoria createCategoria(CategoriaRequest request) {
        Categoria categoria = new Categoria();
        categoria.setNombre(request.getNombre());
        categoria.setDescripcion(request.getDescripcion());
        categoria.setActivo(request.isActivo());
        Categoria guardada = categoriaRepository.save(categoria);
        categoriaPublisher.publicarCategoriaCreada(guardada);
        // Solo si el broker confirmo; si falla, la excepcion sale antes y la marca queda sin definir
        guardada.setEventoPublicado(true);
        return categoriaRepository.save(guardada);
    }

    @Transactional
    public Categoria updateCategoria(Long id, CategoriaRequest request) {
        Categoria categoria = categoriaRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Categoria no encontrada: " + id));
        categoria.setNombre(request.getNombre());
        categoria.setDescripcion(request.getDescripcion());
        categoria.setActivo(request.isActivo());
        return categoriaRepository.save(categoria);
    }

    @Transactional
    public void deleteCategoria(Long id) {
        Categoria categoria = categoriaRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Categoria no encontrada: " + id));
        categoria.setActivo(false);
        categoriaRepository.save(categoria);
    }

    public List<Prioridad> getPrioridades() {
        return prioridadRepository.findByActivoTrueOrderByNivelAsc();
    }

    @Transactional
    public Prioridad createPrioridad(PrioridadRequest request) {
        Prioridad prioridad = new Prioridad();
        prioridad.setNombre(request.getNombre());
        prioridad.setNivel(request.getNivel());
        prioridad.setDescripcion(request.getDescripcion());
        prioridad.setActivo(request.isActivo());
        return prioridadRepository.save(prioridad);
    }

    @Transactional
    public Prioridad updatePrioridad(Long id, PrioridadRequest request) {
        Prioridad prioridad = prioridadRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Prioridad no encontrada: " + id));
        prioridad.setNombre(request.getNombre());
        prioridad.setNivel(request.getNivel());
        prioridad.setDescripcion(request.getDescripcion());
        prioridad.setActivo(request.isActivo());
        return prioridadRepository.save(prioridad);
    }

    @Transactional
    public void deletePrioridad(Long id) {
        Prioridad prioridad = prioridadRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Prioridad no encontrada: " + id));
        prioridad.setActivo(false);
        prioridadRepository.save(prioridad);
    }
}
