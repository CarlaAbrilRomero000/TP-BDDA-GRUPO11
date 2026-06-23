/*
=============================================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Archivo:     11-ScriptTesting_API_Cotizacion.sql
Descripción: Pruebas del consumo de la API de cotización de moneda extranjera
             (DolarAPI) y de la conversión de montos a dólares.

             Requisitos previos:
             - Ejecutar el script 10 para crear los objetos de cotización.
             - El servidor debe tener salida a Internet (HTTPS) y OLE
               Automation habilitado.
=============================================================================
*/

USE ParquesNacionalesDB;
GO

PRINT '=========================================================================';
PRINT 'INICIANDO TESTING DE CONSUMO DE API DE COTIZACIÓN (ENTREGA 8)';
PRINT '=========================================================================';
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 1: Obtener la cotización actual desde la API (DolarAPI)';
PRINT '-------------------------------------------------------------------------';
EXEC ventas.CotizacionDolarActualizar;
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 2: Histórico de cotizaciones registradas';
PRINT '-------------------------------------------------------------------------';
SELECT id_cotizacion, moneda, casa, compra, venta, fecha_actualizacion, fecha_consulta
FROM ventas.CotizacionDolar
ORDER BY fecha_consulta DESC;
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 3: Cotización vigente (valor de venta)';
PRINT '-------------------------------------------------------------------------';
SELECT ventas.fn_CotizacionVigente() AS Cotizacion_Venta_Vigente;
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 4: Conversión de un monto de ejemplo (ARS -> USD)';
PRINT '-------------------------------------------------------------------------';
SELECT
    50000.00                                  AS Monto_ARS,
    ventas.fn_ConvertirArsAUsd(50000.00)      AS Monto_USD,
    ventas.fn_CotizacionVigente()             AS Cotizacion_Aplicada;
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 5: Reporte de ingresos por parque con equivalente en USD';
PRINT '-------------------------------------------------------------------------';
EXEC dbo.Ingresos_Parque_USD;
GO

PRINT '';
PRINT '=========================================================================';
PRINT 'FIN DEL TESTING DE CONSUMO DE API DE COTIZACIÓN';
PRINT '=========================================================================';
GO
