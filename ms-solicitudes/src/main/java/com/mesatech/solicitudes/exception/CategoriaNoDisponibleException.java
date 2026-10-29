package com.mesatech.solicitudes.exception;

// La categoria no existe en la copia local (aun no llega el evento, o no existe)
public class CategoriaNoDisponibleException extends RuntimeException {

    public CategoriaNoDisponibleException(Long categoriaId) {
        super("La categoria " + categoriaId + " aun no esta disponible en Solicitudes. "
                + "Se sincroniza de forma asincrona; intenta nuevamente en unos segundos.");
    }
}
