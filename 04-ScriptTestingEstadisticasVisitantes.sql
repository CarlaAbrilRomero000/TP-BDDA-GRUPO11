/*
==============================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Fecha:       13/06/2026
Descripción: Script de pruebas para
             importaciones.ImportarEstadisticasVisitantes.

             Orden de ejecución:
               1. 01-ScriptCreacionTablasYSchemas.sql
               2. 02-ScriptABM_SPs.sql
               3. 03-ScriptLogicaNegocio_SPs.sql
               4. 04-ScriptEstadisticasVisitantes.sql
               5. Este script

             Cada caso puede ejecutarse de forma independiente
             seleccionando el bloque correspondiente.

             Archivo de errores requerido para CASO 3 y 4:
             Crear C:\Importaciones\casos_error.csv con:

               indice_tiempo,region_de_destino,origen_visitantes,visitas,observaciones
               2024-1-01,santa cruz,residentes,500,Carga inicial
               2024-1-01,santa cruz,residentes,550,Correccion de carga
               2024-1-01,chubut,residentes,-10,Visitas negativas - debe rechazarse
               2024-99-01,neuquen,residentes,300,Fecha invalida - debe rechazarse
               2024-1-01,,no residentes,120,Region vacia - debe rechazarse
               2024-1-01,misiones,total,abc,Visitas no numericas - debe rechazarse
==============================================================
*/

USE ParquesNacionalesDB;
GO

-- ==============================================================
-- CASO 1 - Importación exitosa del archivo principal
-- Se espera: registros_insertados > 0, rechazados = 0
-- ==============================================================

PRINT '==============================================================';
PRINT ' CASO 1 - Importación exitosa del archivo principal';
PRINT '==============================================================';

EXEC importaciones.ImportarEstadisticasVisitantes
    @p_ruta_archivo = 'visitas-residentes-y-no-residentes-por-region.csv';

SELECT TOP 20
    id_visitantes_parque,
    indice_tiempo,
    region_destino,
    origen_visitantes,
    visitas,
    observaciones,
    fecha_carga
FROM estadisticas.VisitantesParques
ORDER BY indice_tiempo, region_destino, origen_visitantes;

SELECT COUNT(*) AS total_filas_importadas FROM estadisticas.VisitantesParques;
GO

-- ==============================================================
-- CASO 2 - Reimportación del mismo archivo
-- Se espera: registros_insertados = 0, registros_actualizados = 0
-- La cantidad total de filas no debe cambiar respecto al CASO 1
-- ==============================================================

PRINT '==============================================================';
PRINT ' CASO 2 - Reimportación del mismo archivo (no debe duplicar)';
PRINT '==============================================================';

DECLARE @v_total_antes INT = (SELECT COUNT(*) FROM estadisticas.VisitantesParques);

EXEC importaciones.ImportarEstadisticasVisitantes
    @p_ruta_archivo = 'visitas-residentes-y-no-residentes-por-region.csv';

DECLARE @v_total_despues INT = (SELECT COUNT(*) FROM estadisticas.VisitantesParques);

SELECT
    @v_total_antes   AS filas_antes,
    @v_total_despues AS filas_despues,
    CASE WHEN @v_total_antes = @v_total_despues
         THEN 'OK - sin duplicados'
         ELSE 'ERROR - se generaron duplicados'
    END AS resultado;
GO

-- ==============================================================
-- CASO 3 - Archivo con casos de error mixtos
-- Se espera: registros_insertados = 1 (santa cruz/residentes, visitas=550)
--            registros_rechazados = 5 (duplicado + negativos +
--            fecha inválida + región vacía + visitas no numéricas)
-- ==============================================================

PRINT '==============================================================';
PRINT ' CASO 3 - Visitas negativas, fecha inválida, región vacía,';
PRINT '          visitas no numéricas y duplicado dentro del archivo';
PRINT '==============================================================';

EXEC importaciones.ImportarEstadisticasVisitantes
    @p_ruta_archivo = 'casos_error.csv';

-- Fila válida que debió insertarse
SELECT TOP 5
    indice_tiempo,
    region_destino,
    origen_visitantes,
    visitas,
    observaciones
FROM estadisticas.VisitantesParques
WHERE region_destino = 'santa cruz'
  AND origen_visitantes = 'residentes';

-- Filas rechazadas registradas en la tabla de errores
SELECT TOP 10
    id_error,
    fecha_error,
    motivo_error,
    indice_tiempo_valor,
    region_destino_valor,
    visitas_valor
FROM estadisticas.ErroresImportacion
WHERE archivo_origen = 'C:\Importaciones\casos_error.csv'
ORDER BY id_error;
GO

-- ==============================================================
-- CASO 4 - Reimportación del archivo de errores
-- Se espera: registros_insertados = 0, registros_actualizados = 0
-- La fila de santa cruz ya existe y no cambió, no debe actualizarse
-- ==============================================================

PRINT '==============================================================';
PRINT ' CASO 4 - Reimportación del archivo de casos de error';
PRINT '          (sin cambios en la tabla destino)';
PRINT '==============================================================';

EXEC importaciones.ImportarEstadisticasVisitantes
    @p_ruta_archivo = 'casos_error.csv';

SELECT TOP 5
    indice_tiempo,
    region_destino,
    origen_visitantes,
    visitas,
    fecha_carga,
    fecha_actualizacion
FROM estadisticas.VisitantesParques
WHERE region_destino = 'santa cruz'
  AND origen_visitantes = 'residentes';
GO

-- ==============================================================
-- CASO 5 - Archivo inexistente
-- Se espera: error controlado con mensaje descriptivo
-- ==============================================================

PRINT '==============================================================';
PRINT ' CASO 5 - Archivo inexistente';
PRINT '==============================================================';

BEGIN TRY
    EXEC importaciones.ImportarEstadisticasVisitantes
        @p_ruta_archivo = 'no_existe.csv';
END TRY
BEGIN CATCH
    PRINT 'OK - Error esperado capturado: ' + ERROR_MESSAGE();
END CATCH
GO

-- ==============================================================
-- VERIFICACIÓN FINAL - La tabla de staging debe estar vacía
-- ==============================================================

PRINT '==============================================================';
PRINT ' Verificación final: staging debe estar vacío';
PRINT '==============================================================';

SELECT COUNT(*) AS filas_en_staging FROM estadisticas.StagingVisitantes;
GO
