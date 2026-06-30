/*
=============================================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Archivo:     08-ScriptTesting_API_Cotizacion.sql
Descripción: Pruebas del consumo de la API de cotización de moneda extranjera
             (DolarAPI) y de la conversión de montos a dólares.

             Requisitos previos:
             - Ejecutar el script 01B (funciones) y el script 08 (SPs de
               cotización) para crear los objetos involucrados.
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
-- RESULTADO ESPERADO: el SP consume la API y devuelve UNA fila con la
-- cotización recién insertada (id_cotizacion, moneda='USD', casa='oficial',
-- compra y venta > 0, fecha_actualizacion informada por la API y
-- fecha_consulta = momento actual). Si no hay Internet u OLE Automation
-- deshabilitado, lanza un error 500xx con el detalle (no inserta nada).
EXEC ventas.CotizacionDolarActualizar;
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 2: Histórico de cotizaciones registradas';
PRINT '-------------------------------------------------------------------------';
-- RESULTADO ESPERADO: lista todas las cotizaciones almacenadas, ordenadas de
-- más reciente a más antigua. Debe aparecer al menos la fila insertada en el
-- Test 1 en la primera posición. Cada cuantas veces se corra el Test 1, se
-- suma una fila más (la tabla funciona como histórico/auditoría).
SELECT id_cotizacion, moneda, casa, compra, venta, fecha_actualizacion, fecha_consulta
FROM ventas.CotizacionDolar
ORDER BY fecha_consulta DESC;
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 3: Cotización vigente (valor de venta)';
PRINT '-------------------------------------------------------------------------';
-- RESULTADO ESPERADO: un único valor decimal igual al campo "venta" de la
-- cotización más reciente (la mostrada primera en el Test 2). Si nunca se
-- registró una cotización, la función devuelve NULL.
SELECT ventas.fn_CotizacionVigente() AS Cotizacion_Venta_Vigente;
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 4: Conversión de un monto de ejemplo (ARS -> USD)';
PRINT '-------------------------------------------------------------------------';
-- RESULTADO ESPERADO: una fila con Monto_ARS = 50000.00, Cotizacion_Aplicada
-- igual a la venta vigente (Test 3) y Monto_USD = 50000 / Cotizacion_Aplicada
-- redondeado a 2 decimales. Ej.: con venta = 1490 -> Monto_USD ≈ 33.56.
-- Si no hay cotización registrada, Monto_USD es NULL.
SELECT
    50000.00                                  AS Monto_ARS,
    ventas.fn_ConvertirArsAUsd(50000.00)      AS Monto_USD,
    ventas.fn_CotizacionVigente()             AS Cotizacion_Aplicada;
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 5: Reporte de ingresos por parque con equivalente en USD';
PRINT '-------------------------------------------------------------------------';
-- RESULTADO ESPERADO: el reporte de ingresos por parque/año/mes/semana con
-- las columnas en pesos (Total_Entradas, Total_Tours, Total_Concesiones,
-- Total_General) y sus equivalentes en dólares (sufijo _USD), más la columna
-- Cotizacion_USD_Aplicada (igual a la venta vigente). Cada columna _USD debe
-- ser ≈ su columna en ARS dividida por la cotización aplicada. Si no hay
-- cotización registrada, las columnas _USD salen en NULL. Si no hay ventas
-- cargadas, el reporte vuelve vacío.
EXEC dbo.Ingresos_Parque_USD;
GO

PRINT '';
PRINT '=========================================================================';
PRINT 'FIN DEL TESTING DE CONSUMO DE API DE COTIZACIÓN';
PRINT '=========================================================================';
GO
