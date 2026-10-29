package com.mesatech.catalogo.config;

import com.mesatech.catalogo.entity.Categoria;
import com.mesatech.catalogo.entity.Prioridad;
import com.mesatech.catalogo.publisher.CategoriaPublisher;
import com.mesatech.catalogo.repository.CategoriaRepository;
import com.mesatech.catalogo.repository.PrioridadRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.List;

// Carga datos iniciales si la BD esta vacia
@Component
@RequiredArgsConstructor
@Slf4j
public class DataInitializer implements CommandLineRunner {

    private final CategoriaRepository categoriaRepository;
    private final PrioridadRepository prioridadRepository;
    private final CategoriaPublisher categoriaPublisher;

    private static final List<String> CATEGORIAS_SEMILLA =
            List.of("Hardware", "Software", "Red", "Seguridad", "Accesos");

    @Override
    public void run(String... args) {
        seedCategorias();
        seedPrioridades();
        publicarCategoriasSemilla();
    }

    // Las categorias semilla no pasan por la API, asi que nadie publico su evento y Solicitudes
    // no las conoce. Se publican una sola vez (marca eventoPublicado), no en cada reinicio.
    // Solo afecta a las semillas: una categoria creada por API cuyo evento fallo se deja como esta.
    private void publicarCategoriasSemilla() {
        List<Categoria> pendientes = categoriaRepository.findByNombreIn(CATEGORIAS_SEMILLA).stream()
                .filter(c -> !Boolean.TRUE.equals(c.getEventoPublicado()))
                .toList();
        if (pendientes.isEmpty()) return;

        log.info("Publicando evento de {} categorias semilla pendientes", pendientes.size());
        for (Categoria c : pendientes) {
            try {
                categoriaPublisher.publicarCategoriaCreada(c);
                c.setEventoPublicado(true);
                categoriaRepository.save(c);
            } catch (RuntimeException e) {
                // El arranque no debe fallar si el broker aun no esta; se reintenta en el proximo inicio
                log.warn("No se pudo publicar la categoria semilla '{}': {}. Se reintentara al reiniciar.",
                        c.getNombre(), e.getMessage());
                return;
            }
        }
    }

    private void seedCategorias() {
        if (categoriaRepository.count() > 0) return;

        List<Categoria> categorias = List.of(
            crearCategoria("Hardware", "Problemas con equipos fisicos"),
            crearCategoria("Software", "Problemas con aplicaciones o sistemas operativos"),
            crearCategoria("Red", "Problemas de conectividad e internet"),
            crearCategoria("Seguridad", "Incidentes de seguridad informatica"),
            crearCategoria("Accesos", "Gestion de usuarios, cuentas y permisos")
        );
        categoriaRepository.saveAll(categorias);
        log.info("Categorias iniciales cargadas: {}", categorias.size());
    }

    private void seedPrioridades() {
        if (prioridadRepository.count() > 0) return;

        List<Prioridad> prioridades = List.of(
            crearPrioridad("Baja", 1, "Sin urgencia, puede esperar"),
            crearPrioridad("Media", 2, "Requiere atencion en las proximas horas"),
            crearPrioridad("Alta", 3, "Requiere atencion urgente"),
            crearPrioridad("Critica", 4, "Atencion inmediata, impacto en produccion")
        );
        prioridadRepository.saveAll(prioridades);
        log.info("Prioridades iniciales cargadas: {}", prioridades.size());
    }

    private Categoria crearCategoria(String nombre, String descripcion) {
        Categoria c = new Categoria();
        c.setNombre(nombre);
        c.setDescripcion(descripcion);
        c.setActivo(true);
        return c;
    }

    private Prioridad crearPrioridad(String nombre, int nivel, String descripcion) {
        Prioridad p = new Prioridad();
        p.setNombre(nombre);
        p.setNivel(nivel);
        p.setDescripcion(descripcion);
        p.setActivo(true);
        return p;
    }
}
