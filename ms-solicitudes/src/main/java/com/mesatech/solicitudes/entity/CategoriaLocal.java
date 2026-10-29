package com.mesatech.solicitudes.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

// Copia local de una categoria del catalogo, recibida por RabbitMQ (evento categoria.creada)
@Entity
@Table(name = "categorias_locales")
@Data
@NoArgsConstructor
public class CategoriaLocal {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Id de la categoria en el catalogo (referencia de origen, no es autogenerado aqui)
    @Column(nullable = false, unique = true)
    private Long categoriaId;

    @Column(nullable = false, length = 100)
    private String nombre;

    @Column(nullable = false)
    private boolean activo = true;

    // Trazabilidad: evento que origino o actualizo esta copia
    @Column(nullable = false, length = 36)
    private String eventId;

    @Column(length = 40)
    private String fechaEvento;

    @Column(nullable = false)
    private LocalDateTime fechaRecepcion;
}
