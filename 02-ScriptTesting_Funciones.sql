/*
=============================================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Archivo:     02-ScriptTesting_Funciones.sql
Descripción: Pruebas de las 4 funciones escalares creadas en el script
             02-ScriptFunciones.sql:
               - ventas.fn_CotizacionVigente()
               - ventas.fn_ConvertirArsAUsd(@ars)
               - ventas.fn_EsFeriado(@fecha)
               - ventas.fn_PrecioEntradaConFeriado(@precio, @fecha)

             El script es self-contained y re-ejecutable: carga sus propios
             datos de prueba mediante los SP de ABM (una cotización con
             venta = 1000 y un feriado de prueba el 2099-07-15), ejecuta las
             pruebas y limpia los datos al final. NO consume las APIs externas
             (no requiere Internet ni OLE Automation): solo prueba la lógica
             de las funciones sobre datos controlados.

             Requisitos previos (orden de ejecución):
               00 - Creación de tablas y schemas
               01 - ABM (SPs usados para cargar/limpiar los datos de prueba)
               02 - Funciones escalares (objetos bajo prueba)

             Datos de prueba (sentinelas para poder limpiarlos):
               - Cotización: nombre = 'FN-TEST', venta = 1000.0000
               - Feriado:    fecha  = '2099-07-15', nombre = 'Feriado FN-TEST'
=============================================================================
*/

USE ParquesNacionalesDB;
GO

PRINT '=========================================================================';
PRINT 'INICIANDO TESTING DE FUNCIONES ESCALARES';
PRINT '=========================================================================';
GO

-- =========================================================================
-- LIMPIEZA PREVIA — elimina datos FN-TEST de corridas anteriores (vía SPs).
--   Hace el script re-ejecutable. Si no hay residuales, no hace nada.
-- =========================================================================
SET NOCOUNT ON;

PRINT '';
PRINT 'Limpieza previa de datos FN-TEST residuales (si existen)...';

DECLARE @id_prev INT;

WHILE EXISTS (SELECT 1 FROM ventas.CotizacionDolar WHERE nombre = 'FN-TEST')
BEGIN
    SELECT TOP 1 @id_prev = id_cotizacion FROM ventas.CotizacionDolar WHERE nombre = 'FN-TEST';
    EXEC ventas.CotizacionDolarEliminar @p_id_cotizacion = @id_prev;
END

WHILE EXISTS (SELECT 1 FROM ventas.Feriado WHERE fecha = '2099-07-15')
BEGIN
    SELECT TOP 1 @id_prev = id_feriado FROM ventas.Feriado WHERE fecha = '2099-07-15';
    EXEC ventas.FeriadoEliminar @p_id_feriado = @id_prev;
END
PRINT 'OK - Limpieza previa completada.';
GO

-- =========================================================================
-- PREPARACIÓN — carga de datos de prueba controlados (vía SPs de ABM)
-- =========================================================================
PRINT '';
PRINT 'Cargando datos de prueba (cotización venta=1000 y feriado 2099-07-15)...';

EXEC ventas.CotizacionDolarInsertar
    @p_moneda              = 'USD',
    @p_casa                = 'oficial',
    @p_compra              = 950.0000,
    @p_venta               = 1000.0000,
    @p_nombre              = 'FN-TEST',
    @p_fecha_actualizacion = '2099-07-15T00:00:00';

EXEC ventas.FeriadoInsertar
    @p_fecha  = '2099-07-15',
    @p_nombre = 'Feriado FN-TEST',
    @p_tipo   = 'inamovible',
    @p_anio   = 2099;

PRINT 'OK - Datos de prueba cargados.';
GO

-- =========================================================================
-- Test 1: ventas.fn_CotizacionVigente()
-- =========================================================================
PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 1: fn_CotizacionVigente() devuelve la venta de la última cotización';
PRINT '-------------------------------------------------------------------------';
-- RESULTADO ESPERADO: 1000.0000. La cotización FN-TEST recién insertada es la
-- más reciente (mayor fecha_consulta e id), por lo que la función vigente debe
-- devolver su valor de venta. Si la tabla estuviera vacía, devolvería NULL.
SELECT ventas.fn_CotizacionVigente() AS Cotizacion_Vigente_Esperada_1000;
GO

-- =========================================================================
-- Test 2: ventas.fn_ConvertirArsAUsd(@ars)
-- =========================================================================
PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 2: fn_ConvertirArsAUsd convierte ARS -> USD con la cotización vigente';
PRINT '-------------------------------------------------------------------------';
-- RESULTADO ESPERADO: una fila con
--   Convertir_50000 = 50.00      (50000 / 1000)
--   Convertir_NULL  = NULL       (VALIDACIÓN: monto NULL -> NULL)
SELECT
    ventas.fn_ConvertirArsAUsd(50000.00) AS Convertir_50000_Esperado_50,
    ventas.fn_ConvertirArsAUsd(NULL)     AS Convertir_NULL_Esperado_NULL;
GO

-- =========================================================================
-- Test 3: ventas.fn_EsFeriado(@fecha)
-- =========================================================================
PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 3: fn_EsFeriado indica si una fecha es feriado registrado';
PRINT '-------------------------------------------------------------------------';
-- RESULTADO ESPERADO: una fila con
--   EsFeriado_SI   = 1     (2099-07-15 está cargado como feriado)
--   EsFeriado_NO   = 0     (2099-07-16 no es feriado)
--   EsFeriado_NULL = 0     (VALIDACIÓN: fecha NULL -> 0)
SELECT
    ventas.fn_EsFeriado('2099-07-15') AS EsFeriado_SI_Esperado_1,
    ventas.fn_EsFeriado('2099-07-16') AS EsFeriado_NO_Esperado_0,
    ventas.fn_EsFeriado(NULL)         AS EsFeriado_NULL_Esperado_0;
GO

-- =========================================================================
-- Test 4: ventas.fn_PrecioEntradaConFeriado(@precio, @fecha)
-- =========================================================================
PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 4: fn_PrecioEntradaConFeriado aplica el recargo (20%) en feriados';
PRINT '-------------------------------------------------------------------------';
-- RESULTADO ESPERADO: una fila con
--   Precio_EnFeriado = 1200.00   (1000 * 1.20, porque 2099-07-15 es feriado)
--   Precio_DiaHabil  = 1000.00   (sin recargo, 2099-07-16 no es feriado)
--   Precio_NULL      = NULL      (VALIDACIÓN: precio base NULL -> NULL)
SELECT
    ventas.fn_PrecioEntradaConFeriado(1000.00, '2099-07-15') AS Precio_EnFeriado_Esperado_1200,
    ventas.fn_PrecioEntradaConFeriado(1000.00, '2099-07-16') AS Precio_DiaHabil_Esperado_1000,
    ventas.fn_PrecioEntradaConFeriado(NULL,    '2099-07-15') AS Precio_NULL_Esperado_NULL;
GO

-- =========================================================================
-- LIMPIEZA FINAL — elimina los datos de prueba FN-TEST (vía SPs)
-- =========================================================================
PRINT '';
PRINT 'Limpieza final de datos de prueba FN-TEST...';
SET NOCOUNT ON;

DECLARE @id INT;

WHILE EXISTS (SELECT 1 FROM ventas.CotizacionDolar WHERE nombre = 'FN-TEST')
BEGIN
    SELECT TOP 1 @id = id_cotizacion FROM ventas.CotizacionDolar WHERE nombre = 'FN-TEST';
    EXEC ventas.CotizacionDolarEliminar @p_id_cotizacion = @id;
END

WHILE EXISTS (SELECT 1 FROM ventas.Feriado WHERE fecha = '2099-07-15')
BEGIN
    SELECT TOP 1 @id = id_feriado FROM ventas.Feriado WHERE fecha = '2099-07-15';
    EXEC ventas.FeriadoEliminar @p_id_feriado = @id;
END

-- Verificación de limpieza
SELECT CASE WHEN COUNT(*) = 0 THEN 'OK - Sin cotizaciones FN-TEST residuales'
            ELSE 'ATENCIÓN - Quedan ' + CAST(COUNT(*) AS VARCHAR) + ' cotizaciones' END AS resultado
FROM ventas.CotizacionDolar WHERE nombre = 'FN-TEST';

SELECT CASE WHEN COUNT(*) = 0 THEN 'OK - Sin feriados FN-TEST residuales'
            ELSE 'ATENCIÓN - Quedan ' + CAST(COUNT(*) AS VARCHAR) + ' feriados' END AS resultado
FROM ventas.Feriado WHERE fecha = '2099-07-15';
GO

PRINT '';
PRINT '=========================================================================';
PRINT 'FIN DEL TESTING DE FUNCIONES ESCALARES';
PRINT '=========================================================================';
GO
