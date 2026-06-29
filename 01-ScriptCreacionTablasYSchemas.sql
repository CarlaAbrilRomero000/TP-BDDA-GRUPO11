/*
==============================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Fecha:       09/06/2026
Descripción: Script de creación de la base de datos, schemas
             y tablas del sistema de gestión de Parques
             Nacionales. Incluye restricciones (constraints)
             y validaciones a nivel de estructura.
==============================================================
*/

IF DB_ID('ParquesNacionalesDB') IS NULL
BEGIN
    CREATE DATABASE ParquesNacionalesDB;
END
GO

USE ParquesNacionalesDB;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'parques')
    EXEC('CREATE SCHEMA parques;');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'personal')
    EXEC('CREATE SCHEMA personal;');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'turismo')
    EXEC('CREATE SCHEMA turismo;');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'comercial')
    EXEC('CREATE SCHEMA comercial;');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'ventas')
    EXEC('CREATE SCHEMA ventas;');
GO

-- 1. TABLAS MAESTRAS INDEPENDIENTES (Nivel 0)

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TipoParque' AND schema_id = SCHEMA_ID('parques'))
BEGIN
    PRINT 'Creando tabla parques.TipoParque...';
    CREATE TABLE parques.TipoParque (
        id_tipo_parque INT IDENTITY(1,1) PRIMARY KEY,
        descripcion VARCHAR(50) NOT NULL
    );
END
ELSE
    PRINT 'OK - Tabla parques.TipoParque ya existe, se omite creación.';

GO
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TipoVisitante' AND schema_id = SCHEMA_ID('ventas'))
BEGIN
    PRINT 'Creando tabla ventas.TipoVisitante...';
    CREATE TABLE ventas.TipoVisitante (
        id_tipo_visitante INT IDENTITY(1,1) PRIMARY KEY,
        descripcion VARCHAR(50) NOT NULL
    );
END
ELSE
    PRINT 'OK - Tabla ventas.TipoVisitante ya existe, se omite creación.';

GO
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Empresa' AND schema_id = SCHEMA_ID('comercial'))
BEGIN
    PRINT 'Creando tabla comercial.Empresa...';
    CREATE TABLE comercial.Empresa (
        id_empresa INT IDENTITY(1,1) PRIMARY KEY,
        cuit CHAR(11) NOT NULL UNIQUE,
        razon_social VARCHAR(150) NOT NULL,
        telefono VARCHAR(30) NULL,
        email VARCHAR(100) NULL,
        direccion VARCHAR(255) NULL,
        CONSTRAINT CK_Empresa_CUIT CHECK (cuit NOT LIKE '%[^0-9]%'),
        CONSTRAINT CK_Empresa_Email CHECK (email IS NULL OR email LIKE '%@%.%')
    );
END
ELSE
    PRINT 'OK - Tabla comercial.Empresa ya existe, se omite creación.';

GO
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FormaPago' AND schema_id = SCHEMA_ID('ventas'))
BEGIN
    PRINT 'Creando tabla ventas.FormaPago...';
    CREATE TABLE ventas.FormaPago (
        id_forma_pago INT IDENTITY(1,1) PRIMARY KEY,
        descripcion VARCHAR(50) NOT NULL
    );
END
ELSE
    PRINT 'OK - Tabla ventas.FormaPago ya existe, se omite creación.';

GO
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TipoAtraccion' AND schema_id = SCHEMA_ID('turismo'))
BEGIN
    PRINT 'Creando tabla turismo.TipoAtraccion...';
    CREATE TABLE turismo.TipoAtraccion (
        id_tipo_atraccion INT IDENTITY(1,1) PRIMARY KEY,
        descripcion VARCHAR(50) NOT NULL
    );
END
ELSE
    PRINT 'OK - Tabla turismo.TipoAtraccion ya existe, se omite creación.';

GO
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Guardaparque' AND schema_id = SCHEMA_ID('personal'))
BEGIN
    PRINT 'Creando tabla personal.Guardaparque...';
    CREATE TABLE personal.Guardaparque (
        id_guardaparque INT IDENTITY(1,1) PRIMARY KEY,
        nombre VARCHAR(50) NOT NULL,
        apellido VARCHAR(50) NOT NULL,
        dni VARCHAR(20) NOT NULL UNIQUE,
        email VARCHAR(100) NULL,
        telefono VARCHAR(50) NULL,
        activo BIT NOT NULL DEFAULT 1,
        CONSTRAINT CK_Guardaparque_Email CHECK (email IS NULL OR email LIKE '%@%.%')
    );
END
ELSE
    PRINT 'OK - Tabla personal.Guardaparque ya existe, se omite creación.';

GO
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Guia' AND schema_id = SCHEMA_ID('turismo'))
BEGIN
    PRINT 'Creando tabla turismo.Guia...';
    CREATE TABLE turismo.Guia (
        id_guia INT IDENTITY(1,1) PRIMARY KEY,
        nombre VARCHAR(50) NOT NULL,
        apellido VARCHAR(50) NOT NULL,
        dni VARCHAR(20) NOT NULL UNIQUE,
        especialidad VARCHAR(100) NULL,
        vigencia_autorizacion DATE NOT NULL
    );
END
ELSE
    PRINT 'OK - Tabla turismo.Guia ya existe, se omite creación.';

GO

-- 2. TABLAS CON DEPENDENCIAS DIRECTAS (Nivel 1)

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Parque' AND schema_id = SCHEMA_ID('parques'))
BEGIN
    PRINT 'Creando tabla parques.Parque...';
    CREATE TABLE parques.Parque (
        id_parque INT IDENTITY(1,1) PRIMARY KEY,
        codigo_oficial VARCHAR(50) NOT NULL UNIQUE,
        nombre VARCHAR(100) NOT NULL,
        ubicacion VARCHAR(255) NOT NULL,
        superficie DECIMAL(12,2) NOT NULL,
        id_tipo_parque INT NOT NULL,
        CONSTRAINT CK_Parque_Superficie CHECK (superficie > 0),
        CONSTRAINT FK_Parque_TipoParque FOREIGN KEY (id_tipo_parque) REFERENCES parques.TipoParque(id_tipo_parque)
    );
END
ELSE
    PRINT 'OK - Tabla parques.Parque ya existe, se omite creación.';

GO
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Ticket' AND schema_id = SCHEMA_ID('ventas'))
BEGIN
    PRINT 'Creando tabla ventas.Ticket...';
    CREATE TABLE ventas.Ticket (
        id_ticket INT IDENTITY(1,1) PRIMARY KEY,
        punto_venta CHAR(4) NOT NULL,
        numero VARCHAR(50) NOT NULL,
        fecha_venta DATETIME2 NOT NULL,
        id_forma_pago INT NOT NULL,
        total DECIMAL(12,2) NOT NULL,
        CONSTRAINT CK_Ticket_Total CHECK (total >= 0),
        CONSTRAINT CK_Ticket_PuntoVenta CHECK (punto_venta NOT LIKE '%[^0-9]%'),
        CONSTRAINT FK_Ticket_FormaPago FOREIGN KEY (id_forma_pago) REFERENCES ventas.FormaPago(id_forma_pago)
    );
END
ELSE
    PRINT 'OK - Tabla ventas.Ticket ya existe, se omite creación.';

GO

-- 3. TABLAS ASOCIATIVAS Y HISTORIALES (Nivel 2)

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'HistorialGuardaparque' AND schema_id = SCHEMA_ID('personal'))
BEGIN
    PRINT 'Creando tabla personal.HistorialGuardaparque...';
    CREATE TABLE personal.HistorialGuardaparque (
        id_historial INT IDENTITY(1,1) PRIMARY KEY,
        id_guardaparque INT NOT NULL,
        id_parque INT NOT NULL,
        fecha_ingreso DATE NOT NULL,
        fecha_egreso DATE NULL,
        motivo_egreso VARCHAR(255) NULL,
        CONSTRAINT CK_HistorialGP_Fechas CHECK (fecha_egreso IS NULL OR fecha_egreso >= fecha_ingreso),
        CONSTRAINT FK_HistorialGP_Guardaparque FOREIGN KEY (id_guardaparque) REFERENCES personal.Guardaparque(id_guardaparque),
        CONSTRAINT FK_HistorialGP_Parque FOREIGN KEY (id_parque) REFERENCES parques.Parque(id_parque)
    );
END
ELSE
    PRINT 'OK - Tabla personal.HistorialGuardaparque ya existe, se omite creación.';

GO
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'GuiaParque' AND schema_id = SCHEMA_ID('turismo'))
BEGIN
    PRINT 'Creando tabla turismo.GuiaParque...';
    CREATE TABLE turismo.GuiaParque (
        id_guia INT NOT NULL,
        id_parque INT NOT NULL,
        fecha_autorizacion DATE NOT NULL,
        estado_autorizacion BIT NOT NULL DEFAULT 1,
        CONSTRAINT PK_GuiaParque PRIMARY KEY (id_guia, id_parque),
        CONSTRAINT FK_GuiaParque_Guia FOREIGN KEY (id_guia) REFERENCES turismo.Guia(id_guia),
        CONSTRAINT FK_GuiaParque_Parque FOREIGN KEY (id_parque) REFERENCES parques.Parque(id_parque)
    );
END
ELSE
    PRINT 'OK - Tabla turismo.GuiaParque ya existe, se omite creación.';

GO
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Concesion' AND schema_id = SCHEMA_ID('comercial'))
BEGIN
    PRINT 'Creando tabla comercial.Concesion...';
    CREATE TABLE comercial.Concesion (
        id_concesion INT IDENTITY(1,1) PRIMARY KEY,
        id_parque INT NOT NULL,
        id_empresa INT NOT NULL,
        tipo_actividad VARCHAR(100) NOT NULL,
        fecha_inicio DATE NOT NULL,
        fecha_fin DATE NOT NULL,
        canon_mensual DECIMAL(12,2) NOT NULL,
        CONSTRAINT CK_Concesion_Fechas CHECK (fecha_fin >= fecha_inicio),
        CONSTRAINT CK_Concesion_Canon CHECK (canon_mensual > 0),
        CONSTRAINT FK_Concesion_Parque FOREIGN KEY (id_parque) REFERENCES parques.Parque(id_parque),
        CONSTRAINT FK_Concesion_Empresa FOREIGN KEY (id_empresa) REFERENCES comercial.Empresa(id_empresa)
    );
END
ELSE
    PRINT 'OK - Tabla comercial.Concesion ya existe, se omite creación.';

GO
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AtraccionTour' AND schema_id = SCHEMA_ID('turismo'))
BEGIN
    PRINT 'Creando tabla turismo.AtraccionTour...';
    CREATE TABLE turismo.AtraccionTour (
        id_atraccion_tour INT IDENTITY(1,1) PRIMARY KEY,
        id_parque INT NOT NULL,
        id_tipo_atraccion INT NOT NULL,
        nombre VARCHAR(100) NOT NULL,
        costo DECIMAL(12,2) NOT NULL,
        cupo_maximo INT NOT NULL,
        duracion INT NOT NULL,
        CONSTRAINT CK_AtraccionTour_Costo CHECK (costo >= 0),
        CONSTRAINT CK_AtraccionTour_Cupo CHECK (cupo_maximo > 0),
        CONSTRAINT CK_AtraccionTour_Duracion CHECK (duracion > 0),
        CONSTRAINT FK_AtraccionTour_Parque FOREIGN KEY (id_parque) REFERENCES parques.Parque(id_parque),
        CONSTRAINT FK_AtraccionTour_TipoAtraccion FOREIGN KEY (id_tipo_atraccion) REFERENCES turismo.TipoAtraccion(id_tipo_atraccion)
    );
END
ELSE
    PRINT 'OK - Tabla turismo.AtraccionTour ya existe, se omite creación.';

GO
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'HistorialPrecio' AND schema_id = SCHEMA_ID('ventas'))
BEGIN
    PRINT 'Creando tabla ventas.HistorialPrecio...';
    CREATE TABLE ventas.HistorialPrecio (
        id_historial_precio INT IDENTITY(1,1) PRIMARY KEY,
        precio DECIMAL(12,2) NOT NULL,
        fecha_desde DATE NOT NULL,
        id_parque INT NOT NULL,
        id_tipo_visitante INT NOT NULL,
        CONSTRAINT CK_HistorialPrecio_Precio CHECK (precio >= 0),
        CONSTRAINT FK_HistorialPrecio_Parque FOREIGN KEY (id_parque) REFERENCES parques.Parque(id_parque),
        CONSTRAINT FK_HistorialPrecio_TipoVisitante FOREIGN KEY (id_tipo_visitante) REFERENCES ventas.TipoVisitante(id_tipo_visitante)
    );
END
ELSE
    PRINT 'OK - Tabla ventas.HistorialPrecio ya existe, se omite creación.';

GO

-- 4. DEPENDENCIAS DE ÚLTIMO NIVEL (Nivel 3)

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TourGuia' AND schema_id = SCHEMA_ID('turismo'))
BEGIN
    PRINT 'Creando tabla turismo.TourGuia...';
    CREATE TABLE turismo.TourGuia (
        id_atraccion_tour INT NOT NULL,
        id_guia INT NOT NULL,
        CONSTRAINT PK_TourGuia PRIMARY KEY (id_atraccion_tour, id_guia),
        CONSTRAINT FK_TourGuia_AtraccionTour FOREIGN KEY (id_atraccion_tour) REFERENCES turismo.AtraccionTour(id_atraccion_tour),
        CONSTRAINT FK_TourGuia_Guia FOREIGN KEY (id_guia) REFERENCES turismo.Guia(id_guia)
    );
END
ELSE
    PRINT 'OK - Tabla turismo.TourGuia ya existe, se omite creación.';

GO
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ObligacionCanon' AND schema_id = SCHEMA_ID('comercial'))
BEGIN
    PRINT 'Creando tabla comercial.ObligacionCanon...';
    CREATE TABLE comercial.ObligacionCanon (
        id_obligacion INT IDENTITY(1,1) PRIMARY KEY,
        id_concesion INT NOT NULL,
        mes TINYINT NOT NULL,
        anio SMALLINT NOT NULL,
        monto_obligado DECIMAL(12,2) NOT NULL,
        estado VARCHAR(20) NOT NULL,
        fecha_vencimiento DATE NOT NULL,
        CONSTRAINT CK_ObligacionCanon_Mes CHECK (mes BETWEEN 1 AND 12),
        CONSTRAINT CK_ObligacionCanon_Anio CHECK (anio BETWEEN 2000 AND 2100),
        CONSTRAINT CK_ObligacionCanon_Monto CHECK (monto_obligado > 0),
        CONSTRAINT CK_ObligacionCanon_Estado CHECK (estado IN ('PENDIENTE', 'PAGADO', 'VENCIDO', 'PARCIAL')),
        CONSTRAINT UQ_Concesion_Periodo UNIQUE (id_concesion, anio, mes),
        CONSTRAINT FK_ObligacionCanon_Concesion FOREIGN KEY (id_concesion) REFERENCES comercial.Concesion(id_concesion)
    );
END
ELSE
    PRINT 'OK - Tabla comercial.ObligacionCanon ya existe, se omite creación.';

GO
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PagoCanon' AND schema_id = SCHEMA_ID('comercial'))
BEGIN
    PRINT 'Creando tabla comercial.PagoCanon...';
    CREATE TABLE comercial.PagoCanon (
        id_pago INT IDENTITY(1,1) PRIMARY KEY,
        id_obligacion INT NOT NULL,
        fecha_pago DATE NOT NULL,
        monto_pagado DECIMAL(12,2) NOT NULL,
        CONSTRAINT CK_PagoCanon_Monto CHECK (monto_pagado > 0),
        CONSTRAINT FK_PagoCanon_ObligacionCanon FOREIGN KEY (id_obligacion) REFERENCES comercial.ObligacionCanon(id_obligacion)
    );
END
ELSE
    PRINT 'OK - Tabla comercial.PagoCanon ya existe, se omite creación.';

GO
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TicketDetalle' AND schema_id = SCHEMA_ID('ventas'))
BEGIN
    PRINT 'Creando tabla ventas.TicketDetalle...';
    CREATE TABLE ventas.TicketDetalle (
        id_detalle INT IDENTITY(1,1) PRIMARY KEY,
        id_ticket INT NOT NULL,
        id_parque INT NOT NULL,
        id_historial_precio INT NULL,
        id_tipo_visitante INT NULL,
        id_atraccion_tour INT NULL,
        fecha_acceso DATE NOT NULL,
        cantidad INT NOT NULL,
        precio_unitario DECIMAL(12,2) NOT NULL,
        subtotal DECIMAL(12,2) NOT NULL,
        CONSTRAINT CK_TicketDetalle_Cantidad CHECK (cantidad > 0),
        CONSTRAINT CK_TicketDetalle_PrecioUnitario CHECK (precio_unitario >= 0),
        CONSTRAINT CK_TicketDetalle_Subtotal CHECK (subtotal >= 0),
        CONSTRAINT CK_TicketDetalle_Item CHECK (id_historial_precio IS NOT NULL OR id_atraccion_tour IS NOT NULL),
        CONSTRAINT FK_TicketDetalle_Ticket FOREIGN KEY (id_ticket) REFERENCES ventas.Ticket(id_ticket),
        CONSTRAINT FK_TicketDetalle_Parque FOREIGN KEY (id_parque) REFERENCES parques.Parque(id_parque),
        CONSTRAINT FK_TicketDetalle_HistorialPrecio FOREIGN KEY (id_historial_precio) REFERENCES ventas.HistorialPrecio(id_historial_precio),
        CONSTRAINT FK_TicketDetalle_TipoVisitante FOREIGN KEY (id_tipo_visitante) REFERENCES ventas.TipoVisitante(id_tipo_visitante),
        CONSTRAINT FK_TicketDetalle_AtraccionTour FOREIGN KEY (id_atraccion_tour) REFERENCES turismo.AtraccionTour(id_atraccion_tour)
    );
END
ELSE
    PRINT 'OK - Tabla ventas.TicketDetalle ya existe, se omite creación.';

GO

-- ==============================================================
-- TABLAS DE CONSUMO DE APIs EXTERNAS (Entregas 8 y 9)
-- ==============================================================

-- --------------------------------------------------------------
-- SCHEMA: ventas  |  TABLA: CotizacionDolar
-- Histórico de cotizaciones del dólar obtenidas desde la API
-- externa (caché + auditoría de consultas).
-- --------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'CotizacionDolar' AND schema_id = SCHEMA_ID('ventas'))
BEGIN
    PRINT 'Creando tabla ventas.CotizacionDolar...';
    CREATE TABLE ventas.CotizacionDolar (
        id_cotizacion       INT IDENTITY(1,1) PRIMARY KEY,
        moneda              VARCHAR(10)   NOT NULL,
        casa                VARCHAR(20)   NOT NULL,
        nombre              VARCHAR(50)   NULL,
        compra              DECIMAL(12,4) NOT NULL,
        venta               DECIMAL(12,4) NOT NULL,
        fecha_actualizacion DATETIME2     NULL,   -- fechaActualizacion informada por la API
        fecha_consulta      DATETIME2     NOT NULL CONSTRAINT DF_CotizacionDolar_FechaConsulta DEFAULT (SYSDATETIME()),
        CONSTRAINT CK_CotizacionDolar_Compra CHECK (compra > 0),
        CONSTRAINT CK_CotizacionDolar_Venta  CHECK (venta  > 0)
    );
END
ELSE
    PRINT 'OK - Tabla ventas.CotizacionDolar ya existe, se omite creación.';
GO

-- --------------------------------------------------------------
-- SCHEMA: ventas  |  TABLA: Feriado
-- Histórico de feriados obtenidos desde la API externa
-- (caché + auditoría de consultas). La fecha es única.
-- --------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Feriado' AND schema_id = SCHEMA_ID('ventas'))
BEGIN
    PRINT 'Creando tabla ventas.Feriado...';
    CREATE TABLE ventas.Feriado (
        id_feriado     INT IDENTITY(1,1) PRIMARY KEY,
        fecha          DATE          NOT NULL,
        nombre         VARCHAR(150)  NULL,   -- nombre informado por la API
        tipo           VARCHAR(50)   NULL,   -- tipo informado por la API (inamovible, trasladable, etc.)
        anio           SMALLINT      NOT NULL,
        fecha_consulta DATETIME2     NOT NULL CONSTRAINT DF_Feriado_FechaConsulta DEFAULT (SYSDATETIME()),
        CONSTRAINT UQ_Feriado_Fecha UNIQUE (fecha),
        CONSTRAINT CK_Feriado_Anio CHECK (anio BETWEEN 2000 AND 2100)
    );
END
ELSE
    PRINT 'OK - Tabla ventas.Feriado ya existe, se omite creación.';
GO

-- ==============================================================
-- SCHEMAS: estadisticas e importaciones
-- (usados por los scripts de importación de Entrega 6)
-- ==============================================================

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'estadisticas')
    EXEC('CREATE SCHEMA estadisticas;');
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'importaciones')
    EXEC('CREATE SCHEMA importaciones;');
GO

-- ==============================================================
-- SCHEMA: estadisticas  |  TABLA: VisitantesParques
-- Histórico de visitantes por período, región y origen.
-- El SP de importación inserta claves nuevas y actualiza
-- visitas/observaciones de claves existentes; nunca elimina.
-- ==============================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'VisitantesParques' AND schema_id = SCHEMA_ID('estadisticas'))
BEGIN
    PRINT 'Creando tabla estadisticas.VisitantesParques...';
    CREATE TABLE estadisticas.VisitantesParques (
        id_visitantes_parque INT IDENTITY(1,1) PRIMARY KEY,
        indice_tiempo        DATE          NOT NULL,
        region_destino       VARCHAR(100)  NOT NULL,
        origen_visitantes    VARCHAR(50)   NOT NULL,
        visitas              INT           NOT NULL,
        observaciones        VARCHAR(500)  NULL,
        fecha_carga          DATETIME2     NOT NULL CONSTRAINT DF_VisitantesParques_FechaCarga DEFAULT (SYSDATETIME()),
        fecha_actualizacion  DATETIME2     NULL,
        CONSTRAINT CK_VisitantesParques_Visitas CHECK (visitas >= 0),
        CONSTRAINT UQ_VisitantesParques_Clave UNIQUE (indice_tiempo, region_destino, origen_visitantes)
    );
END
ELSE
    PRINT 'OK - Tabla estadisticas.VisitantesParques ya existe, se omite creación.';
GO

-- ==============================================================
-- SCHEMA: estadisticas  |  TABLA: ErroresImportacion
-- Registro de filas rechazadas por los SPs de importación.
-- Tabla de auditoría: no se modifica ni elimina.
-- ==============================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ErroresImportacion' AND schema_id = SCHEMA_ID('estadisticas'))
BEGIN
    PRINT 'Creando tabla estadisticas.ErroresImportacion...';
    CREATE TABLE estadisticas.ErroresImportacion (
        id_error                INT IDENTITY(1,1) PRIMARY KEY,
        fecha_error             DATETIME2     NOT NULL CONSTRAINT DF_ErroresImportacion_Fecha DEFAULT (SYSDATETIME()),
        archivo_origen          VARCHAR(500)  NULL,
        motivo_error            VARCHAR(500)  NOT NULL,
        indice_tiempo_valor     VARCHAR(500)  NULL,
        region_destino_valor    VARCHAR(500)  NULL,
        origen_visitantes_valor VARCHAR(500)  NULL,
        visitas_valor           VARCHAR(500)  NULL,
        observaciones_valor     VARCHAR(500)  NULL
    );
END
ELSE
    PRINT 'OK - Tabla estadisticas.ErroresImportacion ya existe, se omite creación.';

GO

-- ==============================================================
-- SCHEMA: estadisticas  |  TABLA: OrganizacionesDistinguidas
-- Organizaciones con distinción de calidad turística.
-- El SP de importación inserta organizaciones nuevas y actualiza
-- datos de contacto/programa; nunca elimina filas.
-- ==============================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'OrganizacionesDistinguidas' AND schema_id = SCHEMA_ID('estadisticas'))
BEGIN
    PRINT 'Creando tabla estadisticas.OrganizacionesDistinguidas...';
    CREATE TABLE estadisticas.OrganizacionesDistinguidas (
        id_organizacion     INT IDENTITY(1,1) PRIMARY KEY,
        organizacion        VARCHAR(200)  NOT NULL,
        rubro               VARCHAR(100)  NULL,
        subrubro            VARCHAR(100)  NULL,
        calle               VARCHAR(200)  NULL,
        numero              VARCHAR(50)   NULL,
        pais                VARCHAR(100)  NULL,
        provincia           VARCHAR(100)  NULL,
        ciudad              VARCHAR(100)  NULL,
        telefono            VARCHAR(100)  NULL,
        facebook            VARCHAR(200)  NULL,
        web                 VARCHAR(200)  NULL,
        programa            VARCHAR(200)  NULL,
        fecha_distincion    DATE          NULL,
        fecha_revalidacion  DATE          NULL,
        fecha_carga         DATETIME2     NOT NULL CONSTRAINT DF_OrganizacionesDistinguidas_FechaCarga DEFAULT (SYSDATETIME()),
        fecha_actualizacion DATETIME2     NULL,
        CONSTRAINT UQ_OrganizacionesDistinguidas_Clave UNIQUE (organizacion, calle, numero)
    );
END
ELSE
    PRINT 'OK - Tabla estadisticas.OrganizacionesDistinguidas ya existe, se omite creación.';
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_OrganizacionesDistinguidas_Provincia')
    CREATE INDEX IX_OrganizacionesDistinguidas_Provincia ON estadisticas.OrganizacionesDistinguidas (provincia);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_OrganizacionesDistinguidas_Rubro')
    CREATE INDEX IX_OrganizacionesDistinguidas_Rubro ON estadisticas.OrganizacionesDistinguidas (rubro);
GO

-- ==============================================================
-- SCHEMA: estadisticas  |  TABLA: AreasProtegidasJurisdiccion
-- Superficie y cantidad de áreas protegidas por jurisdicción.
-- El SP de importación inserta jurisdicciones nuevas y actualiza
-- datos cuando cambiaron; nunca elimina filas.
-- ==============================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AreasProtegidasJurisdiccion' AND schema_id = SCHEMA_ID('estadisticas'))
BEGIN
    PRINT 'Creando tabla estadisticas.AreasProtegidasJurisdiccion...';
    CREATE TABLE estadisticas.AreasProtegidasJurisdiccion (
        id_area                        INT IDENTITY(1,1) PRIMARY KEY,
        jurisdiccion                   NVARCHAR(100) NOT NULL,
        total_cantidad                 INT           NULL,
        ap_nac                         INT           NULL,
        ap_prov                        INT           NULL,
        ap_desig_inter                 INT           NULL,
        total_ha                       INT           NULL,
        terrestre_ha                   INT           NULL,
        marino_ha                      INT           NULL,
        porcentaje_terrestre_protegido DECIMAL(6,2)  NULL,
        fecha_carga                    DATETIME2     NOT NULL CONSTRAINT DF_AreasProtegidas_FechaCarga DEFAULT (SYSDATETIME()),
        fecha_actualizacion            DATETIME2     NULL,
        CONSTRAINT UQ_AreasProtegidas_Jurisdiccion UNIQUE (jurisdiccion)
    );
END
ELSE
    PRINT 'OK - Tabla estadisticas.AreasProtegidasJurisdiccion ya existe, se omite creación.';