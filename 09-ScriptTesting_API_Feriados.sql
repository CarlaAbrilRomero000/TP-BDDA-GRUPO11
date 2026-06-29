/*
=============================================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Archivo:     09-ScriptTesting_API_Feriados.sql
Descripción: Pruebas del consumo de la API de feriados de Argentina
             (ArgentinaDatos) y del cálculo del valor de entradas con recargo
             por feriado.

             Requisitos previos:
             - Ejecutar el scrispt 09 para crear los objetos de feriados.
             - El servidor debe tener salida a Internet (HTTPS) y OLE
               Automation habilitado.
=============================================================================
*/

USE ParquesNacionalesDB;
GO

PRINT '=========================================================================';
PRINT 'INICIANDO TESTING DE CONSUMO DE API DE FERIADOS (ENTREGA 9)';
PRINT '=========================================================================';
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 1: Obtener los feriados del año en curso desde la API (ArgentinaDatos)';
PRINT '-------------------------------------------------------------------------';
EXEC ventas.FeriadosActualizar;
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 2: Obtener los feriados de un año específico (2026)';
PRINT '-------------------------------------------------------------------------';
EXEC ventas.FeriadosActualizar @p_anio = 2026;
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 3: Histórico de feriados registrados';
PRINT '-------------------------------------------------------------------------';
SELECT id_feriado, fecha, nombre, tipo, anio, fecha_consulta
FROM ventas.Feriado
ORDER BY fecha;
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 4: Verificar si una fecha es feriado';
PRINT '-------------------------------------------------------------------------';
SELECT
    CAST('2026-01-01' AS DATE) AS Fecha, ventas.fn_EsFeriado('2026-01-01') AS Es_Feriado   -- Año Nuevo (esperado 1)
UNION ALL
SELECT
    CAST('2026-01-02' AS DATE),           ventas.fn_EsFeriado('2026-01-02');               -- Día hábil (esperado 0)
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 5: Aplicar recargo por feriado sobre un precio base de ejemplo';
PRINT '-------------------------------------------------------------------------';
SELECT
    10000.00                                                       AS Precio_Base,
    '2026-01-01'                                                   AS Fecha_Feriado,
    ventas.fn_PrecioEntradaConFeriado(10000.00, '2026-01-01')     AS Precio_Con_Recargo,   -- esperado 12000.00
    '2026-01-02'                                                   AS Fecha_Habil,
    ventas.fn_PrecioEntradaConFeriado(10000.00, '2026-01-02')     AS Precio_Sin_Recargo;   -- esperado 10000.00
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 6: Cálculo del valor de una entrada (precio vigente + recargo)';
PRINT '         Ajustar los IDs según datos cargados en la base.';
PRINT '-------------------------------------------------------------------------';
DECLARE @id_parque INT, @id_tipo INT;
SELECT TOP 1 @id_parque = id_parque, @id_tipo = id_tipo_visitante
FROM ventas.HistorialPrecio
ORDER BY fecha_desde DESC;

IF @id_parque IS NOT NULL
BEGIN
    PRINT 'Cálculo en fecha feriado (2026-01-01):';
    EXEC ventas.CalcularValorEntrada @p_id_parque = @id_parque, @p_id_tipo_visitante = @id_tipo, @p_fecha_acceso = '2026-01-01';

    PRINT 'Cálculo en día hábil (2026-01-02):';
    EXEC ventas.CalcularValorEntrada @p_id_parque = @id_parque, @p_id_tipo_visitante = @id_tipo, @p_fecha_acceso = '2026-01-02';
END
ELSE
    PRINT 'No hay precios en ventas.HistorialPrecio; se omite el Test 6.';
GO

PRINT '';
PRINT '=========================================================================';
PRINT 'FIN DEL TESTING DE CONSUMO DE API DE FERIADOS';
PRINT '=========================================================================';
GO
