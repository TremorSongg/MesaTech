package com.mesatech.catalogo.repository;

import com.mesatech.catalogo.entity.Categoria;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CategoriaRepository extends JpaRepository<Categoria, Long> {
    List<Categoria> findByActivoTrue();

    List<Categoria> findByNombreIn(List<String> nombres);
}
