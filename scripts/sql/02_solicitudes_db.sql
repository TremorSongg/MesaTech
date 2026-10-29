-- ============================================================================
-- MesaTech Cloud - RDS de SOLICITUDES (instancia mesatech-rds-solicitudes)
-- Base de datos propia de ms-solicitudes. Contiene las solicitudes y la COPIA LOCAL
-- de categorias recibida por RabbitMQ. Nunca se lee la base de Catalogo.
--
-- Mecanismo habitual: la aplicacion crea/actualiza estas tablas sola con
-- Hibernate (spring.jpa.hibernate.ddl-auto=update). Este script documenta el
-- esquema real (obtenido con SHOW CREATE TABLE) y permite crearlo a mano.
--
-- Uso (como administrador de la RDS, desde la EC2 de Solicitudes):
--   mysql -h <endpoint-rds-solicitudes> -u rds_admin -p < 02_solicitudes_db.sql
-- Antes de ejecutar, reemplazar <PASSWORD_APP> por una clave alfanumerica.
-- ============================================================================

CREATE DATABASE IF NOT EXISTS solicitudes_db
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Usuario de aplicacion: solo tiene permisos sobre su propia base
CREATE USER IF NOT EXISTS 'solicitudes_app'@'%' IDENTIFIED BY '<PASSWORD_APP>';
GRANT ALL PRIVILEGES ON solicitudes_db.* TO 'solicitudes_app'@'%';
FLUSH PRIVILEGES;

USE solicitudes_db;

-- Copia local de las categorias de Catalogo (se llena al consumir el evento categoria.creada).
-- categoria_id = id de la categoria en Catalogo (referencia de origen, no autogenerado aqui).
-- La restriccion UNIQUE hace que un mensaje reentregado actualice la fila en vez de duplicarla.
CREATE TABLE IF NOT EXISTS categorias_locales (
    id              BIGINT       NOT NULL AUTO_INCREMENT,
    activo          BIT(1)       NOT NULL,
    categoria_id    BIGINT       NOT NULL,
    event_id        VARCHAR(36)  NOT NULL,   -- trazabilidad: evento que origino la fila
    fecha_evento    VARCHAR(40)  DEFAULT NULL, -- ISO-8601 UTC, tal como llego en el mensaje
    fecha_recepcion DATETIME(6)  NOT NULL,   -- cuando Solicitudes la guardo
    nombre          VARCHAR(100) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_categorias_locales_categoria (categoria_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Solicitudes de soporte. categoria_id/categoria_nombre se toman de categorias_locales
-- (sin llave foranea hacia Catalogo: son bases independientes).
CREATE TABLE IF NOT EXISTS solicitudes (
    id                  BIGINT       NOT NULL AUTO_INCREMENT,
    categoria_id        BIGINT       NOT NULL,
    categoria_nombre    VARCHAR(100) NOT NULL,
    descripcion         TEXT         NOT NULL,
    estado              ENUM('CREADA','ASIGNADA','EN_PROCESO','RESUELTA','CERRADA','CANCELADA') NOT NULL,
    fecha_actualizacion DATETIME(6)  DEFAULT NULL,
    fecha_creacion      DATETIME(6)  NOT NULL,
    observaciones       TEXT,
    prioridad_id        BIGINT       NOT NULL,
    prioridad_nivel     INT          NOT NULL,
    prioridad_nombre    VARCHAR(50)  NOT NULL,
    titulo              VARCHAR(200) NOT NULL,
    usuario_asignado    VARCHAR(150) DEFAULT NULL,
    usuario_solicitante VARCHAR(150) NOT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
