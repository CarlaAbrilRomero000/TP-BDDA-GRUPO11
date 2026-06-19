/*
==============================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Fecha:       13/06/2026
Descripción: Entrega 6 - Carga histórica de estadísticas de
             visitantes a Parques Nacionales desde un archivo
             CSV externo (indice_tiempo, region_de_destino,
             origen_visitantes, visitas, observaciones).

             Contenido:
             - importaciones.ImportarEstadisticasVisitantes
                 Procedimiento que realiza toda la carga,
                 validación y upsert (sin MERGE).

             Nota: Los schemas 'estadisticas' e 'importaciones',
             las tablas estadisticas.VisitantesParques y
             estadisticas.ErroresImportacion se crean en
             01-ScriptCreacionTablasYSchemas.sql.

             Clave de unicidad / upsert:
                 indice_tiempo + region_destino + origen_visitantes
==============================================================
*/

USE ParquesNacionalesDB;
GO

-- ==============================================================
-- importaciones.ImportarEstadisticasVisitantes
--
-- Importa el archivo CSV indicado en @p_ruta_archivo:
--   1. Valida que el archivo exista.
--   2. Vacía la tabla de staging y carga el CSV con BULK INSERT
--      (se usa SQL dinámico únicamente para esta sentencia,
--       porque BULK INSERT no admite una variable en FROM).
--   3. Valida cada fila (fecha, región, origen, visitas) y
--      detecta duplicados dentro del propio archivo.
--   4. Las filas inválidas se registran en
--      estadisticas.ErroresImportacion (no detienen la carga
--      del resto del archivo).
--   5. Aplica upsert sin MERGE sobre estadisticas.VisitantesParques
--      usando la clave (indice_tiempo, region_destino,
--      origen_visitantes): inserta claves nuevas y actualiza
--      visitas/observaciones cuando cambiaron. Nunca elimina
--      filas existentes (se preserva el historial).
--   6. Vacía la tabla de staging al finalizar (incluso si hubo
--      error).
--   7. Devuelve un registro con la cantidad de filas
--      insertadas, actualizadas y rechazadas.
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('importaciones.ImportarEstadisticasVisitantes') AND type = 'P')
    PRINT 'Creando Procedure importaciones.ImportarEstadisticasVisitantes...';
ELSE
    PRINT 'OK - Procedure importaciones.ImportarEstadisticasVisitantes ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE importaciones.ImportarEstadisticasVisitantes
    @p_ruta_archivo VARCHAR(500)   -- nombre del archivo (ej.: 'estadisticas_visitantes.csv')
AS
BEGIN
    SET NOCOUNT ON;
    SET DATEFORMAT ymd;

    DECLARE @v_ruta_base     VARCHAR(500)  = 'C:\Importaciones\';
    DECLARE @v_ruta_completa VARCHAR(1000) = @v_ruta_base + @p_ruta_archivo;
    DECLARE @v_existe_archivo INT          = 0;
    DECLARE @v_sql            NVARCHAR(MAX);
    DECLARE @v_insertados     INT          = 0;
    DECLARE @v_actualizados   INT          = 0;
    DECLARE @v_rechazados     INT          = 0;

    BEGIN TRY
        ----------------------------------------------------------
        -- 1) Validar existencia del archivo
        ----------------------------------------------------------
        EXEC master.dbo.xp_fileexist @v_ruta_completa, @v_existe_archivo OUTPUT;

        IF @v_existe_archivo IS NULL OR @v_existe_archivo = 0
            THROW 50000, 'El archivo especificado no existe o no es accesible desde el motor de SQL Server.', 1;

        ----------------------------------------------------------
        -- 2) Crear tabla temporal de staging y cargar el CSV.
        --    FORMAT='CSV' (necesario para campos entre comillas)
        --    es incompatible con lista de columnas e incompatible
        --    con IDENTITY en la tabla destino. Por eso la tabla
        --    se crea solo con las 5 columnas raw (mapeo 1-a-1 con
        --    el CSV) y las demás columnas se agregan con ALTER
        --    TABLE, evitando así una segunda tabla temporal.
        ----------------------------------------------------------
        IF OBJECT_ID('tempdb..#StagingVisitantes') IS NOT NULL DROP TABLE #StagingVisitantes;

        CREATE TABLE #StagingVisitantes (
            indice_tiempo_raw     VARCHAR(30)   NULL,
            region_destino_raw    VARCHAR(200)  NULL,
            origen_visitantes_raw VARCHAR(100)  NULL,
            visitas_raw           VARCHAR(50)   NULL,
            observaciones_raw     VARCHAR(MAX)  NULL
        );

        SET @v_sql = N'
            BULK INSERT #StagingVisitantes
            FROM ''' + REPLACE(@v_ruta_completa, '''', '''''') + N'''
            WITH (
                FORMAT          = ''CSV'',
                FIELDQUOTE      = ''"'',
                FIELDTERMINATOR = '','',
                ROWTERMINATOR   = ''0x0a'',
                FIRSTROW        = 2,
                CODEPAGE        = ''65001'',
                MAXERRORS       = 2147483647
            );';

        EXEC sp_executesql @v_sql;

        ALTER TABLE #StagingVisitantes
            ADD row_num           INT           NULL,
                indice_tiempo     DATE          NULL,
                region_destino    VARCHAR(100)  NULL,
                origen_visitantes VARCHAR(50)   NULL,
                visitas           INT           NULL,
                observaciones     VARCHAR(500)  NULL,
                motivo_error      VARCHAR(500)  NULL;

        ----------------------------------------------------------
        -- 3) Poblar columnas de validación
        ----------------------------------------------------------

        -- Asignar número de fila (usado para dedup: conservar la última ocurrencia)
        ;WITH Num AS (
            SELECT row_num, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
            FROM #StagingVisitantes
        )
        UPDATE Num SET row_num = rn;

        -- Parsear columnas tipadas (una sola vez cada TRY_CAST)
        UPDATE #StagingVisitantes
        SET
            indice_tiempo     = TRY_CAST(LTRIM(RTRIM(indice_tiempo_raw)) AS DATE),
            region_destino    = NULLIF(LTRIM(RTRIM(region_destino_raw)), ''),
            origen_visitantes = NULLIF(LTRIM(RTRIM(origen_visitantes_raw)), ''),
            visitas           = TRY_CAST(LTRIM(RTRIM(visitas_raw)) AS INT),
            observaciones     = NULLIF(LTRIM(RTRIM(observaciones_raw)), '');

        -- Validar usando las columnas ya computadas (sin repetir conversiones)
        UPDATE #StagingVisitantes
        SET motivo_error = CASE
                WHEN LTRIM(RTRIM(ISNULL(indice_tiempo_raw, ''))) = ''
                 AND LTRIM(RTRIM(ISNULL(region_destino_raw, ''))) = ''
                 AND LTRIM(RTRIM(ISNULL(origen_visitantes_raw, ''))) = ''
                 AND LTRIM(RTRIM(ISNULL(visitas_raw, ''))) = ''
                    THEN N'Fila vacía o con columnas faltantes.'
                WHEN indice_tiempo IS NULL
                    THEN N'La fecha (indice_tiempo) es inválida o está vacía.'
                WHEN region_destino IS NULL
                    THEN N'La región de destino es nula o vacía.'
                WHEN origen_visitantes IS NULL
                    THEN N'El origen de visitantes es nulo o vacío.'
                WHEN visitas IS NULL
                    THEN N'La cantidad de visitas es nula, vacía o no es un valor numérico válido.'
                WHEN visitas < 0
                    THEN N'La cantidad de visitas no puede ser negativa.'
                ELSE NULL
            END;

        -- Marcar duplicados dentro del archivo: conservar la última ocurrencia
        ;WITH Duplicados AS (
            SELECT row_num,
                   ROW_NUMBER() OVER (
                       PARTITION BY indice_tiempo, region_destino, origen_visitantes
                       ORDER BY row_num DESC
                   ) AS orden
            FROM #StagingVisitantes
            WHERE motivo_error IS NULL
        )
        UPDATE s
        SET s.motivo_error = N'Registro duplicado dentro del archivo (se conserva la última ocurrencia con esa clave).'
        FROM #StagingVisitantes s
        INNER JOIN Duplicados d ON d.row_num = s.row_num
        WHERE d.orden > 1;

        ----------------------------------------------------------
        -- 4) Registrar filas rechazadas
        ----------------------------------------------------------
        INSERT INTO estadisticas.ErroresImportacion
            (archivo_origen, motivo_error, indice_tiempo_valor, region_destino_valor,
             origen_visitantes_valor, visitas_valor, observaciones_valor)
        SELECT
            @v_ruta_completa,
            motivo_error,
            indice_tiempo_raw,
            region_destino_raw,
            origen_visitantes_raw,
            visitas_raw,
            observaciones_raw
        FROM #StagingVisitantes
        WHERE motivo_error IS NOT NULL;

        SET @v_rechazados = @@ROWCOUNT;

        ----------------------------------------------------------
        -- 5) Upsert sin MERGE sobre estadisticas.VisitantesParques
        ----------------------------------------------------------
        BEGIN TRANSACTION;

        -- 5a) Actualizar registros existentes cuyos datos cambiaron
        UPDATE dest
        SET dest.visitas            = s.visitas,
            dest.observaciones      = s.observaciones,
            dest.fecha_actualizacion = SYSDATETIME()
        FROM estadisticas.VisitantesParques dest
        INNER JOIN #StagingVisitantes s
            ON s.indice_tiempo     = dest.indice_tiempo
           AND s.region_destino    = dest.region_destino
           AND s.origen_visitantes = dest.origen_visitantes
        WHERE s.motivo_error IS NULL
          AND (
                dest.visitas <> s.visitas
             OR ISNULL(dest.observaciones, N'') <> ISNULL(s.observaciones, N'')
              );

        SET @v_actualizados = @@ROWCOUNT;

        -- 5b) Insertar claves nuevas
        INSERT INTO estadisticas.VisitantesParques
            (indice_tiempo, region_destino, origen_visitantes, visitas, observaciones)
        SELECT s.indice_tiempo, s.region_destino, s.origen_visitantes, s.visitas, s.observaciones
        FROM #StagingVisitantes s
        WHERE s.motivo_error IS NULL
          AND NOT EXISTS (
              SELECT 1 FROM estadisticas.VisitantesParques dest
              WHERE dest.indice_tiempo     = s.indice_tiempo
                AND dest.region_destino    = s.region_destino
                AND dest.origen_visitantes = s.origen_visitantes
          );

        SET @v_insertados = @@ROWCOUNT;

        COMMIT TRANSACTION;

        ----------------------------------------------------------
        -- 6) Limpieza y resultado
        ----------------------------------------------------------
        DROP TABLE #StagingVisitantes;

        SELECT
            @v_insertados   AS registros_insertados,
            @v_actualizados AS registros_actualizados,
            @v_rechazados   AS registros_rechazados;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        IF OBJECT_ID('tempdb..#StagingVisitantes') IS NOT NULL DROP TABLE #StagingVisitantes;
        THROW;
    END CATCH
END
GO
