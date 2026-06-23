/*
==============================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Fecha:       09/06/2026
Descripción: Stored Procedures de lógica de negocio.
             Cada procedimiento afecta múltiples tablas y
             aplica transacciones para garantizar la integridad
             de los datos.

             Procedimientos incluidos:
             1. ventas.VentaRegistrar
                Registra un ticket completo (cabecera + líneas
                de detalle) en una única transacción atómica.

             2. comercial.ConcesionConObligacionesRegistrar
                Crea una concesión y genera automáticamente las
                obligaciones de canon mensuales para todo el
                período contractual.

             3. comercial.PagoCanonRegistrar
                Registra un pago de canon que cubre el total de
                la obligación y la marca como PAGADO en la misma
                transacción. No admite pagos parciales.

             4. personal.GuardaparqueTransferir
                Cierra el período activo de un guardaparque en
                su parque actual y abre uno nuevo en el parque
                de destino, de forma atómica.

             5. ventas.PrecioEntradaActualizar
                Registra un ajuste de precio de entrada para un
                parque y tipo de visitante, validando la
                coherencia temporal con el historial existente.
==============================================================
*/

USE ParquesNacionalesDB;
GO

-- ==============================================================
-- Tipo de tabla para pasar detalles de venta como parámetro
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.types WHERE name = 'tt_DetalleVenta' AND schema_id = SCHEMA_ID('ventas'))
BEGIN
    PRINT 'Creando Type ventas.tt_DetalleVenta...';
    CREATE TYPE ventas.tt_DetalleVenta AS TABLE (
        id_parque           INT           NOT NULL,
        id_historial_precio INT           NULL,
        id_tipo_visitante   INT           NULL,
        id_atraccion_tour   INT           NULL,
        fecha_acceso        DATE          NOT NULL,
        cantidad            INT           NOT NULL,
        precio_unitario     DECIMAL(12,2) NOT NULL,
        subtotal            DECIMAL(12,2) NOT NULL
    );
END
ELSE
    PRINT 'OK - Type ventas.tt_DetalleVenta ya existe, se omite creación.';
GO

-- ==============================================================
-- 1. ventas.VentaRegistrar
--    Inserta Ticket + todos sus TicketDetalle en una
--    transacción. Valida existencia de referencias y que la
--    suma de subtotales coincida con el total declarado.
--    Retorna el id del ticket generado.
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('ventas.VentaRegistrar') AND type = 'P')
    PRINT 'Creando Procedure ventas.VentaRegistrar...';
ELSE
    PRINT 'OK - Procedure ventas.VentaRegistrar ya existe, se omite creación.';

GO

CREATE OR ALTER PROCEDURE ventas.VentaRegistrar
    @p_punto_venta   CHAR(4),
    @p_numero        VARCHAR(50),
    @p_fecha_venta   DATETIME2,
    @p_id_forma_pago INT,
    @p_total         DECIMAL(12,2),
    @p_detalles      ventas.tt_DetalleVenta READONLY
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores          NVARCHAR(MAX) = N'';
    DECLARE @id_ticket        INT;
    DECLARE @total_calculado  DECIMAL(12,2);

    -- Validaciones de cabecera
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
    IF NOT EXISTS (SELECT 1 FROM @p_detalles)
        SET @errores += N'- El ticket debe contener al menos un línea de detalle.' + CHAR(13);

    -- Validaciones de líneas de detalle
    IF EXISTS (SELECT 1 FROM @p_detalles WHERE id_historial_precio IS NULL AND id_atraccion_tour IS NULL)
        SET @errores += N'- Cada línea de detalle debe referenciar un precio de entrada o una atracción/tour.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM @p_detalles WHERE cantidad <= 0)
        SET @errores += N'- La cantidad de cada línea de detalle debe ser mayor a cero.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM @p_detalles WHERE precio_unitario < 0)
        SET @errores += N'- El precio unitario no puede ser negativo.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM @p_detalles WHERE subtotal < 0)
        SET @errores += N'- El subtotal no puede ser negativo.' + CHAR(13);
    IF EXISTS (
        SELECT 1 FROM @p_detalles d
        WHERE NOT EXISTS (SELECT 1 FROM parques.Parque p WHERE p.id_parque = d.id_parque)
    )
        SET @errores += N'- Uno o más parques referenciados en los detalles no existen.' + CHAR(13);
    IF EXISTS (
        SELECT 1 FROM @p_detalles d
        WHERE d.id_historial_precio IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM ventas.HistorialPrecio hp WHERE hp.id_historial_precio = d.id_historial_precio)
    )
        SET @errores += N'- Uno o más historiales de precio referenciados no existen.' + CHAR(13);
    IF EXISTS (
        SELECT 1 FROM @p_detalles d
        WHERE d.id_tipo_visitante IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante tv WHERE tv.id_tipo_visitante = d.id_tipo_visitante)
    )
        SET @errores += N'- Uno o más tipos de visitante referenciados no existen.' + CHAR(13);
    IF EXISTS (
        SELECT 1 FROM @p_detalles d
        WHERE d.id_atraccion_tour IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM turismo.AtraccionTour at WHERE at.id_atraccion_tour = d.id_atraccion_tour)
    )
        SET @errores += N'- Una o más atracciones/tours referenciados no existen.' + CHAR(13);

    -- Validar coherencia entre total declarado y suma de subtotales
    SELECT @total_calculado = SUM(subtotal) FROM @p_detalles;
    IF ABS(ISNULL(@total_calculado, 0) - ISNULL(@p_total, 0)) > 0.01
        SET @errores += N'- El total del ticket (' + CAST(@p_total AS VARCHAR(20))
            + N') no coincide con la suma de subtotales ('
            + CAST(ISNULL(@total_calculado, 0) AS VARCHAR(20)) + N').' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO ventas.Ticket (punto_venta, numero, fecha_venta, id_forma_pago, total)
        VALUES (@p_punto_venta, @p_numero, @p_fecha_venta, @p_id_forma_pago, @p_total);

        SET @id_ticket = SCOPE_IDENTITY();

        INSERT INTO ventas.TicketDetalle
            (id_ticket, id_parque, id_historial_precio, id_tipo_visitante,
             id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal)
        SELECT
            @id_ticket, id_parque, id_historial_precio, id_tipo_visitante,
            id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal
        FROM @p_detalles;

        COMMIT TRANSACTION;

        -- Se retorna el total en pesos y su equivalente en dólares según la
        -- cotización vigente (útil al cobrar a visitantes no residentes).
        -- La cotización se obtiene con ventas.CotizacionDolarActualizar (API).
        SELECT @id_ticket                            AS id_ticket_generado,
               @p_total                              AS total_ars,
               ventas.fn_ConvertirArsAUsd(@p_total)  AS total_usd,
               ventas.fn_CotizacionVigente()         AS cotizacion_usd_aplicada;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() != 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END

GO

-- ==============================================================
-- 2. comercial.ConcesionConObligacionesRegistrar
--    Inserta la Concesion y genera una ObligacionCanon por
--    cada mes del período contractual (vencimiento el día
--    @p_dia_vencimiento del mes siguiente, estado PENDIENTE).
--    Retorna el id de la concesión y la cantidad de meses.
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('comercial.ConcesionConObligacionesRegistrar') AND type = 'P')
    PRINT 'Creando Procedure comercial.ConcesionConObligacionesRegistrar...';
ELSE
    PRINT 'OK - Procedure comercial.ConcesionConObligacionesRegistrar ya existe, se omite creación.';

GO

CREATE OR ALTER PROCEDURE comercial.ConcesionConObligacionesRegistrar
    @p_id_parque       INT,
    @p_id_empresa      INT,
    @p_tipo_actividad  VARCHAR(100),
    @p_fecha_inicio    DATE,
    @p_fecha_fin       DATE,
    @p_canon_mensual   DECIMAL(12,2),
    @p_dia_vencimiento TINYINT = 10
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores       NVARCHAR(MAX) = N'';
    DECLARE @id_concesion  INT;
    DECLARE @cursor        DATE;
    DECLARE @mes           TINYINT;
    DECLARE @anio          SMALLINT;
    DECLARE @fecha_venc    DATE;
    DECLARE @meses_gen     INT = 0;

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
    IF ISNULL(@p_dia_vencimiento, 0) NOT BETWEEN 1 AND 28
        SET @errores += N'- El día de vencimiento debe estar entre 1 y 28.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO comercial.Concesion
            (id_parque, id_empresa, tipo_actividad, fecha_inicio, fecha_fin, canon_mensual)
        VALUES
            (@p_id_parque, @p_id_empresa, @p_tipo_actividad, @p_fecha_inicio, @p_fecha_fin, @p_canon_mensual);

        SET @id_concesion = SCOPE_IDENTITY();

        -- Recorrer mes a mes desde fecha_inicio hasta fecha_fin
        SET @cursor = DATEFROMPARTS(YEAR(@p_fecha_inicio), MONTH(@p_fecha_inicio), 1);

        WHILE @cursor <= DATEFROMPARTS(YEAR(@p_fecha_fin), MONTH(@p_fecha_fin), 1)
        BEGIN
            SET @mes  = MONTH(@cursor);
            SET @anio = YEAR(@cursor);

            -- Vencimiento: día @p_dia_vencimiento del mes siguiente
            SET @fecha_venc = DATEFROMPARTS(
                CASE WHEN @mes = 12 THEN @anio + 1 ELSE @anio END,
                CASE WHEN @mes = 12 THEN 1          ELSE @mes + 1 END,
                @p_dia_vencimiento
            );

            INSERT INTO comercial.ObligacionCanon
                (id_concesion, mes, anio, monto_obligado, estado, fecha_vencimiento)
            VALUES
                (@id_concesion, @mes, @anio, @p_canon_mensual, 'PENDIENTE', @fecha_venc);

            SET @meses_gen += 1;
            SET @cursor = DATEADD(MONTH, 1, @cursor);
        END;

        COMMIT TRANSACTION;

        SELECT @id_concesion AS id_concesion_generado,
               @meses_gen    AS obligaciones_generadas;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() != 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END

GO

-- ==============================================================
-- 3. comercial.PagoCanonRegistrar
--    Inserta PagoCanon y marca la ObligacionCanon como PAGADO.
--    No se permiten pagos parciales: el monto pagado debe
--    cubrir exactamente el saldo pendiente de la obligación.
--    Retorna el estado resultante y el total acumulado.
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('comercial.PagoCanonRegistrar') AND type = 'P')
    PRINT 'Creando Procedure comercial.PagoCanonRegistrar...';
ELSE
    PRINT 'OK - Procedure comercial.PagoCanonRegistrar ya existe, se omite creación.';

GO

CREATE OR ALTER PROCEDURE comercial.PagoCanonRegistrar
    @p_id_obligacion INT,
    @p_fecha_pago    DATE,
    @p_monto_pagado  DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores            NVARCHAR(MAX) = N'';
    DECLARE @monto_oblig        DECIMAL(12,2);
    DECLARE @total_pagado_prev  DECIMAL(12,2);
    DECLARE @total_pagado       DECIMAL(12,2);
    DECLARE @nuevo_estado       VARCHAR(20);

    SELECT @monto_oblig = monto_obligado
    FROM comercial.ObligacionCanon
    WHERE id_obligacion = @p_id_obligacion;

    SELECT @total_pagado_prev = ISNULL(SUM(monto_pagado), 0)
    FROM comercial.PagoCanon
    WHERE id_obligacion = @p_id_obligacion;

    IF @monto_oblig IS NULL
        SET @errores += N'- La obligación indicada no existe.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM comercial.ObligacionCanon WHERE id_obligacion = @p_id_obligacion AND estado = 'PAGADO')
        SET @errores += N'- La obligación ya se encuentra completamente pagada.' + CHAR(13);
    IF @p_fecha_pago IS NULL
        SET @errores += N'- La fecha de pago es obligatoria.' + CHAR(13);
    IF ISNULL(@p_monto_pagado, 0) <= 0
        SET @errores += N'- El monto pagado debe ser mayor a cero.' + CHAR(13);
    IF @monto_oblig IS NOT NULL AND ISNULL(@p_monto_pagado, 0) != (@monto_oblig - @total_pagado_prev)
        SET @errores += N'- El monto pagado no cubre el total de la obligación. No se permiten pagos parciales.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    SET @total_pagado = @monto_oblig;
    SET @nuevo_estado = 'PAGADO';

    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO comercial.PagoCanon (id_obligacion, fecha_pago, monto_pagado)
        VALUES (@p_id_obligacion, @p_fecha_pago, @p_monto_pagado);

        UPDATE comercial.ObligacionCanon
        SET estado = @nuevo_estado
        WHERE id_obligacion = @p_id_obligacion;

        COMMIT TRANSACTION;

        SELECT @nuevo_estado   AS estado_resultante,
               @total_pagado   AS total_acumulado,
               @monto_oblig    AS monto_obligado;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() != 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END

GO

-- ==============================================================
-- 4. personal.GuardaparqueTransferir
--    Cierra el HistorialGuardaparque activo (sin fecha_egreso)
--    del guardaparque indicado y abre uno nuevo en el parque
--    de destino. Ambas operaciones se realizan en una única
--    transacción para garantizar consistencia.
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('personal.GuardaparqueTransferir') AND type = 'P')
    PRINT 'Creando Procedure personal.GuardaparqueTransferir...';
ELSE
    PRINT 'OK - Procedure personal.GuardaparqueTransferir ya existe, se omite creación.';

GO

CREATE OR ALTER PROCEDURE personal.GuardaparqueTransferir
    @p_id_guardaparque     INT,
    @p_id_parque_destino   INT,
    @p_fecha_transferencia DATE,
    @p_motivo_egreso       VARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores              NVARCHAR(MAX) = N'';
    DECLARE @id_historial_activo  INT;
    DECLARE @id_parque_actual     INT;
    DECLARE @fecha_ingreso_actual DATE;

    -- Buscar asignación activa
    SELECT @id_historial_activo  = id_historial,
           @id_parque_actual     = id_parque,
           @fecha_ingreso_actual = fecha_ingreso
    FROM personal.HistorialGuardaparque
    WHERE id_guardaparque = @p_id_guardaparque
      AND fecha_egreso IS NULL;

    IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE id_guardaparque = @p_id_guardaparque AND activo = 1)
        SET @errores += N'- El guardaparque indicado no existe o está inactivo.' + CHAR(13);
    IF @id_historial_activo IS NULL
        SET @errores += N'- El guardaparque no tiene una asignación activa en ningún parque.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @p_id_parque_destino)
        SET @errores += N'- El parque de destino indicado no existe.' + CHAR(13);
    IF @id_parque_actual IS NOT NULL AND @id_parque_actual = @p_id_parque_destino
        SET @errores += N'- El guardaparque ya está asignado al parque de destino.' + CHAR(13);
    IF @p_fecha_transferencia IS NULL
        SET @errores += N'- La fecha de transferencia es obligatoria.' + CHAR(13);
    IF @p_fecha_transferencia IS NOT NULL AND @fecha_ingreso_actual IS NOT NULL
       AND @p_fecha_transferencia < @fecha_ingreso_actual
        SET @errores += N'- La fecha de transferencia no puede ser anterior a la fecha de ingreso al parque actual.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Cerrar asignación vigente
        UPDATE personal.HistorialGuardaparque
        SET fecha_egreso  = @p_fecha_transferencia,
            motivo_egreso = ISNULL(@p_motivo_egreso, N'Transferencia a otro parque')
        WHERE id_historial = @id_historial_activo;

        -- Abrir nueva asignación en el parque destino
        INSERT INTO personal.HistorialGuardaparque
            (id_guardaparque, id_parque, fecha_ingreso)
        VALUES
            (@p_id_guardaparque, @p_id_parque_destino, @p_fecha_transferencia);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() != 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END

GO

-- ==============================================================
-- 5. ventas.PrecioEntradaActualizar
--    Registra un nuevo precio de entrada (HistorialPrecio)
--    para la combinación parque + tipo de visitante. Valida
--    que la fecha de vigencia sea posterior al último ajuste
--    registrado para esa combinación.
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('ventas.PrecioEntradaActualizar') AND type = 'P')
    PRINT 'Creando Procedure ventas.PrecioEntradaActualizar...';
ELSE
    PRINT 'OK - Procedure ventas.PrecioEntradaActualizar ya existe, se omite creación.';

GO

CREATE OR ALTER PROCEDURE ventas.PrecioEntradaActualizar
    @p_id_parque         INT,
    @p_id_tipo_visitante INT,
    @p_nuevo_precio      DECIMAL(12,2),
    @p_fecha_vigencia    DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores           NVARCHAR(MAX) = N'';
    DECLARE @ultima_fecha      DATE;

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @p_id_parque)
        SET @errores += N'- El parque indicado no existe.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id_tipo_visitante = @p_id_tipo_visitante)
        SET @errores += N'- El tipo de visitante indicado no existe.' + CHAR(13);
    IF ISNULL(@p_nuevo_precio, -1) < 0
        SET @errores += N'- El precio no puede ser negativo.' + CHAR(13);
    IF @p_fecha_vigencia IS NULL
        SET @errores += N'- La fecha de vigencia es obligatoria.' + CHAR(13);

    -- Validar que la nueva fecha sea posterior al último precio registrado
    IF @p_fecha_vigencia IS NOT NULL
    BEGIN
        SELECT @ultima_fecha = MAX(fecha_desde)
        FROM ventas.HistorialPrecio
        WHERE id_parque = @p_id_parque AND id_tipo_visitante = @p_id_tipo_visitante;

        IF @ultima_fecha IS NOT NULL AND @p_fecha_vigencia <= @ultima_fecha
            SET @errores += N'- La fecha de vigencia debe ser posterior al último ajuste registrado ('
                + CONVERT(VARCHAR(10), @ultima_fecha, 103) + N').' + CHAR(13);
    END

    IF @errores != N'' THROW 50000, @errores, 1;

    INSERT INTO ventas.HistorialPrecio
        (precio, fecha_desde, id_parque, id_tipo_visitante)
    VALUES
        (@p_nuevo_precio, @p_fecha_vigencia, @p_id_parque, @p_id_tipo_visitante);

    SELECT SCOPE_IDENTITY() AS id_historial_precio_generado;
END

GO
