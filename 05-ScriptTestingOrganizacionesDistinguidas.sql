/*
==============================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Fecha:       16/06/2026
Descripción: Script de pruebas para
             importaciones.ImportarOrganizacionesDistinguidas.

             Orden de ejecución:
               1. 00-ScriptCreacionTablasYSchemas.sql
               2. 02-ScriptABM_SPs.sql
               3. 03-ScriptLogicaNegocio_SPs.sql
               4. 04-ScriptEstadisticasVisitantes.sql
               5. 05-ScriptOrganizacionesDistinguidas.sql
               6. Este script

             Cada caso puede ejecutarse de forma independiente
             seleccionando el bloque correspondiente.

             Archivo requerido para CASO 3 y 4:
             Crear C:\Importaciones\casos_error_org.csv con:

               organizacion,rubro,subrubro,calle,numero,pais,provincia,ciudad,telefono,facebook,web,programa,fecha_distincion,fecha_revalidacion
               Hotel Las Piedras,Alojamiento,Rural,Ruta 1,Km 10,Argentina,Buenos Aires,Lujan,,,, ISO 9001:2000,2020-01-15,
               Hotel Las Piedras,Alojamiento,Rural,Ruta 1,Km 10,Argentina,Buenos Aires,Lujan,,,,ISO 9001:2000,2020-01-15,
               ,Alojamiento,Rural,Ruta 2,123,Argentina,Mendoza,Mendoza,,,,ISO 9001:2000,2020-03-10,
               Hostel Sin Rubro,,Rural,Ruta 3,456,Argentina,Cordoba,Cordoba,,,,ISO 9001:2000,2020-05-20,
               Hotel Fecha Mal,Alojamiento,,Ruta 4,789,Argentina,Jujuy,Jujuy,,,,ISO 9001:2000,99-99-9999,
==============================================================
*/

USE ParquesNacionalesDB;
GO

-- ==============================================================
-- CASO 1 - Importación exitosa del archivo principal
-- Se espera: registros_insertados > 0, rechazados > 0
--            (el archivo real contiene duplicados y fechas inválidas)
-- ==============================================================

PRINT '==============================================================';
PRINT ' CASO 1 - Importación exitosa del archivo principal';
PRINT '==============================================================';

EXEC importaciones.ImportarOrganizacionesDistinguidas
    @p_ruta_archivo = 'registro-organizaciones-distinguidas.csv';

SELECT TOP 20
    id_organizacion,
    organizacion,
    rubro,
    provincia,
    ciudad,
    fecha_distincion,
    fecha_carga
FROM estadisticas.OrganizacionesDistinguidas
ORDER BY fecha_carga DESC, organizacion;

SELECT COUNT(*) AS total_organizaciones_importadas
FROM estadisticas.OrganizacionesDistinguidas;
GO

-- ==============================================================
-- CASO 2 - Reimportación del mismo archivo
-- Se espera: registros_insertados = 0, registros_actualizados = 0
-- La tabla destino no debe crecer
-- ==============================================================

PRINT '==============================================================';
PRINT ' CASO 2 - Reimportación del mismo archivo (no debe duplicar)';
PRINT '==============================================================';

DECLARE @v_total_antes INT = (SELECT COUNT(*) FROM estadisticas.OrganizacionesDistinguidas);

EXEC importaciones.ImportarOrganizacionesDistinguidas
    @p_ruta_archivo = 'registro-organizaciones-distinguidas.csv';

DECLARE @v_total_despues INT = (SELECT COUNT(*) FROM estadisticas.OrganizacionesDistinguidas);

SELECT
    @v_total_antes   AS filas_antes,
    @v_total_despues AS filas_despues,
    CASE WHEN @v_total_antes = @v_total_despues
         THEN 'OK - sin duplicados'
         ELSE 'ERROR - se generaron duplicados'
    END AS resultado;
GO

-- ==============================================================
-- CASO 3 - Archivo con errores variados
-- Se espera:
--   registros_insertados  = 1 (Hotel Las Piedras, segunda ocurrencia)
--   registros_rechazados  = 4 (duplicado + org vacía + rubro vacío
--                              + fecha de distinción inválida)
-- ==============================================================

PRINT '==============================================================';
PRINT ' CASO 3 - Organización vacía, rubro vacío, fecha inválida';
PRINT '          y duplicado dentro del archivo';
PRINT '==============================================================';

EXEC importaciones.ImportarOrganizacionesDistinguidas
    @p_ruta_archivo = 'casos_error_org.csv';

-- Fila válida que debió insertarse
SELECT TOP 5
    organizacion,
    rubro,
    provincia,
    ciudad,
    fecha_distincion
FROM estadisticas.OrganizacionesDistinguidas
WHERE organizacion = 'Hotel Las Piedras';

-- Filas rechazadas para este archivo
SELECT TOP 10
    id_error,
    fecha_error,
    motivo_error,
    indice_tiempo_valor   AS organizacion_valor,
    region_destino_valor  AS rubro_valor
FROM estadisticas.ErroresImportacion
WHERE archivo_origen LIKE '%casos_error_org%'
ORDER BY id_error;
GO

-- ==============================================================
-- CASO 4 - Reimportación del archivo de errores
-- Se espera: registros_insertados = 0, registros_actualizados = 0
-- Hotel Las Piedras ya existe y no cambió: no debe actualizarse
-- ==============================================================

PRINT '==============================================================';
PRINT ' CASO 4 - Reimportación del archivo de errores';
PRINT '          (sin cambios en la tabla destino)';
PRINT '==============================================================';

EXEC importaciones.ImportarOrganizacionesDistinguidas
    @p_ruta_archivo = 'casos_error_org.csv';

SELECT TOP 5
    organizacion,
    rubro,
    provincia,
    fecha_carga,
    fecha_actualizacion
FROM estadisticas.OrganizacionesDistinguidas
WHERE organizacion = 'Hotel Las Piedras';
GO

-- ==============================================================
-- CASO 5 - Archivo inexistente
-- Se espera: error controlado con mensaje descriptivo
-- ==============================================================

PRINT '==============================================================';
PRINT ' CASO 5 - Archivo inexistente';
PRINT '==============================================================';

BEGIN TRY
    EXEC importaciones.ImportarOrganizacionesDistinguidas
        @p_ruta_archivo = 'no_existe.csv';
END TRY
BEGIN CATCH
    PRINT 'OK - Error esperado capturado: ' + ERROR_MESSAGE();
END CATCH
GO
