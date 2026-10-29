package com.mesatech.solicitudes.repository;

import com.mesatech.solicitudes.entity.CategoriaLocal;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface CategoriaLocalRepository extends JpaRepository<CategoriaLocal, Long> {

    Optional<CategoriaLocal> findByCategoriaId(Long categoriaId);

    List<CategoriaLocal> findByActivoTrueOrderByNombreAsc();
}
