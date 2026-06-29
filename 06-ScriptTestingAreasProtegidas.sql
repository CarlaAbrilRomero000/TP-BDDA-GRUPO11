/*
==============================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Fecha:       16/06/2026
Descripción: Script de pruebas para
             importaciones.ImportarAreasProtegidas.

             Orden de ejecución:
               1. 01-ScriptCreacionTablasYSchemas.sql
               2. 02-ScriptABM_SPs.sql
               3. 03-ScriptLogicaNegocio_SPs.sql
               4. 06-ScriptAreasProtegidas.sql
               5. Este script

             Cada caso puede ejecutarse de forma independiente
             seleccionando el bloque correspondiente.

             Archivo JSON requerido para CASO 3 y 4:
             Crear C:\Importaciones\casos_error_areas.json con:

             [
               { "jurisdiccion": "Prueba Patagonia", "total_cantidad": 10, "ap_nac": 3, "ap_prov": 7, "ap_desig_inter": 0, "total_ha": 500000, "terrestre_ha": 400000, "marino_ha": 100000, "porcentaje_terrestre_protegido": 8.5 },
               { "jurisdiccion": "Prueba Patagonia", "total_cantidad": 10, "ap_nac": 3, "ap_prov": 7, "ap_desig_inter": 0, "total_ha": 500000, "terrestre_ha": 400000, "marino_ha": 100000, "porcentaje_terrestre_protegido": 8.5 },
               { "jurisdiccion": null,               "total_cantidad": 5,  "ap_nac": 1, "ap_prov": 4, "ap_desig_inter": 0, "total_ha": 200000, "terrestre_ha": 200000, "marino_ha": 0,      "porcentaje_terrestre_protegido": 3.2 },
               { "jurisdiccion": "Prueba Negativa",  "total_cantidad": -5, "ap_nac": 1, "ap_prov": 4, "ap_desig_inter": 0, "total_ha": 200000, "terrestre_ha": 200000, "marino_ha": 0,      "porcentaje_terrestre_protegido": 3.2 }
             ]
==============================================================
*/

USE ParquesNacionalesDB;
GO

-- ==============================================================
-- CASO 1 - Importación exitosa del archivo JSON principal
-- Se espera: registros_insertados > 0, rechazados = 0
-- ==============================================================

PRINT '==============================================================';
PRINT ' CASO 1 - Importación exitosa del archivo JSON principal';
PRINT '==============================================================';

EXEC importaciones.ImportarAreasProtegidas
    @p_ruta_archivo = 'areas-protegidas-por-jurisdiccion.json';

SELECT TOP 20
    id_area,
    jurisdiccion,
    total_cantidad,
    ap_nac,
    ap_prov,
    total_ha,
    porcentaje_terrestre_protegido,
    fecha_carga
FROM estadisticas.AreasProtegidasJurisdiccion
ORDER BY jurisdiccion;

SELECT COUNT(*) AS total_jurisdicciones_importadas
FROM estadisticas.AreasProtegidasJurisdiccion;
GO

-- ==============================================================
-- CASO 2 - Reimportación del mismo archivo JSON
-- Se espera: registros_insertados = 0, registros_actualizados = 0
-- La tabla destino no debe crecer
-- ==============================================================

PRINT '==============================================================';
PRINT ' CASO 2 - Reimportación del mismo archivo (no debe duplicar)';
PRINT '==============================================================';

DECLARE @v_total_antes INT = (SELECT COUNT(*) FROM estadisticas.AreasProtegidasJurisdiccion);

EXEC importaciones.ImportarAreasProtegidas
    @p_ruta_archivo = 'areas-protegidas-por-jurisdiccion.json';

DECLARE @v_total_despues INT = (SELECT COUNT(*) FROM estadisticas.AreasProtegidasJurisdiccion);

SELECT
    @v_total_antes   AS filas_antes,
    @v_total_despues AS filas_despues,
    CASE WHEN @v_total_antes = @v_total_despues
         THEN 'OK - sin duplicados'
         ELSE 'ERROR - se generaron duplicados'
    END AS resultado;
GO

-- ==============================================================
-- CASO 3 - Archivo JSON con errores variados
-- Se espera:
--   registros_insertados = 1 (Prueba Patagonia, segunda ocurrencia)
--   registros_rechazados = 3 (duplicado + jurisdiccion nula
--                             + total_cantidad negativo)
-- ==============================================================

PRINT '==============================================================';
PRINT ' CASO 3 - Jurisdiccion nula, total negativo y duplicado';
PRINT '          dentro del archivo JSON';
PRINT '==============================================================';

EXEC importaciones.ImportarAreasProtegidas
    @p_ruta_archivo = 'casos_error_areas.json';

-- Fila válida que debió insertarse
SELECT TOP 5
    jurisdiccion,
    total_cantidad,
    ap_nac,
    ap_prov,
    total_ha,
    fecha_carga
FROM estadisticas.AreasProtegidasJurisdiccion
WHERE jurisdiccion = 'Prueba Patagonia';

-- Filas rechazadas registradas en la tabla de errores
SELECT TOP 10
    id_error,
    fecha_error,
    motivo_error,
    indice_tiempo_valor  AS jurisdiccion_valor,
    region_destino_valor AS total_cantidad_valor
FROM estadisticas.ErroresImportacion
WHERE archivo_origen LIKE '%casos_error_areas%'
ORDER BY id_error;
GO

-- ==============================================================
-- CASO 4 - Reimportación del archivo de errores
-- Se espera: registros_insertados = 0, registros_actualizados = 0
-- Prueba Patagonia ya existe y no cambió: no debe actualizarse
-- ==============================================================

PRINT '==============================================================';
PRINT ' CASO 4 - Reimportación del archivo de errores';
PRINT '          (sin cambios en la tabla destino)';
PRINT '==============================================================';

EXEC importaciones.ImportarAreasProtegidas
    @p_ruta_archivo = 'casos_error_areas.json';

SELECT TOP 5
    jurisdiccion,
    total_cantidad,
    total_ha,
    fecha_carga,
    fecha_actualizacion
FROM estadisticas.AreasProtegidasJurisdiccion
WHERE jurisdiccion = 'Prueba Patagonia';
GO

-- ==============================================================
-- CASO 5 - Archivo inexistente
-- Se espera: error controlado con mensaje descriptivo
-- ==============================================================

PRINT '==============================================================';
PRINT ' CASO 5 - Archivo inexistente';
PRINT '==============================================================';

BEGIN TRY
    EXEC importaciones.ImportarAreasProtegidas
        @p_ruta_archivo = 'no_existe.json';
END TRY
BEGIN CATCH
    PRINT 'OK - Error esperado capturado: ' + ERROR_MESSAGE();
END CATCH
GO
