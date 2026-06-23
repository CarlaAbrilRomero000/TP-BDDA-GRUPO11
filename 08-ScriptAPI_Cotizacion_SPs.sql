/*
=============================================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada!!!!
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Archivo:     10-ScriptAPI_Cotizacion_SPs.sql
Descripción: Consumo de API externa de cotización de moneda extranjera
             (DolarAPI - https://dolarapi.com/v1/dolares/oficial).

             El consumo HTTP se realiza desde T-SQL mediante OLE Automation
             (MSXML2.ServerXMLHTTP) y el JSON de respuesta se interpreta con
             OPENJSON. La última cotización obtenida se persiste en la tabla
             ventas.CotizacionDolar, que funciona a la vez como caché y como
             auditoría de consultas.

             Formato de respuesta esperado de la API:
             {
               "moneda": "USD",
               "casa": "oficial",
               "nombre": "Oficial",
               "compra": 1440,
               "venta": 1490,
               "fechaActualizacion": "2026-06-23T18:00:00.000Z"
             }

             Objetos incluidos:
             1. ventas.CotizacionDolar (tabla)
                Histórico de cotizaciones obtenidas desde la API.

             2. ventas.CotizacionDolarActualizar (SP)
                Consume la API, interpreta el JSON y registra una nueva
                cotización. Retorna la fila insertada.

             3. ventas.fn_CotizacionVigente (función)
                Devuelve el valor de venta de la última cotización registrada.

             4. ventas.fn_ConvertirArsAUsd (función)
                Convierte un monto en pesos a dólares usando la cotización
                vigente (valor de venta).

             5. dbo.Ingresos_Parque_USD (SP)
                Variante del reporte de ingresos que agrega las columnas
                equivalentes en dólares.
=============================================================================
*/

USE ParquesNacionalesDB;
GO

PRINT '=========================================================================';
PRINT 'INICIANDO CONFIGURACIÓN DE CONSUMO DE API DE COTIZACIÓN (ENTREGA 8)';
PRINT '=========================================================================';
GO

-- =========================================================================
-- 0. HABILITAR OLE AUTOMATION
--    Necesario para que sp_OACreate pueda instanciar el cliente HTTP.
--    Requiere permisos de administrador del servidor (sysadmin).
-- =========================================================================
PRINT 'Habilitando OLE Automation Procedures...';
GO
IF EXISTS (SELECT 1 FROM sys.configurations WHERE name = 'show advanced options' AND value_in_use = 0)
BEGIN
    EXEC sp_configure 'show advanced options', 1;
    RECONFIGURE;
END
GO
IF EXISTS (SELECT 1 FROM sys.configurations WHERE name = 'Ole Automation Procedures' AND value_in_use = 0)
BEGIN
    EXEC sp_configure 'Ole Automation Procedures', 1;
    RECONFIGURE;
END
GO
PRINT 'OK - OLE Automation habilitado.';
GO

-- =========================================================================
-- 1. TABLA: ventas.CotizacionDolar
--    Persiste cada cotización obtenida desde la API (caché + auditoría).
-- =========================================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CotizacionDolar' AND schema_id = SCHEMA_ID('ventas'))
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

-- =========================================================================
-- 2. SP: ventas.CotizacionDolarActualizar
--    Consume la API de DolarAPI, parsea el JSON con OPENJSON y registra
--    una nueva fila en ventas.CotizacionDolar. Retorna la fila insertada.
-- =========================================================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('ventas.CotizacionDolarActualizar') AND type = 'P')
    PRINT 'Creando Procedure ventas.CotizacionDolarActualizar...';
ELSE
    PRINT 'OK - Procedure ventas.CotizacionDolarActualizar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE ventas.CotizacionDolarActualizar
    @p_url VARCHAR(200) = 'https://dolarapi.com/v1/dolares/oficial'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @obj    INT;
    DECLARE @hr     INT;
    DECLARE @status INT       = NULL;
    -- IMPORTANTE: sp_OAGetProperty devuelve cadena vacía si el destino es
    -- NVARCHAR(MAX). Se usa un tipo de tamaño fijo para leer la respuesta.
    DECLARE @json   NVARCHAR(4000);
    DECLARE @errSrc VARCHAR(255);
    DECLARE @errDsc VARCHAR(500);
    DECLARE @msg    NVARCHAR(1000);

    -- Variables destino del parseo
    DECLARE @moneda  VARCHAR(10);
    DECLARE @casa    VARCHAR(20);
    DECLARE @nombre  VARCHAR(50);
    DECLARE @compra  DECIMAL(12,4);
    DECLARE @venta   DECIMAL(12,4);
    DECLARE @fechaAct_txt VARCHAR(40);
    DECLARE @fechaAct     DATETIME2;
    DECLARE @id_cotizacion INT;

    -- 1) Instanciar el cliente HTTP.
    --    Se usa WinHttp.WinHttpRequest.5.1 (en lugar de MSXML2.ServerXMLHTTP)
    --    porque negocia mejor TLS 1.2 y la compresión, evitando que la API
    --    detrás de un CDN devuelva un cuerpo vacío.
    EXEC @hr = sp_OACreate 'WinHttp.WinHttpRequest.5.1', @obj OUT;
    IF @hr <> 0
    BEGIN
        EXEC sp_OAGetErrorInfo @obj, @errSrc OUT, @errDsc OUT;
        SET @msg = N'No se pudo crear el cliente HTTP. ' + ISNULL(@errDsc, N'');
        THROW 50010, @msg, 1;
    END

    BEGIN TRY
        -- 2) Abrir la conexión (GET), declarar cabeceras y enviar la solicitud.
        --    El User-Agent es obligatorio: sin él, el CDN puede responder
        --    con estado 200 pero cuerpo vacío.
        EXEC @hr = sp_OAMethod @obj, 'open', NULL, 'GET', @p_url, 'false';
        IF @hr <> 0 THROW 50011, N'Error al abrir la conexión HTTP.', 1;

        EXEC sp_OAMethod @obj, 'setRequestHeader', NULL, 'User-Agent', 'ParquesNacionalesDB/1.0';
        EXEC sp_OAMethod @obj, 'setRequestHeader', NULL, 'Accept', 'application/json';

        EXEC @hr = sp_OAMethod @obj, 'send';
        IF @hr <> 0 THROW 50012, N'Error al enviar la solicitud HTTP.', 1;

        -- 3) Verificar el código de estado HTTP
        EXEC @hr = sp_OAGetProperty @obj, 'status', @status OUT;
        IF ISNULL(@status, 0) <> 200
        BEGIN
            SET @msg = N'La API respondió con un estado HTTP no exitoso: '
                       + CAST(ISNULL(@status, -1) AS VARCHAR(10)) + N'.';
            THROW 50013, @msg, 1;
        END

        -- 4) Leer el cuerpo de la respuesta (JSON)
        EXEC @hr = sp_OAGetProperty @obj, 'responseText', @json OUT;
        IF @hr <> 0 OR @json IS NULL OR LTRIM(RTRIM(@json)) = ''
            THROW 50014, N'La API no devolvió contenido en la respuesta.', 1;

        -- 5) Liberar el objeto COM (ya tenemos el JSON)
        EXEC sp_OADestroy @obj;
        SET @obj = NULL;

        -- 6) Parsear el JSON con OPENJSON
        IF ISJSON(@json) = 0
            THROW 50015, N'La respuesta de la API no es un JSON válido.', 1;

        SELECT
            @moneda       = j.moneda,
            @casa         = j.casa,
            @nombre       = j.nombre,
            @compra       = j.compra,
            @venta        = j.venta,
            @fechaAct_txt = j.fechaActualizacion
        FROM OPENJSON(@json)
        WITH (
            moneda             VARCHAR(10) '$.moneda',
            casa               VARCHAR(20) '$.casa',
            nombre             VARCHAR(50) '$.nombre',
            compra             DECIMAL(12,4) '$.compra',
            venta              DECIMAL(12,4) '$.venta',
            fechaActualizacion VARCHAR(40) '$.fechaActualizacion'
        ) AS j;

        -- La fecha viene en ISO 8601 con 'Z' (UTC): se convierte con estilo 127.
        SET @fechaAct = TRY_CONVERT(DATETIME2, @fechaAct_txt, 127);

        IF @compra IS NULL OR @venta IS NULL
            THROW 50016, N'El JSON no contiene los campos de cotización esperados (compra/venta).', 1;

        -- 7) Persistir la cotización obtenida
        INSERT INTO ventas.CotizacionDolar
            (moneda, casa, nombre, compra, venta, fecha_actualizacion)
        VALUES
            (ISNULL(@moneda, 'USD'), ISNULL(@casa, 'oficial'), @nombre, @compra, @venta, @fechaAct);

        SET @id_cotizacion = SCOPE_IDENTITY();

        -- 8) Retornar la fila insertada
        SELECT id_cotizacion, moneda, casa, nombre, compra, venta,
               fecha_actualizacion, fecha_consulta
        FROM ventas.CotizacionDolar
        WHERE id_cotizacion = @id_cotizacion;
    END TRY
    BEGIN CATCH
        -- Asegurar la liberación del objeto COM ante cualquier error
        IF @obj IS NOT NULL EXEC sp_OADestroy @obj;
        THROW;
    END CATCH
END
GO
PRINT 'OK - Store Procedure ventas.CotizacionDolarActualizar creado/actualizado con éxito.';
GO

-- =========================================================================
-- 3. FUNCIÓN: ventas.fn_CotizacionVigente
--    Devuelve el valor de venta de la última cotización registrada.
--    Retorna NULL si todavía no se consultó ninguna cotización.
-- =========================================================================
PRINT 'Creando o actualizando función ventas.fn_CotizacionVigente...';
GO
CREATE OR ALTER FUNCTION ventas.fn_CotizacionVigente()
RETURNS DECIMAL(12,4)
AS
BEGIN
    DECLARE @venta DECIMAL(12,4);

    SELECT TOP 1 @venta = venta
    FROM ventas.CotizacionDolar
    ORDER BY fecha_consulta DESC, id_cotizacion DESC;

    RETURN @venta;
END
GO
PRINT 'OK - Función ventas.fn_CotizacionVigente creada/actualizada con éxito.';
GO

-- =========================================================================
-- 4. FUNCIÓN: ventas.fn_ConvertirArsAUsd
--    Convierte un monto en pesos a dólares usando la cotización vigente
--    (valor de venta). Retorna NULL si no hay cotización disponible.
-- =========================================================================
PRINT 'Creando o actualizando función ventas.fn_ConvertirArsAUsd...';
GO
CREATE OR ALTER FUNCTION ventas.fn_ConvertirArsAUsd
(
    @p_monto_ars DECIMAL(18,2)
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @venta DECIMAL(12,4) = ventas.fn_CotizacionVigente();

    IF @venta IS NULL OR @venta = 0 OR @p_monto_ars IS NULL
        RETURN NULL;

    RETURN CAST(@p_monto_ars / @venta AS DECIMAL(18,2));
END
GO
PRINT 'OK - Función ventas.fn_ConvertirArsAUsd creada/actualizada con éxito.';
GO

-- =========================================================================
-- 5. SP: dbo.Ingresos_Parque_USD
--    Variante del reporte de ingresos por parque/semana/mes/año que agrega
--    las columnas equivalentes en dólares (usando la cotización vigente).
-- =========================================================================
PRINT 'Creando o actualizando Store Procedure dbo.Ingresos_Parque_USD...';
GO
CREATE OR ALTER PROCEDURE dbo.Ingresos_Parque_USD
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @cotizacion DECIMAL(12,4) = ventas.fn_CotizacionVigente();

    SELECT
        Parque,
        Anio,
        Mes,
        Semana,
        SUM(Ingreso_Entradas)                                                   AS Total_Entradas,
        SUM(Ingreso_Tours)                                                      AS Total_Tours,
        SUM(Ingreso_Concesiones)                                                AS Total_Concesiones,
        SUM(Ingreso_Entradas + Ingreso_Tours + Ingreso_Concesiones)             AS Total_General,
        @cotizacion                                                             AS Cotizacion_USD_Aplicada,
        ventas.fn_ConvertirArsAUsd(SUM(Ingreso_Entradas))                       AS Total_Entradas_USD,
        ventas.fn_ConvertirArsAUsd(SUM(Ingreso_Tours))                          AS Total_Tours_USD,
        ventas.fn_ConvertirArsAUsd(SUM(Ingreso_Concesiones))                    AS Total_Concesiones_USD,
        ventas.fn_ConvertirArsAUsd(
            SUM(Ingreso_Entradas + Ingreso_Tours + Ingreso_Concesiones))        AS Total_General_USD
    FROM (
        -- Ingresos por Entradas y Tours
        SELECT
            p.nombre AS Parque,
            YEAR(td.fecha_acceso) AS Anio,
            MONTH(td.fecha_acceso) AS Mes,
            DATEPART(WEEK, td.fecha_acceso) AS Semana,
            SUM(CASE WHEN td.id_atraccion_tour IS NULL THEN td.subtotal ELSE 0 END) AS Ingreso_Entradas,
            SUM(CASE WHEN td.id_atraccion_tour IS NOT NULL THEN td.subtotal ELSE 0 END) AS Ingreso_Tours,
            0 AS Ingreso_Concesiones
        FROM ventas.TicketDetalle td
        JOIN parques.Parque p ON td.id_parque = p.id_parque
        GROUP BY p.nombre, td.fecha_acceso

        UNION ALL

        -- Ingresos por Concesiones
        SELECT
            p.nombre AS Parque,
            YEAR(pc.fecha_pago) AS Anio,
            MONTH(pc.fecha_pago) AS Mes,
            DATEPART(WEEK, pc.fecha_pago) AS Semana,
            0, 0,
            SUM(pc.monto_pagado) AS Ingreso_Concesiones
        FROM comercial.PagoCanon pc
        JOIN comercial.ObligacionCanon oc ON pc.id_obligacion = oc.id_obligacion
        JOIN comercial.Concesion c ON oc.id_concesion = c.id_concesion
        JOIN parques.Parque p ON c.id_parque = p.id_parque
        GROUP BY p.nombre, pc.fecha_pago
    ) AS consolidados
    GROUP BY Parque, Anio, Mes, Semana
    ORDER BY Parque, Anio, Mes, Semana;
END
GO
PRINT 'OK - Store Procedure dbo.Ingresos_Parque_USD creado/actualizado con éxito.';
GO

PRINT '=========================================================================';
PRINT 'FIN DEL SCRIPT: OBJETOS DE CONSUMO DE API DE COTIZACIÓN CREADOS';
PRINT '=========================================================================';
GO
