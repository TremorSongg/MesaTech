-- ============================================================================
-- MesaTech Cloud - RDS de CATALOGO (instancia mesatech-rds-catalogo)
-- Base de datos propia de ms-catalogo. NO es leida por ningun otro servicio.
--
-- Mecanismo habitual: la aplicacion crea/actualiza estas tablas sola con
-- Hibernate (spring.jpa.hibernate.ddl-auto=update). Este script documenta el
-- esquema real (obtenido con SHOW CREATE TABLE) y permite crearlo a mano.
--
-- Uso (como administrador de la RDS, desde la EC2 de Catalogo):
--   mysql -h <endpoint-rds-catalogo> -u rds_admin -p < 01_catalogo_db.sql
-- Antes de ejecutar, reemplazar <PASSWORD_APP> por una clave alfanumerica.
-- ============================================================================

CREATE DATABASE IF NOT EXISTS catalogo_db
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Usuario de aplicacion: solo tiene permisos sobre su propia base
CREATE USER IF NOT EXISTS 'catalogo_app'@'%' IDENTIFIED BY '<PASSWORD_APP>';
GRANT ALL PRIVILEGES ON catalogo_db.* TO 'catalogo_app'@'%';
FLUSH PRIVILEGES;

USE catalogo_db;

-- Categorias de atencion (origen de verdad). "id" es el categoriaId que viaja en el evento.
CREATE TABLE IF NOT EXISTS categorias (
    id               BIGINT       NOT NULL AUTO_INCREMENT,
    activo           BIT(1)       NOT NULL,
    descripcion      VARCHAR(255) DEFAULT NULL,
    nombre           VARCHAR(100) NOT NULL,
    -- 1 cuando RabbitMQ confirmo el evento categoria.creada; NULL en filas previas a la columna
    evento_publicado BIT(1)       DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_categorias_nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS prioridades (
    id          BIGINT       NOT NULL AUTO_INCREMENT,
    activo      BIT(1)       NOT NULL,
    descripcion VARCHAR(255) DEFAULT NULL,
    nivel       INT          NOT NULL,
    nombre      VARCHAR(50)  NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_prioridades_nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------------------
-- Datos iniciales (los carga la aplicacion al arrancar si las tablas estan vacias;
-- se incluyen solo para referencia). Las 5 categorias semilla se publican como
-- evento una unica vez al primer arranque con el broker disponible.
-- ----------------------------------------------------------------------------
-- INSERT INTO categorias (nombre, descripcion, activo) VALUES
--   ('Hardware',  'Problemas con equipos fisicos', 1),
--   ('Software',  'Problemas con aplicaciones o sistemas operativos', 1),
--   ('Red',       'Problemas de conectividad e internet', 1),
--   ('Seguridad', 'Incidentes de seguridad informatica', 1),
--   ('Accesos',   'Gestion de usuarios, cuentas y permisos', 1);
-- INSERT INTO prioridades (nombre, nivel, descripcion, activo) VALUES
--   ('Baja', 1, 'Sin urgencia, puede esperar', 1),
--   ('Media', 2, 'Requiere atencion en las proximas horas', 1),
--   ('Alta', 3, 'Requiere atencion urgente', 1),
--   ('Critica', 4, 'Atencion inmediata, impacto en produccion', 1);
