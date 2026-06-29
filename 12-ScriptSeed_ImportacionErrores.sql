/*
==============================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Fecha:       29/06/2026
Descripción: Caso obligatorio 4 — Importación con errores parciales.

             Ejecuta importaciones.ImportarEstadisticasVisitantes
             sobre el archivo 'seed_visitantes_errores.csv', que
             contiene filas válidas e inválidas mezcladas. La
             importación debe cargar las válidas y registrar las
             inválidas en estadisticas.ErroresImportacion sin
             detener la carga.

             REQUISITO PREVIO (igual que las demás importaciones):
             copiar el archivo 'seed_visitantes_errores.csv'
             (provisto en el repositorio) a la carpeta
             C:\Importaciones\ , accesible por el servicio de
             SQL Server.

             Filas del archivo:
               Válidas   (4): se insertan/actualizan.
               Inválidas (5): fecha inválida, visitas negativas,
                              visitas no numéricas, región vacía y
                              una clave duplicada dentro del archivo.
==============================================================
*/

USE ParquesNacionalesDB;
GO

DECLARE @archivo VARCHAR(500) = 'seed_visitantes_errores.csv';
DECLARE @ruta    VARCHAR(1000) = 'C:\Importaciones\' + @archivo;
DECLARE @existe  INT = 0;

EXEC master.dbo.xp_fileexist @ruta, @existe OUTPUT;

IF @existe = 0
BEGIN
    PRINT '===========================================================';
    PRINT ' ATENCIÓN: no se encontró ' + @ruta;
    PRINT ' Copie el archivo seed_visitantes_errores.csv del';
    PRINT ' repositorio a C:\Importaciones\ y vuelva a ejecutar.';
    PRINT '===========================================================';
    RETURN;
END

PRINT '===========================================================';
PRINT ' Importando seed_visitantes_errores.csv (con errores parciales)';
PRINT '===========================================================';

-- La importación devuelve: insertados, actualizados, rechazados
EXEC importaciones.ImportarEstadisticasVisitantes @p_ruta_archivo = 'seed_visitantes_errores.csv';
GO

PRINT '--- Filas rechazadas registradas en estadisticas.ErroresImportacion ---';
GO
SELECT TOP 20
       fecha_error,
       motivo_error,
       indice_tiempo_valor,
       region_destino_valor,
       origen_visitantes_valor,
       visitas_valor
FROM estadisticas.ErroresImportacion
WHERE archivo_origen LIKE '%seed_visitantes_errores.csv'
ORDER BY id_error DESC;
GO

PRINT '--- Filas válidas cargadas en estadisticas.VisitantesParques ---';
GO
SELECT indice_tiempo, region_destino, origen_visitantes, visitas, observaciones
FROM estadisticas.VisitantesParques
WHERE region_destino IN ('Patagonia', 'Litoral', 'Cuyo')
ORDER BY indice_tiempo, region_destino, origen_visitantes;
GO
