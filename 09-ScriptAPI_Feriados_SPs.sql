/*
=============================================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Archivo:     09-ScriptAPI_Feriados_SPs.sql
Descripción: Consumo de API externa de feriados de Argentina para el cálculo
             del valor de las entradas (ArgentinaDatos -
             https://api.argentinadatos.com/v1/feriados/{anio}).

             El consumo HTTP se realiza desde T-SQL mediante OLE Automation
             (WinHttp.WinHttpRequest.5.1) y el JSON de respuesta se interpreta
             con OPENJSON. Los feriados obtenidos se persisten en la tabla
             ventas.Feriado, que funciona a la vez como caché y como
             auditoría de consultas.

             En los días feriados se aplica un recargo sobre el valor de la
             entrada (precio dinámico), análogo a como la cotización del
             dólar ajusta los importes en moneda extranjera.

             Formato de respuesta esperado de la API (array JSON):
             [
               {
                 "fecha": "2026-02-16",
                 "tipo": "inamovible",
                 "nombre": "Carnaval"
               },
               ...
             ]

             Objetos incluidos:
             NOTA: La tabla ventas.Feriado se crea en el script 01 y sus
             operaciones ABM están en el script 02. Este script solo contiene
             la lógica de consumo de la API y el cálculo de entradas.

             1. ventas.FeriadosActualizar (SP)
                Consume la API para un año dado, interpreta el JSON y
                sincroniza (upsert) los feriados. Retorna las filas vigentes.

             2. ventas.fn_EsFeriado (función)
                Indica si una fecha dada es feriado registrado.

             3. ventas.fn_PrecioEntradaConFeriado (función)
                Aplica el recargo por feriado al valor de una entrada.

             4. ventas.CalcularValorEntrada (SP)
                Calcula el valor final de una entrada para un parque, tipo de
                visitante y fecha, considerando el recargo por feriado.
=============================================================================
*/

USE ParquesNacionalesDB;
GO

PRINT '=========================================================================';
PRINT 'INICIANDO CONFIGURACIÓN DE CONSUMO DE API DE FERIADOS (ENTREGA 9)';
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
-- 1. TABLA: ventas.Feriado
--    La tabla se crea en el script 01-ScriptCreacionTablasYSchemas.sql
--    (sección "TABLAS DE CONSUMO DE APIs EXTERNAS") y sus operaciones ABM
--    están en el script 02-ScriptABM_SPs.sql. Debe existir antes de
--    ejecutar este script.
-- =========================================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Feriado' AND schema_id = SCHEMA_ID('ventas'))
    THROW 50020, N'Falta la tabla ventas.Feriado. Ejecute primero el script 01-ScriptCreacionTablasYSchemas.sql.', 1;
GO

-- =========================================================================
-- 2. SP: ventas.FeriadosActualizar
--    Consume la API de ArgentinaDatos para un año dado, parsea el array JSON
--    con OPENJSON y sincroniza (upsert) los feriados en ventas.Feriado.
--    Retorna los feriados vigentes para el año consultado.
-- =========================================================================
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('ventas.FeriadosActualizar') AND type = 'P')
    PRINT 'Creando Procedure ventas.FeriadosActualizar...';
ELSE
    PRINT 'OK - Procedure ventas.FeriadosActualizar ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE ventas.FeriadosActualizar
    @p_anio    SMALLINT     = NULL,                       -- por defecto, el año en curso
    @p_url_base VARCHAR(200) = 'https://api.argentinadatos.com/v1/feriados'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @obj    INT;
    DECLARE @hr     INT;
    DECLARE @status INT       = NULL;
    -- IMPORTANTE: sp_OAGetProperty devuelve cadena vacía si el destino es
    -- NVARCHAR(MAX). Se usa un tipo de tamaño fijo para leer la respuesta.
    -- NVARCHAR admite hasta 4000 caracteres; el array de feriados de un año
    -- (~20 entradas) entra holgado y se conservan los acentos de los nombres.
    DECLARE @json   NVARCHAR(4000);
    DECLARE @errSrc VARCHAR(255);
    DECLARE @errDsc VARCHAR(500);
    DECLARE @msg    NVARCHAR(1000);
    DECLARE @url    VARCHAR(260);

    -- Año a consultar (por defecto, el año actual)
    SET @p_anio = ISNULL(@p_anio, YEAR(SYSDATETIME()));
    IF @p_anio < 2000 OR @p_anio > 2100
        THROW 50020, N'El año a consultar debe estar entre 2000 y 2100.', 1;

    -- Se arma la URL: {base}/{anio}
    SET @url = @p_url_base + '/' + CAST(@p_anio AS VARCHAR(4));

    -- 1) Instanciar el cliente HTTP.
    --    Se usa WinHttp.WinHttpRequest.5.1 (en lugar de MSXML2.ServerXMLHTTP)
    --    porque negocia mejor TLS 1.2 y la compresión, evitando que la API
    --    detrás de un CDN devuelva un cuerpo vacío.
    EXEC @hr = sp_OACreate 'WinHttp.WinHttpRequest.5.1', @obj OUT;
    IF @hr <> 0
    BEGIN
        EXEC sp_OAGetErrorInfo @obj, @errSrc OUT, @errDsc OUT;
        SET @msg = N'No se pudo crear el cliente HTTP. ' + ISNULL(@errDsc, N'');
        THROW 50021, @msg, 1;
    END

    BEGIN TRY
        -- 2) Abrir la conexión (GET), declarar cabeceras y enviar la solicitud.
        --    El User-Agent es obligatorio: sin él, el CDN puede responder
        --    con estado 200 pero cuerpo vacío.
        EXEC @hr = sp_OAMethod @obj, 'open', NULL, 'GET', @url, 'false';
        IF @hr <> 0 THROW 50022, N'Error al abrir la conexión HTTP.', 1;

        EXEC sp_OAMethod @obj, 'setRequestHeader', NULL, 'User-Agent', 'ParquesNacionalesDB/1.0';
        EXEC sp_OAMethod @obj, 'setRequestHeader', NULL, 'Accept', 'application/json';

        EXEC @hr = sp_OAMethod @obj, 'send';
        IF @hr <> 0 THROW 50023, N'Error al enviar la solicitud HTTP.', 1;

        -- 3) Verificar el código de estado HTTP
        EXEC @hr = sp_OAGetProperty @obj, 'status', @status OUT;
        IF ISNULL(@status, 0) <> 200
        BEGIN
            SET @msg = N'La API respondió con un estado HTTP no exitoso: '
                       + CAST(ISNULL(@status, -1) AS VARCHAR(10)) + N'.';
            THROW 50024, @msg, 1;
        END

        -- 4) Leer el cuerpo de la respuesta (JSON)
        EXEC @hr = sp_OAGetProperty @obj, 'responseText', @json OUT;
        IF @hr <> 0 OR @json IS NULL OR LTRIM(RTRIM(@json)) = ''
            THROW 50025, N'La API no devolvió contenido en la respuesta.', 1;

        -- 5) Liberar el objeto COM (ya tenemos el JSON)
        EXEC sp_OADestroy @obj;
        SET @obj = NULL;

        -- 6) Parsear el JSON con OPENJSON
        IF ISJSON(@json) = 0
            THROW 50026, N'La respuesta de la API no es un JSON válido.', 1;

        -- La respuesta es un array; se vuelca a una tabla temporal.
        DECLARE @feriados TABLE (
            fecha        DATE          NOT NULL,
            nombre       VARCHAR(150)  NULL,
            tipo         VARCHAR(50)   NULL
        );

        INSERT INTO @feriados (fecha, nombre, tipo)
        SELECT
            TRY_CONVERT(DATE, j.fecha, 23),   -- 'AAAA-MM-DD' (ISO)
            j.nombre,
            j.tipo
        FROM OPENJSON(@json)
        WITH (
            fecha   VARCHAR(10)  '$.fecha',
            nombre  VARCHAR(150) '$.nombre',
            tipo    VARCHAR(50)  '$.tipo'
        ) AS j
        WHERE TRY_CONVERT(DATE, j.fecha, 23) IS NOT NULL;

        IF NOT EXISTS (SELECT 1 FROM @feriados)
            THROW 50027, N'La API no devolvió feriados para el año consultado.', 1;

        -- 7) Sincronizar (upsert) contra ventas.Feriado.
        --    Se actualiza lo existente y se inserta lo nuevo, manteniendo la
        --    tabla como caché vigente del año.
        MERGE ventas.Feriado AS destino
        USING (
            SELECT fecha, nombre, tipo, @p_anio AS anio
            FROM @feriados
        ) AS origen
        ON destino.fecha = origen.fecha
        WHEN MATCHED THEN
            UPDATE SET
                destino.nombre         = origen.nombre,
                destino.tipo           = origen.tipo,
                destino.anio           = origen.anio,
                destino.fecha_consulta = SYSDATETIME()
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (fecha, nombre, tipo, anio)
            VALUES (origen.fecha, origen.nombre, origen.tipo, origen.anio);

        -- 8) Retornar los feriados vigentes para el año consultado
        SELECT id_feriado, fecha, nombre, tipo, anio, fecha_consulta
        FROM ventas.Feriado
        WHERE anio = @p_anio
        ORDER BY fecha;
    END TRY
    BEGIN CATCH
        -- Asegurar la liberación del objeto COM ante cualquier error
        IF @obj IS NOT NULL EXEC sp_OADestroy @obj;
        THROW;
    END CATCH
END
GO
PRINT 'OK - Store Procedure ventas.FeriadosActualizar creado/actualizado con éxito.';
GO

-- =========================================================================
-- 3. FUNCIÓN: ventas.fn_EsFeriado
--    Devuelve 1 si la fecha indicada es un feriado registrado, 0 en caso
--    contrario. Retorna 0 si la fecha es NULL.
-- =========================================================================
PRINT 'Creando o actualizando función ventas.fn_EsFeriado...';
GO
CREATE OR ALTER FUNCTION ventas.fn_EsFeriado
(
    @p_fecha DATE
)
RETURNS BIT
AS
BEGIN
    IF @p_fecha IS NULL
        RETURN 0;

    IF EXISTS (SELECT 1 FROM ventas.Feriado WHERE fecha = @p_fecha)
        RETURN 1;

    RETURN 0;
END
GO
PRINT 'OK - Función ventas.fn_EsFeriado creada/actualizada con éxito.';
GO

-- =========================================================================
-- 4. FUNCIÓN: ventas.fn_PrecioEntradaConFeriado
--    Aplica el recargo por feriado al valor base de una entrada. Si la
--    fecha es feriado, incrementa el precio en RECARGO_FERIADO (20%); de lo
--    contrario, devuelve el precio sin cambios. Retorna NULL si el precio
--    es NULL.
-- =========================================================================
PRINT 'Creando o actualizando función ventas.fn_PrecioEntradaConFeriado...';
GO
CREATE OR ALTER FUNCTION ventas.fn_PrecioEntradaConFeriado
(
    @p_precio_base DECIMAL(12,2),
    @p_fecha       DATE
)
RETURNS DECIMAL(12,2)
AS
BEGIN
    -- Recargo aplicado sobre el valor de la entrada en días feriados (20%).
    DECLARE @recargo DECIMAL(5,4) = 0.20;

    IF @p_precio_base IS NULL
        RETURN NULL;

    IF ventas.fn_EsFeriado(@p_fecha) = 1
        RETURN CAST(@p_precio_base * (1 + @recargo) AS DECIMAL(12,2));

    RETURN @p_precio_base;
END
GO
PRINT 'OK - Función ventas.fn_PrecioEntradaConFeriado creada/actualizada con éxito.';
GO

-- =========================================================================
-- 5. SP: ventas.CalcularValorEntrada
--    Calcula el valor final de una entrada para un parque, tipo de
--    visitante y fecha de acceso. Toma el precio vigente de
--    ventas.HistorialPrecio (el último ajuste cuya fecha_desde es menor o
--    igual a la fecha de acceso) y le aplica el recargo por feriado.
-- =========================================================================
PRINT 'Creando o actualizando Store Procedure ventas.CalcularValorEntrada...';
GO
CREATE OR ALTER PROCEDURE ventas.CalcularValorEntrada
    @p_id_parque         INT,
    @p_id_tipo_visitante INT,
    @p_fecha_acceso      DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @errores      NVARCHAR(MAX) = N'';
    DECLARE @precio_base  DECIMAL(12,2);

    IF NOT EXISTS (SELECT 1 FROM parques.Parque WHERE id_parque = @p_id_parque)
        SET @errores += N'- El parque indicado no existe.' + CHAR(13);
    IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE id_tipo_visitante = @p_id_tipo_visitante)
        SET @errores += N'- El tipo de visitante indicado no existe.' + CHAR(13);
    IF @p_fecha_acceso IS NULL
        SET @errores += N'- La fecha de acceso es obligatoria.' + CHAR(13);

    IF @errores != N'' THROW 50028, @errores, 1;

    -- Precio vigente: último ajuste cuya vigencia ya comenzó a la fecha de acceso
    SELECT TOP 1 @precio_base = precio
    FROM ventas.HistorialPrecio
    WHERE id_parque = @p_id_parque
      AND id_tipo_visitante = @p_id_tipo_visitante
      AND fecha_desde <= @p_fecha_acceso
    ORDER BY fecha_desde DESC;

    IF @precio_base IS NULL
        THROW 50029, N'No hay un precio de entrada vigente para el parque, tipo de visitante y fecha indicados.', 1;

    SELECT
        @p_id_parque                                                  AS id_parque,
        @p_id_tipo_visitante                                          AS id_tipo_visitante,
        @p_fecha_acceso                                               AS fecha_acceso,
        ventas.fn_EsFeriado(@p_fecha_acceso)                          AS es_feriado,
        @precio_base                                                  AS precio_base,
        ventas.fn_PrecioEntradaConFeriado(@precio_base, @p_fecha_acceso) AS precio_final;
END
GO
PRINT 'OK - Store Procedure ventas.CalcularValorEntrada creado/actualizado con éxito.';
GO

PRINT '=========================================================================';
PRINT 'FIN DEL SCRIPT: OBJETOS DE CONSUMO DE API DE FERIADOS CREADOS';
PRINT '=========================================================================';
GO
