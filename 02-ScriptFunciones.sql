/*
=============================================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Archivo:     02-ScriptFunciones.sql
Descripción: Creación centralizada de las FUNCIONES escalares del modelo.

             Siguiendo la consigna ("un script para las tablas, otro para los
             SP, otro para las vistas/funciones"), todas las funciones se
             agrupan acá. El script se ejecuta DESPUÉS del 00 (creación de
             tablas) y del 01 (ABM), y ANTES de los scripts de SP que las
             consumen (08 - Cotización y 09 - Feriados). Las funciones solo
             dependen de tablas creadas en el script 00; el 01 (ABM) se ubica
             antes para que el testing de funciones (02-ScriptTesting_Funciones)
             pueda usar los SP de ABM al cargar/limpiar sus datos de prueba.

             Orden de ejecución dentro de la solución:
               00  - Creación de tablas y schemas
               01  - ABM (SPs)
               02  - Este script (funciones)        <--
               ...
               08  - API Cotización (SPs que usan fn_CotizacionVigente / fn_ConvertirArsAUsd)
               09  - API Feriados   (SPs que usan fn_EsFeriado / fn_PrecioEntradaConFeriado)

             Funciones incluidas:
               1. ventas.fn_CotizacionVigente()        - última cotización (venta)
               2. ventas.fn_ConvertirArsAUsd(@ars)     - convierte ARS -> USD
               3. ventas.fn_EsFeriado(@fecha)          - 1 si la fecha es feriado
               4. ventas.fn_PrecioEntradaConFeriado(@precio,@fecha) - recargo feriado

             NOTA: las funciones se crean con CREATE OR ALTER, por lo que el
             script es idempotente y re-ejecutable sin validaciones extra.
             Aun así, se valida la existencia de las tablas que consultan.
=============================================================================
*/

USE ParquesNacionalesDB;
GO

PRINT '=========================================================================';
PRINT 'INICIANDO CREACIÓN DE FUNCIONES ESCALARES';
PRINT '=========================================================================';
GO

-- =========================================================================
-- 0. VALIDACIÓN DE DEPENDENCIAS
--    Las funciones consultan tablas creadas en el script 00. Si no existen,
--    se aborta con un mensaje claro.
-- =========================================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CotizacionDolar' AND schema_id = SCHEMA_ID('ventas'))
    THROW 50100, N'Falta la tabla ventas.CotizacionDolar. Ejecute primero el script 00-ScriptCreacionTablasYSchemas.sql.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Feriado' AND schema_id = SCHEMA_ID('ventas'))
    THROW 50101, N'Falta la tabla ventas.Feriado. Ejecute primero el script 00-ScriptCreacionTablasYSchemas.sql.', 1;
GO

-- =========================================================================
-- 1. FUNCIÓN: ventas.fn_CotizacionVigente
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
-- 2. FUNCIÓN: ventas.fn_ConvertirArsAUsd
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

PRINT '=========================================================================';
PRINT 'FIN DEL SCRIPT: FUNCIONES ESCALARES CREADAS';
PRINT '=========================================================================';
GO
