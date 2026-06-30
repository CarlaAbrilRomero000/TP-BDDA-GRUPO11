/*
==============================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Fecha:       09/06/2026
Descripción: Stored Procedures para operaciones ABM (Alta,
             Baja, Modificación) de todas las tablas del
             sistema de gestión de Parques Nacionales.
             Ninguna operación ABM debe realizarse accediendo
             directamente a las tablas.
==============================================================
*/

USE ParquesNacionalesDB;
GO

-- ==============================================================
-- SCHEMA: parques  |  TABLA: TipoParque
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('parques.TipoParqueInsertar') AND type = 'P')
    PRINT 'Creando Procedure parques.TipoParqueInsertar...';
ELSE
    PRINT 'OK - Procedure parques.TipoParqueInsertar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE parques.TipoParqueInsertar
    @p_descripcion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF LTRIM(RTRIM(ISNULL(@p_descripcion, ''))) = ''
        SET @errores += N'- La descripción del tipo de parque es obligatoria.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM parques.TipoParque WHERE descripcion = @p_descripcion)
        SET @errores += N'- Ya existe un tipo de parque con esa descripción.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    INSERT INTO parques.TipoParque (descripcion) VALUES (@p_descripcion);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('parques.TipoParqueModificar') AND type = 'P')
    PRINT 'Creando Procedure parques.TipoParqueModificar...';
ELSE
    PRINT 'OK - Procedure parques.TipoParqueModificar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE parques.TipoParqueModificar
    @p_id_tipo_parque INT,
    @p_descripcion    VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM parques.TipoParque WHERE id_tipo_parque = @p_id_tipo_parque)
        SET @errores += N'- No existe un tipo de parque con el ID indicado.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_descripcion, ''))) = ''
        SET @errores += N'- La descripción es obligatoria.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM parques.TipoParque WHERE descripcion = @p_descripcion AND id_tipo_parque != @p_id_tipo_parque)
        SET @errores += N'- Ya existe otro tipo de parque con esa descripción.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    UPDATE parques.TipoParque SET descripcion = @p_descripcion WHERE id_tipo_parque = @p_id_tipo_parque;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('parques.TipoParqueEliminar') AND type = 'P')
    PRINT 'Creando Procedure parques.TipoParqueEliminar...';
ELSE
    PRINT 'OK - Procedure parques.TipoParqueEliminar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE parques.TipoParqueEliminar
    @p_id_tipo_parque INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM parques.TipoParque WHERE id_tipo_parque = @p_id_tipo_parque)
        SET @errores += N'- No existe un tipo de parque con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM parques.Parque WHERE id_tipo_parque = @p_id_tipo_parque)
        SET @errores += N'- No se puede eliminar: existen parques asociados a este tipo.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    DELETE FROM parques.TipoParque WHERE id_tipo_parque = @p_id_tipo_parque;
END
GO

-- ==============================================================
-- SCHEMA: ventas  |  TABLA: TipoVisitante
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('ventas.TipoVisitanteInsertar') AND type = 'P')
    PRINT 'Creando Procedure ventas.TipoVisitanteInsertar...';
ELSE
    PRINT 'OK - Procedure ventas.TipoVisitanteInsertar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE ventas.TipoVisitanteInsertar
    @p_descripcion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF LTRIM(RTRIM(ISNULL(@p_descripcion, ''))) = ''
        SET @errores += N'- La descripción es obligatoria.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE descripcion = @p_descripcion)
        SET @errores += N'- Ya existe un tipo de visitante con esa descripción.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    INSERT INTO ventas.TipoVisitante (descripcion) VALUES (@p_descripcion);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('ventas.TipoVisitanteModificar') AND type = 'P')
    PRINT 'Creando Procedure ventas.TipoVisitanteModificar...';
ELSE
    PRINT 'OK - Procedure ventas.TipoVisitanteModificar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE ventas.TipoVisitanteModificar
    @p_id_tipo_visitante INT,
    @p_descripcion       VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id_tipo_visitante = @p_id_tipo_visitante)
        SET @errores += N'- No existe un tipo de visitante con el ID indicado.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_descripcion, ''))) = ''
        SET @errores += N'- La descripción es obligatoria.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE descripcion = @p_descripcion AND id_tipo_visitante != @p_id_tipo_visitante)
        SET @errores += N'- Ya existe otro tipo de visitante con esa descripción.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    UPDATE ventas.TipoVisitante SET descripcion = @p_descripcion WHERE id_tipo_visitante = @p_id_tipo_visitante;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('ventas.TipoVisitanteEliminar') AND type = 'P')
    PRINT 'Creando Procedure ventas.TipoVisitanteEliminar...';
ELSE
    PRINT 'OK - Procedure ventas.TipoVisitanteEliminar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE ventas.TipoVisitanteEliminar
    @p_id_tipo_visitante INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id_tipo_visitante = @p_id_tipo_visitante)
        SET @errores += N'- No existe un tipo de visitante con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.HistorialPrecio WHERE id_tipo_visitante = @p_id_tipo_visitante)
        SET @errores += N'- No se puede eliminar: existen precios asociados a este tipo de visitante.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.TicketDetalle WHERE id_tipo_visitante = @p_id_tipo_visitante)
        SET @errores += N'- No se puede eliminar: existen detalles de ticket asociados a este tipo.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    DELETE FROM ventas.TipoVisitante WHERE id_tipo_visitante = @p_id_tipo_visitante;
END
GO

-- ==============================================================
-- SCHEMA: ventas  |  TABLA: FormaPago
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('ventas.FormaPagoInsertar') AND type = 'P')
    PRINT 'Creando Procedure ventas.FormaPagoInsertar...';
ELSE
    PRINT 'OK - Procedure ventas.FormaPagoInsertar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE ventas.FormaPagoInsertar
    @p_descripcion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF LTRIM(RTRIM(ISNULL(@p_descripcion, ''))) = ''
        SET @errores += N'- La descripción es obligatoria.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.FormaPago WHERE descripcion = @p_descripcion)
        SET @errores += N'- Ya existe una forma de pago con esa descripción.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    INSERT INTO ventas.FormaPago (descripcion) VALUES (@p_descripcion);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('ventas.FormaPagoModificar') AND type = 'P')
    PRINT 'Creando Procedure ventas.FormaPagoModificar...';
ELSE
    PRINT 'OK - Procedure ventas.FormaPagoModificar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE ventas.FormaPagoModificar
    @p_id_forma_pago INT,
    @p_descripcion   VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM ventas.FormaPago WHERE id_forma_pago = @p_id_forma_pago)
        SET @errores += N'- No existe una forma de pago con el ID indicado.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_descripcion, ''))) = ''
        SET @errores += N'- La descripción es obligatoria.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    UPDATE ventas.FormaPago SET descripcion = @p_descripcion WHERE id_forma_pago = @p_id_forma_pago;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('ventas.FormaPagoEliminar') AND type = 'P')
    PRINT 'Creando Procedure ventas.FormaPagoEliminar...';
ELSE
    PRINT 'OK - Procedure ventas.FormaPagoEliminar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE ventas.FormaPagoEliminar
    @p_id_forma_pago INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM ventas.FormaPago WHERE id_forma_pago = @p_id_forma_pago)
        SET @errores += N'- No existe una forma de pago con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.Ticket WHERE id_forma_pago = @p_id_forma_pago)
        SET @errores += N'- No se puede eliminar: existen tickets asociados a esta forma de pago.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    DELETE FROM ventas.FormaPago WHERE id_forma_pago = @p_id_forma_pago;
END
GO

-- ==============================================================
-- SCHEMA: turismo  |  TABLA: TipoAtraccion
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('turismo.TipoAtraccionInsertar') AND type = 'P')
    PRINT 'Creando Procedure turismo.TipoAtraccionInsertar...';
ELSE
    PRINT 'OK - Procedure turismo.TipoAtraccionInsertar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE turismo.TipoAtraccionInsertar
    @p_descripcion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF LTRIM(RTRIM(ISNULL(@p_descripcion, ''))) = ''
        SET @errores += N'- La descripción es obligatoria.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM turismo.TipoAtraccion WHERE descripcion = @p_descripcion)
        SET @errores += N'- Ya existe un tipo de atracción con esa descripción.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    INSERT INTO turismo.TipoAtraccion (descripcion) VALUES (@p_descripcion);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('turismo.TipoAtraccionModificar') AND type = 'P')
    PRINT 'Creando Procedure turismo.TipoAtraccionModificar...';
ELSE
    PRINT 'OK - Procedure turismo.TipoAtraccionModificar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE turismo.TipoAtraccionModificar
    @p_id_tipo_atraccion INT,
    @p_descripcion       VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM turismo.TipoAtraccion WHERE id_tipo_atraccion = @p_id_tipo_atraccion)
        SET @errores += N'- No existe un tipo de atracción con el ID indicado.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_descripcion, ''))) = ''
        SET @errores += N'- La descripción es obligatoria.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    UPDATE turismo.TipoAtraccion SET descripcion = @p_descripcion WHERE id_tipo_atraccion = @p_id_tipo_atraccion;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('turismo.TipoAtraccionEliminar') AND type = 'P')
    PRINT 'Creando Procedure turismo.TipoAtraccionEliminar...';
ELSE
    PRINT 'OK - Procedure turismo.TipoAtraccionEliminar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE turismo.TipoAtraccionEliminar
    @p_id_tipo_atraccion INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM turismo.TipoAtraccion WHERE id_tipo_atraccion = @p_id_tipo_atraccion)
        SET @errores += N'- No existe un tipo de atracción con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM turismo.AtraccionTour WHERE id_tipo_atraccion = @p_id_tipo_atraccion)
        SET @errores += N'- No se puede eliminar: existen atracciones/tours asociados a este tipo.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    DELETE FROM turismo.TipoAtraccion WHERE id_tipo_atraccion = @p_id_tipo_atraccion;
END
GO

-- ==============================================================
-- SCHEMA: personal  |  TABLA: Guardaparque
-- Baja lógica: se marca activo = 0
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('personal.GuardaparqueInsertar') AND type = 'P')
    PRINT 'Creando Procedure personal.GuardaparqueInsertar...';
ELSE
    PRINT 'OK - Procedure personal.GuardaparqueInsertar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE personal.GuardaparqueInsertar
    @p_nombre   VARCHAR(50),
    @p_apellido VARCHAR(50),
    @p_dni      VARCHAR(20),
    @p_email    VARCHAR(100) = NULL,
    @p_telefono VARCHAR(50)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF LTRIM(RTRIM(ISNULL(@p_nombre, ''))) = ''
        SET @errores += N'- El nombre es obligatorio.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_apellido, ''))) = ''
        SET @errores += N'- El apellido es obligatorio.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_dni, ''))) = ''
        SET @errores += N'- El DNI es obligatorio.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM personal.Guardaparque WHERE dni = @p_dni)
        SET @errores += N'- Ya existe un guardaparque registrado con ese DNI.' + CHAR(13);
    IF @p_email IS NOT NULL AND @p_email NOT LIKE '%@%.%'
        SET @errores += N'- El formato del email no es válido.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    INSERT INTO personal.Guardaparque (nombre, apellido, dni, email, telefono, activo)
    VALUES (@p_nombre, @p_apellido, @p_dni, @p_email, @p_telefono, 1);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('personal.GuardaparqueModificar') AND type = 'P')
    PRINT 'Creando Procedure personal.GuardaparqueModificar...';
ELSE
    PRINT 'OK - Procedure personal.GuardaparqueModificar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE personal.GuardaparqueModificar
    @p_id_guardaparque INT,
    @p_nombre          VARCHAR(50),
    @p_apellido        VARCHAR(50),
    @p_dni             VARCHAR(20),
    @p_email           VARCHAR(100) = NULL,
    @p_telefono        VARCHAR(50)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE id_guardaparque = @p_id_guardaparque)
        SET @errores += N'- No existe un guardaparque con el ID indicado.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_nombre, ''))) = ''
        SET @errores += N'- El nombre es obligatorio.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_apellido, ''))) = ''
        SET @errores += N'- El apellido es obligatorio.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_dni, ''))) = ''
        SET @errores += N'- El DNI es obligatorio.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM personal.Guardaparque WHERE dni = @p_dni AND id_guardaparque != @p_id_guardaparque)
        SET @errores += N'- Ya existe otro guardaparque con ese DNI.' + CHAR(13);
    IF @p_email IS NOT NULL AND @p_email NOT LIKE '%@%.%'
        SET @errores += N'- El formato del email no es válido.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    UPDATE personal.Guardaparque
    SET nombre = @p_nombre, apellido = @p_apellido, dni = @p_dni,
        email = @p_email, telefono = @p_telefono
    WHERE id_guardaparque = @p_id_guardaparque;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('personal.GuardaparqueEliminar') AND type = 'P')
    PRINT 'Creando Procedure personal.GuardaparqueEliminar...';
ELSE
    PRINT 'OK - Procedure personal.GuardaparqueEliminar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE personal.GuardaparqueEliminar
    @p_id_guardaparque INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE id_guardaparque = @p_id_guardaparque)
        SET @errores += N'- No existe un guardaparque con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM personal.Guardaparque WHERE id_guardaparque = @p_id_guardaparque AND activo = 0)
        SET @errores += N'- El guardaparque ya se encuentra inactivo.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    UPDATE personal.Guardaparque SET activo = 0 WHERE id_guardaparque = @p_id_guardaparque;
END
GO

-- ==============================================================
-- SCHEMA: turismo  |  TABLA: Guia
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('turismo.GuiaInsertar') AND type = 'P')
    PRINT 'Creando Procedure turismo.GuiaInsertar...';
ELSE
    PRINT 'OK - Procedure turismo.GuiaInsertar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE turismo.GuiaInsertar
    @p_nombre                VARCHAR(50),
    @p_apellido              VARCHAR(50),
    @p_dni                   VARCHAR(20),
    @p_especialidad          VARCHAR(100) = NULL,
    @p_vigencia_autorizacion DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF LTRIM(RTRIM(ISNULL(@p_nombre, ''))) = ''
        SET @errores += N'- El nombre es obligatorio.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_apellido, ''))) = ''
        SET @errores += N'- El apellido es obligatorio.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_dni, ''))) = ''
        SET @errores += N'- El DNI es obligatorio.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM turismo.Guia WHERE dni = @p_dni)
        SET @errores += N'- Ya existe un guía registrado con ese DNI.' + CHAR(13);
    IF @p_vigencia_autorizacion IS NULL
        SET @errores += N'- La vigencia de autorización es obligatoria.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    INSERT INTO turismo.Guia (nombre, apellido, dni, especialidad, vigencia_autorizacion)
    VALUES (@p_nombre, @p_apellido, @p_dni, @p_especialidad, @p_vigencia_autorizacion);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('turismo.GuiaModificar') AND type = 'P')
    PRINT 'Creando Procedure turismo.GuiaModificar...';
ELSE
    PRINT 'OK - Procedure turismo.GuiaModificar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE turismo.GuiaModificar
    @p_id_guia               INT,
    @p_nombre                VARCHAR(50),
    @p_apellido              VARCHAR(50),
    @p_dni                   VARCHAR(20),
    @p_especialidad          VARCHAR(100) = NULL,
    @p_vigencia_autorizacion DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM turismo.Guia WHERE id_guia = @p_id_guia)
        SET @errores += N'- No existe un guía con el ID indicado.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_nombre, ''))) = ''
        SET @errores += N'- El nombre es obligatorio.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_apellido, ''))) = ''
        SET @errores += N'- El apellido es obligatorio.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM turismo.Guia WHERE dni = @p_dni AND id_guia != @p_id_guia)
        SET @errores += N'- Ya existe otro guía con ese DNI.' + CHAR(13);
    IF @p_vigencia_autorizacion IS NULL
        SET @errores += N'- La vigencia de autorización es obligatoria.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    UPDATE turismo.Guia
    SET nombre = @p_nombre, apellido = @p_apellido, dni = @p_dni,
        especialidad = @p_especialidad, vigencia_autorizacion = @p_vigencia_autorizacion
    WHERE id_guia = @p_id_guia;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('turismo.GuiaEliminar') AND type = 'P')
    PRINT 'Creando Procedure turismo.GuiaEliminar...';
ELSE
    PRINT 'OK - Procedure turismo.GuiaEliminar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE turismo.GuiaEliminar
    @p_id_guia INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM turismo.Guia WHERE id_guia = @p_id_guia)
        SET @errores += N'- No existe un guía con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM turismo.GuiaParque WHERE id_guia = @p_id_guia)
        SET @errores += N'- No se puede eliminar: el guía tiene habilitaciones en parques registradas.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM turismo.TourGuia WHERE id_guia = @p_id_guia)
        SET @errores += N'- No se puede eliminar: el guía está asignado a uno o más tours.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    DELETE FROM turismo.Guia WHERE id_guia = @p_id_guia;
END
GO

-- ==============================================================
-- SCHEMA: parques  |  TABLA: Parque
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('parques.ParqueInsertar') AND type = 'P')
    PRINT 'Creando Procedure parques.ParqueInsertar...';
ELSE
    PRINT 'OK - Procedure parques.ParqueInsertar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE parques.ParqueInsertar
    @p_codigo_oficial VARCHAR(50),
    @p_nombre         VARCHAR(100),
    @p_ubicacion      VARCHAR(255),
    @p_superficie     DECIMAL(12,2),
    @p_id_tipo_parque INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF LTRIM(RTRIM(ISNULL(@p_codigo_oficial, ''))) = ''
        SET @errores += N'- El código oficial es obligatorio.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM parques.Parque WHERE codigo_oficial = @p_codigo_oficial)
        SET @errores += N'- Ya existe un parque con ese código oficial.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_nombre, ''))) = ''
        SET @errores += N'- El nombre del parque es obligatorio.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_ubicacion, ''))) = ''
        SET @errores += N'- La ubicación del parque es obligatoria.' + CHAR(13);
    IF ISNULL(@p_superficie, 0) <= 0
        SET @errores += N'- La superficie debe ser mayor a cero.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM parques.TipoParque WHERE id_tipo_parque = @p_id_tipo_parque)
        SET @errores += N'- El tipo de parque indicado no existe.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    INSERT INTO parques.Parque (codigo_oficial, nombre, ubicacion, superficie, id_tipo_parque)
    VALUES (@p_codigo_oficial, @p_nombre, @p_ubicacion, @p_superficie, @p_id_tipo_parque);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('parques.ParqueModificar') AND type = 'P')
    PRINT 'Creando Procedure parques.ParqueModificar...';
ELSE
    PRINT 'OK - Procedure parques.ParqueModificar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE parques.ParqueModificar
    @p_id_parque      INT,
    @p_codigo_oficial VARCHAR(50),
    @p_nombre         VARCHAR(100),
    @p_ubicacion      VARCHAR(255),
    @p_superficie     DECIMAL(12,2),
    @p_id_tipo_parque INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @p_id_parque)
        SET @errores += N'- No existe un parque con el ID indicado.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_codigo_oficial, ''))) = ''
        SET @errores += N'- El código oficial es obligatorio.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM parques.Parque WHERE codigo_oficial = @p_codigo_oficial AND id_parque != @p_id_parque)
        SET @errores += N'- Ya existe otro parque con ese código oficial.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_nombre, ''))) = ''
        SET @errores += N'- El nombre del parque es obligatorio.' + CHAR(13);
    IF ISNULL(@p_superficie, 0) <= 0
        SET @errores += N'- La superficie debe ser mayor a cero.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM parques.TipoParque WHERE id_tipo_parque = @p_id_tipo_parque)
        SET @errores += N'- El tipo de parque indicado no existe.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    UPDATE parques.Parque
    SET codigo_oficial = @p_codigo_oficial, nombre = @p_nombre, ubicacion = @p_ubicacion,
        superficie = @p_superficie, id_tipo_parque = @p_id_tipo_parque
    WHERE id_parque = @p_id_parque;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('parques.ParqueEliminar') AND type = 'P')
    PRINT 'Creando Procedure parques.ParqueEliminar...';
ELSE
    PRINT 'OK - Procedure parques.ParqueEliminar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE parques.ParqueEliminar
    @p_id_parque INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @p_id_parque)
        SET @errores += N'- No existe un parque con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM comercial.Concesion WHERE id_parque = @p_id_parque)
        SET @errores += N'- No se puede eliminar: el parque tiene concesiones registradas.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM personal.HistorialGuardaparque WHERE id_parque = @p_id_parque)
        SET @errores += N'- No se puede eliminar: el parque tiene historial de guardaparques.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM turismo.AtraccionTour WHERE id_parque = @p_id_parque)
        SET @errores += N'- No se puede eliminar: el parque tiene atracciones/tours registrados.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.HistorialPrecio WHERE id_parque = @p_id_parque)
        SET @errores += N'- No se puede eliminar: el parque tiene historial de precios registrado.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    DELETE FROM parques.Parque WHERE id_parque = @p_id_parque;
END
GO

-- ==============================================================
-- SCHEMA: comercial  |  TABLA: Empresa
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('comercial.EmpresaInsertar') AND type = 'P')
    PRINT 'Creando Procedure comercial.EmpresaInsertar...';
ELSE
    PRINT 'OK - Procedure comercial.EmpresaInsertar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE comercial.EmpresaInsertar
    @p_cuit         CHAR(11),
    @p_razon_social VARCHAR(150),
    @p_telefono     VARCHAR(30)  = NULL,
    @p_email        VARCHAR(100) = NULL,
    @p_direccion    VARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF LTRIM(RTRIM(ISNULL(@p_cuit, ''))) = ''
        SET @errores += N'- El CUIT es obligatorio.' + CHAR(13);
    IF ISNULL(@p_cuit, '') NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
        SET @errores += N'- El CUIT debe contener exactamente 11 dígitos numéricos.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM comercial.Empresa WHERE cuit = @p_cuit)
        SET @errores += N'- Ya existe una empresa registrada con ese CUIT.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_razon_social, ''))) = ''
        SET @errores += N'- La razón social es obligatoria.' + CHAR(13);
    IF @p_email IS NOT NULL AND @p_email NOT LIKE '%@%.%'
        SET @errores += N'- El formato del email no es válido.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    INSERT INTO comercial.Empresa (cuit, razon_social, telefono, email, direccion)
    VALUES (@p_cuit, @p_razon_social, @p_telefono, @p_email, @p_direccion);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('comercial.EmpresaModificar') AND type = 'P')
    PRINT 'Creando Procedure comercial.EmpresaModificar...';
ELSE
    PRINT 'OK - Procedure comercial.EmpresaModificar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE comercial.EmpresaModificar
    @p_id_empresa   INT,
    @p_cuit         CHAR(11),
    @p_razon_social VARCHAR(150),
    @p_telefono     VARCHAR(30)  = NULL,
    @p_email        VARCHAR(100) = NULL,
    @p_direccion    VARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM comercial.Empresa WHERE id_empresa = @p_id_empresa)
        SET @errores += N'- No existe una empresa con el ID indicado.' + CHAR(13);
    IF ISNULL(@p_cuit, '') NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
        SET @errores += N'- El CUIT debe contener exactamente 11 dígitos numéricos.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM comercial.Empresa WHERE cuit = @p_cuit AND id_empresa != @p_id_empresa)
        SET @errores += N'- Ya existe otra empresa registrada con ese CUIT.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_razon_social, ''))) = ''
        SET @errores += N'- La razón social es obligatoria.' + CHAR(13);
    IF @p_email IS NOT NULL AND @p_email NOT LIKE '%@%.%'
        SET @errores += N'- El formato del email no es válido.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    UPDATE comercial.Empresa
    SET cuit = @p_cuit, razon_social = @p_razon_social, telefono = @p_telefono,
        email = @p_email, direccion = @p_direccion
    WHERE id_empresa = @p_id_empresa;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('comercial.EmpresaEliminar') AND type = 'P')
    PRINT 'Creando Procedure comercial.EmpresaEliminar...';
ELSE
    PRINT 'OK - Procedure comercial.EmpresaEliminar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE comercial.EmpresaEliminar
    @p_id_empresa INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM comercial.Empresa WHERE id_empresa = @p_id_empresa)
        SET @errores += N'- No existe una empresa con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM comercial.Concesion WHERE id_empresa = @p_id_empresa)
        SET @errores += N'- No se puede eliminar: la empresa tiene concesiones registradas.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    DELETE FROM comercial.Empresa WHERE id_empresa = @p_id_empresa;
END
GO

-- ==============================================================
-- SCHEMA: personal  |  TABLA: HistorialGuardaparque
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('personal.HistorialGuardaparqueInsertar') AND type = 'P')
    PRINT 'Creando Procedure personal.HistorialGuardaparqueInsertar...';
ELSE
    PRINT 'OK - Procedure personal.HistorialGuardaparqueInsertar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE personal.HistorialGuardaparqueInsertar
    @p_id_guardaparque INT,
    @p_id_parque       INT,
    @p_fecha_ingreso   DATE,
    @p_fecha_egreso    DATE         = NULL,
    @p_motivo_egreso   VARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE id_guardaparque = @p_id_guardaparque)
        SET @errores += N'- El guardaparque indicado no existe.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @p_id_parque)
        SET @errores += N'- El parque indicado no existe.' + CHAR(13);
    IF @p_fecha_ingreso IS NULL
        SET @errores += N'- La fecha de ingreso es obligatoria.' + CHAR(13);
    IF @p_fecha_egreso IS NOT NULL AND @p_fecha_egreso < @p_fecha_ingreso
        SET @errores += N'- La fecha de egreso no puede ser anterior a la fecha de ingreso.' + CHAR(13);
    IF @p_fecha_egreso IS NULL AND @p_motivo_egreso IS NOT NULL
        SET @errores += N'- No se puede registrar motivo de egreso sin una fecha de egreso.' + CHAR(13);
    IF EXISTS (
        SELECT 1 FROM personal.HistorialGuardaparque
        WHERE id_guardaparque = @p_id_guardaparque AND fecha_egreso IS NULL
    )
        SET @errores += N'- El guardaparque ya tiene un período activo sin fecha de egreso. Ciérrelo antes de iniciar uno nuevo.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    INSERT INTO personal.HistorialGuardaparque (id_guardaparque, id_parque, fecha_ingreso, fecha_egreso, motivo_egreso)
    VALUES (@p_id_guardaparque, @p_id_parque, @p_fecha_ingreso, @p_fecha_egreso, @p_motivo_egreso);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('personal.HistorialGuardaparqueModificar') AND type = 'P')
    PRINT 'Creando Procedure personal.HistorialGuardaparqueModificar...';
ELSE
    PRINT 'OK - Procedure personal.HistorialGuardaparqueModificar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE personal.HistorialGuardaparqueModificar
    @p_id_historial  INT,
    @p_fecha_egreso  DATE         = NULL,
    @p_motivo_egreso VARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';
    DECLARE @fecha_ingreso DATE;

    SELECT @fecha_ingreso = fecha_ingreso
    FROM personal.HistorialGuardaparque
    WHERE id_historial = @p_id_historial;

    IF @fecha_ingreso IS NULL
        SET @errores += N'- No existe un historial con el ID indicado.' + CHAR(13);
    IF @p_fecha_egreso IS NOT NULL AND @fecha_ingreso IS NOT NULL AND @p_fecha_egreso < @fecha_ingreso
        SET @errores += N'- La fecha de egreso no puede ser anterior a la fecha de ingreso.' + CHAR(13);
    IF @p_fecha_egreso IS NULL AND @p_motivo_egreso IS NOT NULL
        SET @errores += N'- No se puede registrar motivo de egreso sin una fecha de egreso.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    UPDATE personal.HistorialGuardaparque
    SET fecha_egreso = @p_fecha_egreso, motivo_egreso = @p_motivo_egreso
    WHERE id_historial = @p_id_historial;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('personal.HistorialGuardaparqueEliminar') AND type = 'P')
    PRINT 'Creando Procedure personal.HistorialGuardaparqueEliminar...';
ELSE
    PRINT 'OK - Procedure personal.HistorialGuardaparqueEliminar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE personal.HistorialGuardaparqueEliminar
    @p_id_historial INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM personal.HistorialGuardaparque WHERE id_historial = @p_id_historial)
        SET @errores += N'- No existe un historial con el ID indicado.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    DELETE FROM personal.HistorialGuardaparque WHERE id_historial = @p_id_historial;
END
GO

-- ==============================================================
-- SCHEMA: turismo  |  TABLA: GuiaParque
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('turismo.GuiaParqueInsertar') AND type = 'P')
    PRINT 'Creando Procedure turismo.GuiaParqueInsertar...';
ELSE
    PRINT 'OK - Procedure turismo.GuiaParqueInsertar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE turismo.GuiaParqueInsertar
    @p_id_guia             INT,
    @p_id_parque           INT,
    @p_fecha_autorizacion  DATE,
    @p_estado_autorizacion BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM turismo.Guia WHERE id_guia = @p_id_guia)
        SET @errores += N'- El guía indicado no existe.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @p_id_parque)
        SET @errores += N'- El parque indicado no existe.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM turismo.GuiaParque WHERE id_guia = @p_id_guia AND id_parque = @p_id_parque)
        SET @errores += N'- El guía ya tiene una habilitación registrada para ese parque.' + CHAR(13);
    IF @p_fecha_autorizacion IS NULL
        SET @errores += N'- La fecha de autorización es obligatoria.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    INSERT INTO turismo.GuiaParque (id_guia, id_parque, fecha_autorizacion, estado_autorizacion)
    VALUES (@p_id_guia, @p_id_parque, @p_fecha_autorizacion, @p_estado_autorizacion);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('turismo.GuiaParqueModificar') AND type = 'P')
    PRINT 'Creando Procedure turismo.GuiaParqueModificar...';
ELSE
    PRINT 'OK - Procedure turismo.GuiaParqueModificar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE turismo.GuiaParqueModificar
    @p_id_guia             INT,
    @p_id_parque           INT,
    @p_fecha_autorizacion  DATE,
    @p_estado_autorizacion BIT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM turismo.GuiaParque WHERE id_guia = @p_id_guia AND id_parque = @p_id_parque)
        SET @errores += N'- No existe una habilitación para el guía y parque indicados.' + CHAR(13);
    IF @p_fecha_autorizacion IS NULL
        SET @errores += N'- La fecha de autorización es obligatoria.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    UPDATE turismo.GuiaParque
    SET fecha_autorizacion = @p_fecha_autorizacion, estado_autorizacion = @p_estado_autorizacion
    WHERE id_guia = @p_id_guia AND id_parque = @p_id_parque;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('turismo.GuiaParqueEliminar') AND type = 'P')
    PRINT 'Creando Procedure turismo.GuiaParqueEliminar...';
ELSE
    PRINT 'OK - Procedure turismo.GuiaParqueEliminar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE turismo.GuiaParqueEliminar
    @p_id_guia   INT,
    @p_id_parque INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM turismo.GuiaParque WHERE id_guia = @p_id_guia AND id_parque = @p_id_parque)
        SET @errores += N'- No existe una habilitación para el guía y parque indicados.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    DELETE FROM turismo.GuiaParque WHERE id_guia = @p_id_guia AND id_parque = @p_id_parque;
END
GO

-- ==============================================================
-- SCHEMA: turismo  |  TABLA: AtraccionTour
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('turismo.AtraccionTourInsertar') AND type = 'P')
    PRINT 'Creando Procedure turismo.AtraccionTourInsertar...';
ELSE
    PRINT 'OK - Procedure turismo.AtraccionTourInsertar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE turismo.AtraccionTourInsertar
    @p_id_parque         INT,
    @p_id_tipo_atraccion INT,
    @p_nombre            VARCHAR(100),
    @p_costo             DECIMAL(12,2),
    @p_cupo_maximo       INT,
    @p_duracion          INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @p_id_parque)
        SET @errores += N'- El parque indicado no existe.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM turismo.TipoAtraccion WHERE id_tipo_atraccion = @p_id_tipo_atraccion)
        SET @errores += N'- El tipo de atracción indicado no existe.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_nombre, ''))) = ''
        SET @errores += N'- El nombre de la atracción/tour es obligatorio.' + CHAR(13);
    IF ISNULL(@p_costo, -1) < 0
        SET @errores += N'- El costo no puede ser negativo (use 0 para atracciones gratuitas).' + CHAR(13);
    IF ISNULL(@p_cupo_maximo, 0) <= 0
        SET @errores += N'- El cupo máximo debe ser mayor a cero.' + CHAR(13);
    IF ISNULL(@p_duracion, 0) <= 0
        SET @errores += N'- La duración debe ser mayor a cero.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    INSERT INTO turismo.AtraccionTour (id_parque, id_tipo_atraccion, nombre, costo, cupo_maximo, duracion)
    VALUES (@p_id_parque, @p_id_tipo_atraccion, @p_nombre, @p_costo, @p_cupo_maximo, @p_duracion);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('turismo.AtraccionTourModificar') AND type = 'P')
    PRINT 'Creando Procedure turismo.AtraccionTourModificar...';
ELSE
    PRINT 'OK - Procedure turismo.AtraccionTourModificar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE turismo.AtraccionTourModificar
    @p_id_atraccion_tour INT,
    @p_id_tipo_atraccion INT,
    @p_nombre            VARCHAR(100),
    @p_costo             DECIMAL(12,2),
    @p_cupo_maximo       INT,
    @p_duracion          INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM turismo.AtraccionTour WHERE id_atraccion_tour = @p_id_atraccion_tour)
        SET @errores += N'- No existe una atracción/tour con el ID indicado.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM turismo.TipoAtraccion WHERE id_tipo_atraccion = @p_id_tipo_atraccion)
        SET @errores += N'- El tipo de atracción indicado no existe.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_nombre, ''))) = ''
        SET @errores += N'- El nombre es obligatorio.' + CHAR(13);
    IF ISNULL(@p_costo, -1) < 0
        SET @errores += N'- El costo no puede ser negativo.' + CHAR(13);
    IF ISNULL(@p_cupo_maximo, 0) <= 0
        SET @errores += N'- El cupo máximo debe ser mayor a cero.' + CHAR(13);
    IF ISNULL(@p_duracion, 0) <= 0
        SET @errores += N'- La duración debe ser mayor a cero.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    UPDATE turismo.AtraccionTour
    SET id_tipo_atraccion = @p_id_tipo_atraccion, nombre = @p_nombre, costo = @p_costo,
        cupo_maximo = @p_cupo_maximo, duracion = @p_duracion
    WHERE id_atraccion_tour = @p_id_atraccion_tour;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('turismo.AtraccionTourEliminar') AND type = 'P')
    PRINT 'Creando Procedure turismo.AtraccionTourEliminar...';
ELSE
    PRINT 'OK - Procedure turismo.AtraccionTourEliminar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE turismo.AtraccionTourEliminar
    @p_id_atraccion_tour INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM turismo.AtraccionTour WHERE id_atraccion_tour = @p_id_atraccion_tour)
        SET @errores += N'- No existe una atracción/tour con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.TicketDetalle WHERE id_atraccion_tour = @p_id_atraccion_tour)
        SET @errores += N'- No se puede eliminar: la atracción/tour tiene ventas registradas.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM turismo.TourGuia WHERE id_atraccion_tour = @p_id_atraccion_tour)
        SET @errores += N'- No se puede eliminar: la atracción/tour tiene guías asignados.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    DELETE FROM turismo.AtraccionTour WHERE id_atraccion_tour = @p_id_atraccion_tour;
END
GO

-- ==============================================================
-- SCHEMA: turismo  |  TABLA: TourGuia
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('turismo.TourGuiaInsertar') AND type = 'P')
    PRINT 'Creando Procedure turismo.TourGuiaInsertar...';
ELSE
    PRINT 'OK - Procedure turismo.TourGuiaInsertar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE turismo.TourGuiaInsertar
    @p_id_atraccion_tour INT,
    @p_id_guia           INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';
    DECLARE @id_parque_tour INT;

    SELECT @id_parque_tour = id_parque
    FROM turismo.AtraccionTour
    WHERE id_atraccion_tour = @p_id_atraccion_tour;

    IF @id_parque_tour IS NULL
        SET @errores += N'- La atracción/tour indicada no existe.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM turismo.Guia WHERE id_guia = @p_id_guia)
        SET @errores += N'- El guía indicado no existe.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM turismo.TourGuia WHERE id_atraccion_tour = @p_id_atraccion_tour AND id_guia = @p_id_guia)
        SET @errores += N'- El guía ya está asignado a esa atracción/tour.' + CHAR(13);
    IF @id_parque_tour IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM turismo.GuiaParque
        WHERE id_guia = @p_id_guia AND id_parque = @id_parque_tour AND estado_autorizacion = 1
    )
        SET @errores += N'- El guía no tiene habilitación activa en el parque al que pertenece el tour.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    INSERT INTO turismo.TourGuia (id_atraccion_tour, id_guia)
    VALUES (@p_id_atraccion_tour, @p_id_guia);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('turismo.TourGuiaEliminar') AND type = 'P')
    PRINT 'Creando Procedure turismo.TourGuiaEliminar...';
ELSE
    PRINT 'OK - Procedure turismo.TourGuiaEliminar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE turismo.TourGuiaEliminar
    @p_id_atraccion_tour INT,
    @p_id_guia           INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM turismo.TourGuia WHERE id_atraccion_tour = @p_id_atraccion_tour AND id_guia = @p_id_guia)
        SET @errores += N'- No existe la asignación entre el guía y la atracción/tour indicados.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    DELETE FROM turismo.TourGuia WHERE id_atraccion_tour = @p_id_atraccion_tour AND id_guia = @p_id_guia;
END
GO

-- ==============================================================
-- SCHEMA: ventas  |  TABLA: HistorialPrecio
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('ventas.HistorialPrecioInsertar') AND type = 'P')
    PRINT 'Creando Procedure ventas.HistorialPrecioInsertar...';
ELSE
    PRINT 'OK - Procedure ventas.HistorialPrecioInsertar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE ventas.HistorialPrecioInsertar
    @p_precio            DECIMAL(12,2),
    @p_fecha_desde       DATE,
    @p_id_parque         INT,
    @p_id_tipo_visitante INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @p_id_parque)
        SET @errores += N'- El parque indicado no existe.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id_tipo_visitante = @p_id_tipo_visitante)
        SET @errores += N'- El tipo de visitante indicado no existe.' + CHAR(13);
    IF ISNULL(@p_precio, -1) < 0
        SET @errores += N'- El precio no puede ser negativo.' + CHAR(13);
    IF @p_fecha_desde IS NULL
        SET @errores += N'- La fecha de vigencia es obligatoria.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    INSERT INTO ventas.HistorialPrecio (precio, fecha_desde, id_parque, id_tipo_visitante)
    VALUES (@p_precio, @p_fecha_desde, @p_id_parque, @p_id_tipo_visitante);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('ventas.HistorialPrecioModificar') AND type = 'P')
    PRINT 'Creando Procedure ventas.HistorialPrecioModificar...';
ELSE
    PRINT 'OK - Procedure ventas.HistorialPrecioModificar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE ventas.HistorialPrecioModificar
    @p_id_historial_precio INT,
    @p_precio              DECIMAL(12,2),
    @p_fecha_desde         DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM ventas.HistorialPrecio WHERE id_historial_precio = @p_id_historial_precio)
        SET @errores += N'- No existe un registro de precio con el ID indicado.' + CHAR(13);
    IF ISNULL(@p_precio, -1) < 0
        SET @errores += N'- El precio no puede ser negativo.' + CHAR(13);
    IF @p_fecha_desde IS NULL
        SET @errores += N'- La fecha de vigencia es obligatoria.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    UPDATE ventas.HistorialPrecio
    SET precio = @p_precio, fecha_desde = @p_fecha_desde
    WHERE id_historial_precio = @p_id_historial_precio;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('ventas.HistorialPrecioEliminar') AND type = 'P')
    PRINT 'Creando Procedure ventas.HistorialPrecioEliminar...';
ELSE
    PRINT 'OK - Procedure ventas.HistorialPrecioEliminar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE ventas.HistorialPrecioEliminar
    @p_id_historial_precio INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM ventas.HistorialPrecio WHERE id_historial_precio = @p_id_historial_precio)
        SET @errores += N'- No existe un registro de precio con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.TicketDetalle WHERE id_historial_precio = @p_id_historial_precio)
        SET @errores += N'- No se puede eliminar: el precio está referenciado en detalles de tickets.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    DELETE FROM ventas.HistorialPrecio WHERE id_historial_precio = @p_id_historial_precio;
END
GO

-- ==============================================================
-- SCHEMA: comercial  |  TABLA: Concesion
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('comercial.ConcesionInsertar') AND type = 'P')
    PRINT 'Creando Procedure comercial.ConcesionInsertar...';
ELSE
    PRINT 'OK - Procedure comercial.ConcesionInsertar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE comercial.ConcesionInsertar
    @p_id_parque      INT,
    @p_id_empresa     INT,
    @p_tipo_actividad VARCHAR(100),
    @p_fecha_inicio   DATE,
    @p_fecha_fin      DATE,
    @p_canon_mensual  DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @p_id_parque)
        SET @errores += N'- El parque indicado no existe.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM comercial.Empresa WHERE id_empresa = @p_id_empresa)
        SET @errores += N'- La empresa indicada no existe.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_tipo_actividad, ''))) = ''
        SET @errores += N'- El tipo de actividad es obligatorio.' + CHAR(13);
    IF @p_fecha_inicio IS NULL OR @p_fecha_fin IS NULL
        SET @errores += N'- Las fechas de inicio y fin son obligatorias.' + CHAR(13);
    IF @p_fecha_inicio IS NOT NULL AND @p_fecha_fin IS NOT NULL AND @p_fecha_fin < @p_fecha_inicio
        SET @errores += N'- La fecha de fin no puede ser anterior a la fecha de inicio.' + CHAR(13);
    IF ISNULL(@p_canon_mensual, 0) <= 0
        SET @errores += N'- El canon mensual debe ser mayor a cero.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    INSERT INTO comercial.Concesion (id_parque, id_empresa, tipo_actividad, fecha_inicio, fecha_fin, canon_mensual)
    VALUES (@p_id_parque, @p_id_empresa, @p_tipo_actividad, @p_fecha_inicio, @p_fecha_fin, @p_canon_mensual);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('comercial.ConcesionModificar') AND type = 'P')
    PRINT 'Creando Procedure comercial.ConcesionModificar...';
ELSE
    PRINT 'OK - Procedure comercial.ConcesionModificar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE comercial.ConcesionModificar
    @p_id_concesion   INT,
    @p_tipo_actividad VARCHAR(100),
    @p_fecha_inicio   DATE,
    @p_fecha_fin      DATE,
    @p_canon_mensual  DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM comercial.Concesion WHERE id_concesion = @p_id_concesion)
        SET @errores += N'- No existe una concesión con el ID indicado.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_tipo_actividad, ''))) = ''
        SET @errores += N'- El tipo de actividad es obligatorio.' + CHAR(13);
    IF @p_fecha_inicio IS NOT NULL AND @p_fecha_fin IS NOT NULL AND @p_fecha_fin < @p_fecha_inicio
        SET @errores += N'- La fecha de fin no puede ser anterior a la fecha de inicio.' + CHAR(13);
    IF ISNULL(@p_canon_mensual, 0) <= 0
        SET @errores += N'- El canon mensual debe ser mayor a cero.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    UPDATE comercial.Concesion
    SET tipo_actividad = @p_tipo_actividad, fecha_inicio = @p_fecha_inicio,
        fecha_fin = @p_fecha_fin, canon_mensual = @p_canon_mensual
    WHERE id_concesion = @p_id_concesion;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('comercial.ConcesionEliminar') AND type = 'P')
    PRINT 'Creando Procedure comercial.ConcesionEliminar...';
ELSE
    PRINT 'OK - Procedure comercial.ConcesionEliminar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE comercial.ConcesionEliminar
    @p_id_concesion INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM comercial.Concesion WHERE id_concesion = @p_id_concesion)
        SET @errores += N'- No existe una concesión con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM comercial.ObligacionCanon WHERE id_concesion = @p_id_concesion)
        SET @errores += N'- No se puede eliminar: la concesión tiene obligaciones de canon registradas.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    DELETE FROM comercial.Concesion WHERE id_concesion = @p_id_concesion;
END
GO

-- ==============================================================
-- SCHEMA: comercial  |  TABLA: ObligacionCanon
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('comercial.ObligacionCanonInsertar') AND type = 'P')
    PRINT 'Creando Procedure comercial.ObligacionCanonInsertar...';
ELSE
    PRINT 'OK - Procedure comercial.ObligacionCanonInsertar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE comercial.ObligacionCanonInsertar
    @p_id_concesion      INT,
    @p_mes               TINYINT,
    @p_anio              SMALLINT,
    @p_monto_obligado    DECIMAL(12,2),
    @p_estado            VARCHAR(20),
    @p_fecha_vencimiento DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM comercial.Concesion WHERE id_concesion = @p_id_concesion)
        SET @errores += N'- La concesión indicada no existe.' + CHAR(13);
    IF ISNULL(@p_mes, 0) NOT BETWEEN 1 AND 12
        SET @errores += N'- El mes debe estar entre 1 y 12.' + CHAR(13);
    IF ISNULL(@p_anio, 0) NOT BETWEEN 2000 AND 2100
        SET @errores += N'- El año debe estar entre 2000 y 2100.' + CHAR(13);
    IF ISNULL(@p_monto_obligado, 0) <= 0
        SET @errores += N'- El monto obligado debe ser mayor a cero.' + CHAR(13);
    IF ISNULL(@p_estado, '') NOT IN ('PENDIENTE', 'PAGADO', 'VENCIDO', 'PARCIAL')
        SET @errores += N'- El estado debe ser uno de los siguientes: PENDIENTE, PAGADO, VENCIDO, PARCIAL.' + CHAR(13);
    IF @p_fecha_vencimiento IS NULL
        SET @errores += N'- La fecha de vencimiento es obligatoria.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM comercial.ObligacionCanon WHERE id_concesion = @p_id_concesion AND anio = @p_anio AND mes = @p_mes)
        SET @errores += N'- Ya existe una obligación para esa concesión en el período indicado.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    INSERT INTO comercial.ObligacionCanon (id_concesion, mes, anio, monto_obligado, estado, fecha_vencimiento)
    VALUES (@p_id_concesion, @p_mes, @p_anio, @p_monto_obligado, @p_estado, @p_fecha_vencimiento);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('comercial.ObligacionCanonModificar') AND type = 'P')
    PRINT 'Creando Procedure comercial.ObligacionCanonModificar...';
ELSE
    PRINT 'OK - Procedure comercial.ObligacionCanonModificar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE comercial.ObligacionCanonModificar
    @p_id_obligacion     INT,
    @p_monto_obligado    DECIMAL(12,2),
    @p_estado            VARCHAR(20),
    @p_fecha_vencimiento DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM comercial.ObligacionCanon WHERE id_obligacion = @p_id_obligacion)
        SET @errores += N'- No existe una obligación con el ID indicado.' + CHAR(13);
    IF ISNULL(@p_monto_obligado, 0) <= 0
        SET @errores += N'- El monto obligado debe ser mayor a cero.' + CHAR(13);
    IF ISNULL(@p_estado, '') NOT IN ('PENDIENTE', 'PAGADO', 'VENCIDO', 'PARCIAL')
        SET @errores += N'- El estado debe ser uno de los siguientes: PENDIENTE, PAGADO, VENCIDO, PARCIAL.' + CHAR(13);
    IF @p_fecha_vencimiento IS NULL
        SET @errores += N'- La fecha de vencimiento es obligatoria.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    UPDATE comercial.ObligacionCanon
    SET monto_obligado = @p_monto_obligado, estado = @p_estado, fecha_vencimiento = @p_fecha_vencimiento
    WHERE id_obligacion = @p_id_obligacion;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('comercial.ObligacionCanonEliminar') AND type = 'P')
    PRINT 'Creando Procedure comercial.ObligacionCanonEliminar...';
ELSE
    PRINT 'OK - Procedure comercial.ObligacionCanonEliminar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE comercial.ObligacionCanonEliminar
    @p_id_obligacion INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM comercial.ObligacionCanon WHERE id_obligacion = @p_id_obligacion)
        SET @errores += N'- No existe una obligación con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM comercial.PagoCanon WHERE id_obligacion = @p_id_obligacion)
        SET @errores += N'- No se puede eliminar: la obligación tiene pagos registrados.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    DELETE FROM comercial.ObligacionCanon WHERE id_obligacion = @p_id_obligacion;
END
GO

-- ==============================================================
-- SCHEMA: comercial  |  TABLA: PagoCanon
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('comercial.PagoCanonInsertar') AND type = 'P')
    PRINT 'Creando Procedure comercial.PagoCanonInsertar...';
ELSE
    PRINT 'OK - Procedure comercial.PagoCanonInsertar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE comercial.PagoCanonInsertar
    @p_id_obligacion INT,
    @p_fecha_pago    DATE,
    @p_monto_pagado  DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM comercial.ObligacionCanon WHERE id_obligacion = @p_id_obligacion)
        SET @errores += N'- La obligación indicada no existe.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM comercial.ObligacionCanon WHERE id_obligacion = @p_id_obligacion AND estado = 'PAGADO')
        SET @errores += N'- La obligación ya se encuentra completamente pagada.' + CHAR(13);
    IF @p_fecha_pago IS NULL
        SET @errores += N'- La fecha de pago es obligatoria.' + CHAR(13);
    IF ISNULL(@p_monto_pagado, 0) <= 0
        SET @errores += N'- El monto pagado debe ser mayor a cero.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    INSERT INTO comercial.PagoCanon (id_obligacion, fecha_pago, monto_pagado)
    VALUES (@p_id_obligacion, @p_fecha_pago, @p_monto_pagado);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('comercial.PagoCanonEliminar') AND type = 'P')
    PRINT 'Creando Procedure comercial.PagoCanonEliminar...';
ELSE
    PRINT 'OK - Procedure comercial.PagoCanonEliminar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE comercial.PagoCanonEliminar
    @p_id_pago INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM comercial.PagoCanon WHERE id_pago = @p_id_pago)
        SET @errores += N'- No existe un pago con el ID indicado.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    DELETE FROM comercial.PagoCanon WHERE id_pago = @p_id_pago;
END
GO

-- ==============================================================
-- SCHEMA: ventas  |  TABLA: Ticket
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('ventas.TicketInsertar') AND type = 'P')
    PRINT 'Creando Procedure ventas.TicketInsertar...';
ELSE
    PRINT 'OK - Procedure ventas.TicketInsertar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE ventas.TicketInsertar
    @p_punto_venta   CHAR(4),
    @p_numero        VARCHAR(50),
    @p_fecha_venta   DATETIME2,
    @p_id_forma_pago INT,
    @p_total         DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF ISNULL(@p_punto_venta, '') NOT LIKE '[0-9][0-9][0-9][0-9]'
        SET @errores += N'- El punto de venta debe contener exactamente 4 dígitos numéricos.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_numero, ''))) = ''
        SET @errores += N'- El número de ticket es obligatorio.' + CHAR(13);
    IF @p_fecha_venta IS NULL
        SET @errores += N'- La fecha de venta es obligatoria.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM ventas.FormaPago WHERE id_forma_pago = @p_id_forma_pago)
        SET @errores += N'- La forma de pago indicada no existe.' + CHAR(13);
    IF ISNULL(@p_total, -1) < 0
        SET @errores += N'- El total no puede ser negativo.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    INSERT INTO ventas.Ticket (punto_venta, numero, fecha_venta, id_forma_pago, total)
    VALUES (@p_punto_venta, @p_numero, @p_fecha_venta, @p_id_forma_pago, @p_total);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('ventas.TicketModificar') AND type = 'P')
    PRINT 'Creando Procedure ventas.TicketModificar...';
ELSE
    PRINT 'OK - Procedure ventas.TicketModificar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE ventas.TicketModificar
    @p_id_ticket     INT,
    @p_id_forma_pago INT,
    @p_total         DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM ventas.Ticket WHERE id_ticket = @p_id_ticket)
        SET @errores += N'- No existe un ticket con el ID indicado.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM ventas.FormaPago WHERE id_forma_pago = @p_id_forma_pago)
        SET @errores += N'- La forma de pago indicada no existe.' + CHAR(13);
    IF ISNULL(@p_total, -1) < 0
        SET @errores += N'- El total no puede ser negativo.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    UPDATE ventas.Ticket
    SET id_forma_pago = @p_id_forma_pago, total = @p_total
    WHERE id_ticket = @p_id_ticket;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('ventas.TicketEliminar') AND type = 'P')
    PRINT 'Creando Procedure ventas.TicketEliminar...';
ELSE
    PRINT 'OK - Procedure ventas.TicketEliminar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE ventas.TicketEliminar
    @p_id_ticket INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM ventas.Ticket WHERE id_ticket = @p_id_ticket)
        SET @errores += N'- No existe un ticket con el ID indicado.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.TicketDetalle WHERE id_ticket = @p_id_ticket)
        SET @errores += N'- No se puede eliminar: el ticket tiene líneas de detalle asociadas.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    DELETE FROM ventas.Ticket WHERE id_ticket = @p_id_ticket;
END
GO

-- ==============================================================
-- SCHEMA: ventas  |  TABLA: TicketDetalle
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('ventas.TicketDetalleInsertar') AND type = 'P')
    PRINT 'Creando Procedure ventas.TicketDetalleInsertar...';
ELSE
    PRINT 'OK - Procedure ventas.TicketDetalleInsertar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE ventas.TicketDetalleInsertar
    @p_id_ticket           INT,
    @p_id_parque           INT,
    @p_id_historial_precio INT          = NULL,
    @p_id_tipo_visitante   INT          = NULL,
    @p_id_atraccion_tour   INT          = NULL,
    @p_fecha_acceso        DATE,
    @p_cantidad            INT,
    @p_precio_unitario     DECIMAL(12,2),
    @p_subtotal            DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM ventas.Ticket WHERE id_ticket = @p_id_ticket)
        SET @errores += N'- El ticket indicado no existe.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @p_id_parque)
        SET @errores += N'- El parque indicado no existe.' + CHAR(13);
    IF @p_id_historial_precio IS NULL AND @p_id_atraccion_tour IS NULL
        SET @errores += N'- El detalle debe corresponder a una entrada (precio) o a una atracción/tour.' + CHAR(13);
    IF @p_id_historial_precio IS NOT NULL AND NOT EXISTS (SELECT 1 FROM ventas.HistorialPrecio WHERE id_historial_precio = @p_id_historial_precio)
        SET @errores += N'- El historial de precio indicado no existe.' + CHAR(13);
    IF @p_id_tipo_visitante IS NOT NULL AND NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id_tipo_visitante = @p_id_tipo_visitante)
        SET @errores += N'- El tipo de visitante indicado no existe.' + CHAR(13);
    IF @p_id_atraccion_tour IS NOT NULL AND NOT EXISTS (SELECT 1 FROM turismo.AtraccionTour WHERE id_atraccion_tour = @p_id_atraccion_tour)
        SET @errores += N'- La atracción/tour indicada no existe.' + CHAR(13);
    IF @p_fecha_acceso IS NULL
        SET @errores += N'- La fecha de acceso es obligatoria.' + CHAR(13);
    IF ISNULL(@p_cantidad, 0) <= 0
        SET @errores += N'- La cantidad debe ser mayor a cero.' + CHAR(13);
    IF ISNULL(@p_precio_unitario, -1) < 0
        SET @errores += N'- El precio unitario no puede ser negativo.' + CHAR(13);
    IF ISNULL(@p_subtotal, -1) < 0
        SET @errores += N'- El subtotal no puede ser un monto negativo.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    INSERT INTO ventas.TicketDetalle
        (id_ticket, id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour,
         fecha_acceso, cantidad, precio_unitario, subtotal)
    VALUES
        (@p_id_ticket, @p_id_parque, @p_id_historial_precio, @p_id_tipo_visitante, @p_id_atraccion_tour,
         @p_fecha_acceso, @p_cantidad, @p_precio_unitario, @p_subtotal);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('ventas.TicketDetalleModificar') AND type = 'P')
    PRINT 'Creando Procedure ventas.TicketDetalleModificar...';
ELSE
    PRINT 'OK - Procedure ventas.TicketDetalleModificar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE ventas.TicketDetalleModificar
    @p_id_detalle      INT,
    @p_cantidad        INT,
    @p_precio_unitario DECIMAL(12,2),
    @p_subtotal        DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM ventas.TicketDetalle WHERE id_detalle = @p_id_detalle)
        SET @errores += N'- No existe un detalle de ticket con el ID indicado.' + CHAR(13);
    IF ISNULL(@p_cantidad, 0) <= 0
        SET @errores += N'- La cantidad debe ser mayor a cero.' + CHAR(13);
    IF ISNULL(@p_precio_unitario, -1) < 0
        SET @errores += N'- El precio unitario no puede ser negativo.' + CHAR(13);
    IF ISNULL(@p_subtotal, -1) < 0
        SET @errores += N'- El subtotal no puede ser un monto negativo.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    UPDATE ventas.TicketDetalle
    SET cantidad = @p_cantidad, precio_unitario = @p_precio_unitario, subtotal = @p_subtotal
    WHERE id_detalle = @p_id_detalle;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('ventas.TicketDetalleEliminar') AND type = 'P')
    PRINT 'Creando Procedure ventas.TicketDetalleEliminar...';
ELSE
    PRINT 'OK - Procedure ventas.TicketDetalleEliminar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE ventas.TicketDetalleEliminar
    @p_id_detalle INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM ventas.TicketDetalle WHERE id_detalle = @p_id_detalle)
        SET @errores += N'- No existe un detalle de ticket con el ID indicado.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    DELETE FROM ventas.TicketDetalle WHERE id_detalle = @p_id_detalle;
END
GO

-- ==============================================================
-- SCHEMA: estadisticas  |  TABLA: ErroresImportacion
-- Solo Insertar: es un log de auditoría (no se modifica ni elimina)
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('estadisticas.ErroresImportacionInsertar') AND type = 'P')
    PRINT 'Creando Procedure estadisticas.ErroresImportacionInsertar...';
ELSE
    PRINT 'OK - Procedure estadisticas.ErroresImportacionInsertar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE estadisticas.ErroresImportacionInsertar
    @p_archivo_origen          VARCHAR(500) = NULL,
    @p_motivo_error            VARCHAR(500),
    @p_indice_tiempo_valor     VARCHAR(500) = NULL,
    @p_region_destino_valor    VARCHAR(500) = NULL,
    @p_origen_visitantes_valor VARCHAR(500) = NULL,
    @p_visitas_valor           VARCHAR(500) = NULL,
    @p_observaciones_valor     VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF LTRIM(RTRIM(ISNULL(@p_motivo_error, ''))) = ''
        SET @errores += N'- El motivo de error es obligatorio.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    INSERT INTO estadisticas.ErroresImportacion
        (archivo_origen, motivo_error, indice_tiempo_valor, region_destino_valor,
         origen_visitantes_valor, visitas_valor, observaciones_valor)
    VALUES
        (@p_archivo_origen, @p_motivo_error, @p_indice_tiempo_valor, @p_region_destino_valor,
         @p_origen_visitantes_valor, @p_visitas_valor, @p_observaciones_valor);
END
GO

-- ==============================================================
-- SCHEMA: estadisticas  |  TABLA: VisitantesParques
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('estadisticas.VisitantesParquesInsertar') AND type = 'P')
    PRINT 'Creando Procedure estadisticas.VisitantesParquesInsertar...';
ELSE
    PRINT 'OK - Procedure estadisticas.VisitantesParquesInsertar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE estadisticas.VisitantesParquesInsertar
    @p_indice_tiempo     DATE,
    @p_region_destino    VARCHAR(100),
    @p_origen_visitantes VARCHAR(50),
    @p_visitas           INT,
    @p_observaciones     VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF @p_indice_tiempo IS NULL
        SET @errores += N'- La fecha (indice_tiempo) es obligatoria.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_region_destino, ''))) = ''
        SET @errores += N'- La región de destino es obligatoria.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_origen_visitantes, ''))) = ''
        SET @errores += N'- El origen de visitantes es obligatorio.' + CHAR(13);
    IF ISNULL(@p_visitas, -1) < 0
        SET @errores += N'- La cantidad de visitas no puede ser negativa.' + CHAR(13);
    IF EXISTS (
        SELECT 1 FROM estadisticas.VisitantesParques
        WHERE indice_tiempo = @p_indice_tiempo
          AND region_destino = @p_region_destino
          AND origen_visitantes = @p_origen_visitantes
    )
        SET @errores += N'- Ya existe un registro con esa combinación de fecha, región y origen.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    INSERT INTO estadisticas.VisitantesParques
        (indice_tiempo, region_destino, origen_visitantes, visitas, observaciones)
    VALUES
        (@p_indice_tiempo, @p_region_destino, @p_origen_visitantes, @p_visitas, @p_observaciones);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('estadisticas.VisitantesParquesModificar') AND type = 'P')
    PRINT 'Creando Procedure estadisticas.VisitantesParquesModificar...';
ELSE
    PRINT 'OK - Procedure estadisticas.VisitantesParquesModificar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE estadisticas.VisitantesParquesModificar
    @p_id_visitantes_parque INT,
    @p_visitas              INT,
    @p_observaciones        VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM estadisticas.VisitantesParques WHERE id_visitantes_parque = @p_id_visitantes_parque)
        SET @errores += N'- No existe un registro con el ID indicado.' + CHAR(13);
    IF ISNULL(@p_visitas, -1) < 0
        SET @errores += N'- La cantidad de visitas no puede ser negativa.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    UPDATE estadisticas.VisitantesParques
    SET visitas             = @p_visitas,
        observaciones       = @p_observaciones,
        fecha_actualizacion = SYSDATETIME()
    WHERE id_visitantes_parque = @p_id_visitantes_parque;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('estadisticas.VisitantesParquesEliminar') AND type = 'P')
    PRINT 'Creando Procedure estadisticas.VisitantesParquesEliminar...';
ELSE
    PRINT 'OK - Procedure estadisticas.VisitantesParquesEliminar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE estadisticas.VisitantesParquesEliminar
    @p_id_visitantes_parque INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM estadisticas.VisitantesParques WHERE id_visitantes_parque = @p_id_visitantes_parque)
        SET @errores += N'- No existe un registro con el ID indicado.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    DELETE FROM estadisticas.VisitantesParques WHERE id_visitantes_parque = @p_id_visitantes_parque;
END
GO

-- ==============================================================
-- SCHEMA: estadisticas  |  TABLA: OrganizacionesDistinguidas
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('estadisticas.OrganizacionesDistinguidasInsertar') AND type = 'P')
    PRINT 'Creando Procedure estadisticas.OrganizacionesDistinguidasInsertar...';
ELSE
    PRINT 'OK - Procedure estadisticas.OrganizacionesDistinguidasInsertar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE estadisticas.OrganizacionesDistinguidasInsertar
    @p_organizacion      VARCHAR(200),
    @p_rubro             VARCHAR(100) = NULL,
    @p_subrubro          VARCHAR(100) = NULL,
    @p_calle             VARCHAR(200) = NULL,
    @p_numero            VARCHAR(50)  = NULL,
    @p_pais              VARCHAR(100) = NULL,
    @p_provincia         VARCHAR(100) = NULL,
    @p_ciudad            VARCHAR(100) = NULL,
    @p_telefono          VARCHAR(100) = NULL,
    @p_facebook          VARCHAR(200) = NULL,
    @p_web               VARCHAR(200) = NULL,
    @p_programa          VARCHAR(200) = NULL,
    @p_fecha_distincion  DATE         = NULL,
    @p_fecha_revalidacion DATE        = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF LTRIM(RTRIM(ISNULL(@p_organizacion, ''))) = ''
        SET @errores += N'- El nombre de la organización es obligatorio.' + CHAR(13);
    IF EXISTS (
        SELECT 1 FROM estadisticas.OrganizacionesDistinguidas
        WHERE organizacion      = @p_organizacion
          AND ISNULL(calle, '')  = ISNULL(@p_calle, '')
          AND ISNULL(numero, '') = ISNULL(@p_numero, '')
    )
        SET @errores += N'- Ya existe una organización con esa combinación de nombre, calle y número.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    INSERT INTO estadisticas.OrganizacionesDistinguidas
        (organizacion, rubro, subrubro, calle, numero, pais, provincia, ciudad,
         telefono, facebook, web, programa, fecha_distincion, fecha_revalidacion)
    VALUES
        (@p_organizacion, @p_rubro, @p_subrubro, @p_calle, @p_numero, @p_pais,
         @p_provincia, @p_ciudad, @p_telefono, @p_facebook, @p_web, @p_programa,
         @p_fecha_distincion, @p_fecha_revalidacion);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('estadisticas.OrganizacionesDistinguidasModificar') AND type = 'P')
    PRINT 'Creando Procedure estadisticas.OrganizacionesDistinguidasModificar...';
ELSE
    PRINT 'OK - Procedure estadisticas.OrganizacionesDistinguidasModificar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE estadisticas.OrganizacionesDistinguidasModificar
    @p_id_organizacion   INT,
    @p_rubro             VARCHAR(100) = NULL,
    @p_subrubro          VARCHAR(100) = NULL,
    @p_pais              VARCHAR(100) = NULL,
    @p_provincia         VARCHAR(100) = NULL,
    @p_ciudad            VARCHAR(100) = NULL,
    @p_telefono          VARCHAR(100) = NULL,
    @p_facebook          VARCHAR(200) = NULL,
    @p_web               VARCHAR(200) = NULL,
    @p_programa          VARCHAR(200) = NULL,
    @p_fecha_distincion  DATE         = NULL,
    @p_fecha_revalidacion DATE        = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM estadisticas.OrganizacionesDistinguidas WHERE id_organizacion = @p_id_organizacion)
        SET @errores += N'- No existe una organización con el ID indicado.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    UPDATE estadisticas.OrganizacionesDistinguidas
    SET rubro               = @p_rubro,
        subrubro            = @p_subrubro,
        pais                = @p_pais,
        provincia           = @p_provincia,
        ciudad              = @p_ciudad,
        telefono            = @p_telefono,
        facebook            = @p_facebook,
        web                 = @p_web,
        programa            = @p_programa,
        fecha_distincion    = @p_fecha_distincion,
        fecha_revalidacion  = @p_fecha_revalidacion,
        fecha_actualizacion = SYSDATETIME()
    WHERE id_organizacion = @p_id_organizacion;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('estadisticas.OrganizacionesDistinguidasEliminar') AND type = 'P')
    PRINT 'Creando Procedure estadisticas.OrganizacionesDistinguidasEliminar...';
ELSE
    PRINT 'OK - Procedure estadisticas.OrganizacionesDistinguidasEliminar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE estadisticas.OrganizacionesDistinguidasEliminar
    @p_id_organizacion INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM estadisticas.OrganizacionesDistinguidas WHERE id_organizacion = @p_id_organizacion)
        SET @errores += N'- No existe una organización con el ID indicado.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    DELETE FROM estadisticas.OrganizacionesDistinguidas WHERE id_organizacion = @p_id_organizacion;
END
GO

-- ==============================================================
-- SCHEMA: estadisticas  |  TABLA: AreasProtegidasJurisdiccion
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('estadisticas.AreasProtegidasInsertar') AND type = 'P')
    PRINT 'Creando Procedure estadisticas.AreasProtegidasInsertar...';
ELSE
    PRINT 'OK - Procedure estadisticas.AreasProtegidasInsertar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE estadisticas.AreasProtegidasInsertar
    @p_jurisdiccion                   NVARCHAR(100),
    @p_total_cantidad                 INT          = NULL,
    @p_ap_nac                         INT          = NULL,
    @p_ap_prov                        INT          = NULL,
    @p_ap_desig_inter                 INT          = NULL,
    @p_total_ha                       INT          = NULL,
    @p_terrestre_ha                   INT          = NULL,
    @p_marino_ha                      INT          = NULL,
    @p_porcentaje_terrestre_protegido DECIMAL(6,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF LTRIM(RTRIM(ISNULL(@p_jurisdiccion, ''))) = ''
        SET @errores += N'- La jurisdicción es obligatoria.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM estadisticas.AreasProtegidasJurisdiccion WHERE jurisdiccion = @p_jurisdiccion)
        SET @errores += N'- Ya existe un registro para esa jurisdicción.' + CHAR(13);
    IF @p_total_cantidad IS NOT NULL AND @p_total_cantidad < 0
        SET @errores += N'- El total de áreas protegidas no puede ser negativo.' + CHAR(13);
    IF @p_total_ha IS NOT NULL AND @p_total_ha < 0
        SET @errores += N'- El total de hectáreas no puede ser negativo.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    INSERT INTO estadisticas.AreasProtegidasJurisdiccion
        (jurisdiccion, total_cantidad, ap_nac, ap_prov, ap_desig_inter,
         total_ha, terrestre_ha, marino_ha, porcentaje_terrestre_protegido)
    VALUES
        (@p_jurisdiccion, @p_total_cantidad, @p_ap_nac, @p_ap_prov, @p_ap_desig_inter,
         @p_total_ha, @p_terrestre_ha, @p_marino_ha, @p_porcentaje_terrestre_protegido);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('estadisticas.AreasProtegidasModificar') AND type = 'P')
    PRINT 'Creando Procedure estadisticas.AreasProtegidasModificar...';
ELSE
    PRINT 'OK - Procedure estadisticas.AreasProtegidasModificar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE estadisticas.AreasProtegidasModificar
    @p_id_area                        INT,
    @p_total_cantidad                 INT          = NULL,
    @p_ap_nac                         INT          = NULL,
    @p_ap_prov                        INT          = NULL,
    @p_ap_desig_inter                 INT          = NULL,
    @p_total_ha                       INT          = NULL,
    @p_terrestre_ha                   INT          = NULL,
    @p_marino_ha                      INT          = NULL,
    @p_porcentaje_terrestre_protegido DECIMAL(6,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM estadisticas.AreasProtegidasJurisdiccion WHERE id_area = @p_id_area)
        SET @errores += N'- No existe un área protegida con el ID indicado.' + CHAR(13);
    IF @p_total_cantidad IS NOT NULL AND @p_total_cantidad < 0
        SET @errores += N'- El total de áreas protegidas no puede ser negativo.' + CHAR(13);
    IF @p_total_ha IS NOT NULL AND @p_total_ha < 0
        SET @errores += N'- El total de hectáreas no puede ser negativo.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    UPDATE estadisticas.AreasProtegidasJurisdiccion
    SET total_cantidad                 = @p_total_cantidad,
        ap_nac                         = @p_ap_nac,
        ap_prov                        = @p_ap_prov,
        ap_desig_inter                 = @p_ap_desig_inter,
        total_ha                       = @p_total_ha,
        terrestre_ha                   = @p_terrestre_ha,
        marino_ha                      = @p_marino_ha,
        porcentaje_terrestre_protegido = @p_porcentaje_terrestre_protegido,
        fecha_actualizacion            = SYSDATETIME()
    WHERE id_area = @p_id_area;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('estadisticas.AreasProtegidasEliminar') AND type = 'P')
    PRINT 'Creando Procedure estadisticas.AreasProtegidasEliminar...';
ELSE
    PRINT 'OK - Procedure estadisticas.AreasProtegidasEliminar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE estadisticas.AreasProtegidasEliminar
    @p_id_area INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM estadisticas.AreasProtegidasJurisdiccion WHERE id_area = @p_id_area)
        SET @errores += N'- No existe un área protegida con el ID indicado.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    DELETE FROM estadisticas.AreasProtegidasJurisdiccion WHERE id_area = @p_id_area;
END
GO

-- ==============================================================
-- SCHEMA: ventas  |  TABLA: CotizacionDolar
-- (tabla de consumo de API externa - Entrega 8)
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('ventas.CotizacionDolarInsertar') AND type = 'P')
    PRINT 'Creando Procedure ventas.CotizacionDolarInsertar...';
ELSE
    PRINT 'OK - Procedure ventas.CotizacionDolarInsertar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE ventas.CotizacionDolarInsertar
    @p_moneda              VARCHAR(10),
    @p_casa                VARCHAR(20),
    @p_compra              DECIMAL(12,4),
    @p_venta               DECIMAL(12,4),
    @p_nombre              VARCHAR(50) = NULL,
    @p_fecha_actualizacion DATETIME2   = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF LTRIM(RTRIM(ISNULL(@p_moneda, ''))) = ''
        SET @errores += N'- La moneda es obligatoria.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_casa, ''))) = ''
        SET @errores += N'- La casa es obligatoria.' + CHAR(13);
    IF ISNULL(@p_compra, 0) <= 0
        SET @errores += N'- El valor de compra debe ser mayor a 0.' + CHAR(13);
    IF ISNULL(@p_venta, 0) <= 0
        SET @errores += N'- El valor de venta debe ser mayor a 0.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    INSERT INTO ventas.CotizacionDolar
        (moneda, casa, nombre, compra, venta, fecha_actualizacion)
    VALUES
        (@p_moneda, @p_casa, @p_nombre, @p_compra, @p_venta, @p_fecha_actualizacion);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('ventas.CotizacionDolarModificar') AND type = 'P')
    PRINT 'Creando Procedure ventas.CotizacionDolarModificar...';
ELSE
    PRINT 'OK - Procedure ventas.CotizacionDolarModificar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE ventas.CotizacionDolarModificar
    @p_id_cotizacion       INT,
    @p_moneda              VARCHAR(10),
    @p_casa                VARCHAR(20),
    @p_compra              DECIMAL(12,4),
    @p_venta               DECIMAL(12,4),
    @p_nombre              VARCHAR(50) = NULL,
    @p_fecha_actualizacion DATETIME2   = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM ventas.CotizacionDolar WHERE id_cotizacion = @p_id_cotizacion)
        SET @errores += N'- No existe una cotización con el ID indicado.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_moneda, ''))) = ''
        SET @errores += N'- La moneda es obligatoria.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_casa, ''))) = ''
        SET @errores += N'- La casa es obligatoria.' + CHAR(13);
    IF ISNULL(@p_compra, 0) <= 0
        SET @errores += N'- El valor de compra debe ser mayor a 0.' + CHAR(13);
    IF ISNULL(@p_venta, 0) <= 0
        SET @errores += N'- El valor de venta debe ser mayor a 0.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    UPDATE ventas.CotizacionDolar
    SET moneda              = @p_moneda,
        casa                = @p_casa,
        nombre              = @p_nombre,
        compra              = @p_compra,
        venta               = @p_venta,
        fecha_actualizacion = @p_fecha_actualizacion
    WHERE id_cotizacion = @p_id_cotizacion;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('ventas.CotizacionDolarEliminar') AND type = 'P')
    PRINT 'Creando Procedure ventas.CotizacionDolarEliminar...';
ELSE
    PRINT 'OK - Procedure ventas.CotizacionDolarEliminar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE ventas.CotizacionDolarEliminar
    @p_id_cotizacion INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM ventas.CotizacionDolar WHERE id_cotizacion = @p_id_cotizacion)
        SET @errores += N'- No existe una cotización con el ID indicado.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    DELETE FROM ventas.CotizacionDolar WHERE id_cotizacion = @p_id_cotizacion;
END
GO

-- ==============================================================
-- SCHEMA: ventas  |  TABLA: Feriado
-- (tabla de consumo de API externa - Entrega 9)
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('ventas.FeriadoInsertar') AND type = 'P')
    PRINT 'Creando Procedure ventas.FeriadoInsertar...';
ELSE
    PRINT 'OK - Procedure ventas.FeriadoInsertar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE ventas.FeriadoInsertar
    @p_fecha  DATE,
    @p_nombre VARCHAR(150) = NULL,
    @p_tipo   VARCHAR(50)  = NULL,
    @p_anio   SMALLINT     = NULL    -- por defecto, se deriva del año de la fecha
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    SET @p_anio = ISNULL(@p_anio, YEAR(@p_fecha));

    IF @p_fecha IS NULL
        SET @errores += N'- La fecha del feriado es obligatoria.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.Feriado WHERE fecha = @p_fecha)
        SET @errores += N'- Ya existe un feriado registrado para esa fecha.' + CHAR(13);
    IF @p_anio < 2000 OR @p_anio > 2100
        SET @errores += N'- El año debe estar entre 2000 y 2100.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    INSERT INTO ventas.Feriado (fecha, nombre, tipo, anio)
    VALUES (@p_fecha, @p_nombre, @p_tipo, @p_anio);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('ventas.FeriadoModificar') AND type = 'P')
    PRINT 'Creando Procedure ventas.FeriadoModificar...';
ELSE
    PRINT 'OK - Procedure ventas.FeriadoModificar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE ventas.FeriadoModificar
    @p_id_feriado INT,
    @p_fecha      DATE,
    @p_nombre     VARCHAR(150) = NULL,
    @p_tipo       VARCHAR(50)  = NULL,
    @p_anio       SMALLINT     = NULL    -- por defecto, se deriva del año de la fecha
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    SET @p_anio = ISNULL(@p_anio, YEAR(@p_fecha));

    IF NOT EXISTS (SELECT 1 FROM ventas.Feriado WHERE id_feriado = @p_id_feriado)
        SET @errores += N'- No existe un feriado con el ID indicado.' + CHAR(13);
    IF @p_fecha IS NULL
        SET @errores += N'- La fecha del feriado es obligatoria.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM ventas.Feriado WHERE fecha = @p_fecha AND id_feriado != @p_id_feriado)
        SET @errores += N'- Ya existe otro feriado registrado para esa fecha.' + CHAR(13);
    IF @p_anio < 2000 OR @p_anio > 2100
        SET @errores += N'- El año debe estar entre 2000 y 2100.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    UPDATE ventas.Feriado
    SET fecha          = @p_fecha,
        nombre         = @p_nombre,
        tipo           = @p_tipo,
        anio           = @p_anio,
        fecha_consulta = SYSDATETIME()
    WHERE id_feriado = @p_id_feriado;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('ventas.FeriadoEliminar') AND type = 'P')
    PRINT 'Creando Procedure ventas.FeriadoEliminar...';
ELSE
    PRINT 'OK - Procedure ventas.FeriadoEliminar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE ventas.FeriadoEliminar
    @p_id_feriado INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';

    IF NOT EXISTS (SELECT 1 FROM ventas.Feriado WHERE id_feriado = @p_id_feriado)
        SET @errores += N'- No existe un feriado con el ID indicado.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    DELETE FROM ventas.Feriado WHERE id_feriado = @p_id_feriado;
END
GO
