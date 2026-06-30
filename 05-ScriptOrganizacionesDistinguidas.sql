/*
==============================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Fecha:       13/06/2026
Descripción: Entrega 6 - Carga de organizaciones distinguidas
             desde un archivo CSV externo
             (registro-organizaciones-distinguidas.csv).

             Contenido:
             - importaciones.ImportarOrganizacionesDistinguidas
                 Procedimiento que realiza toda la carga,
                 validación y upsert (sin MERGE).

             Nota: La tabla estadisticas.OrganizacionesDistinguidas,
             sus índices y estadisticas.ErroresImportacion se crean
             en 00-ScriptCreacionTablasYSchemas.sql.

             Clave de unicidad / upsert:
                 organizacion + calle + numero
==============================================================
*/

USE ParquesNacionalesDB;
GO

-- ==============================================================
-- importaciones.ImportarOrganizacionesDistinguidas
--
-- Importa el CSV indicado en @p_ruta_archivo:
--   1. Valida que el archivo exista.
--   2. Crea la tabla temporal #StagingOrganizaciones con las 14
--      columnas raw y carga el CSV con BULK INSERT (SQL dinámico
--      porque BULK INSERT no admite variables en FROM).
--   3. Agrega columnas tipadas + motivo_error con ALTER TABLE.
--   4. Parsea columnas tipadas (un solo NULLIF/TRY_CAST por col).
--   5. Valida usando las columnas ya computadas y detecta
--      duplicados dentro del archivo.
--   6. Filas inválidas -> estadisticas.ErroresImportacion.
--   7. Upsert sin MERGE sobre OrganizacionesDistinguidas
--      (clave: organizacion + calle + numero):
--      inserta filas nuevas y actualiza datos cuando cambiaron.
--      Nunca elimina filas.
--   8. Devuelve registros_insertados, actualizados y rechazados.
-- ==============================================================

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('importaciones.ImportarOrganizacionesDistinguidas') AND type = 'P')
    PRINT 'Creando Procedure importaciones.ImportarOrganizacionesDistinguidas...';
ELSE
    PRINT 'OK - Procedure importaciones.ImportarOrganizacionesDistinguidas ya existe, se omite creación.';
GO

CREATE OR ALTER PROCEDURE importaciones.ImportarOrganizacionesDistinguidas
    @p_ruta_archivo VARCHAR(500)   -- nombre del archivo (ej.: 'registro-organizaciones-distinguidas.csv')
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
        --    Solo columnas raw (mapeo 1-a-1 con el CSV); las
        --    columnas tipadas y motivo_error se agregan luego
        --    con ALTER TABLE, siguiendo el mismo patrón que
        --    ImportarEstadisticasVisitantes.
        ----------------------------------------------------------
        IF OBJECT_ID('tempdb..#StagingOrganizaciones') IS NOT NULL DROP TABLE #StagingOrganizaciones;

        CREATE TABLE #StagingOrganizaciones (
            organizacion_raw       VARCHAR(300) NULL,
            rubro_raw              VARCHAR(200) NULL,
            subrubro_raw           VARCHAR(200) NULL,
            calle_raw              VARCHAR(300) NULL,
            numero_raw             VARCHAR(100) NULL,
            pais_raw               VARCHAR(200) NULL,
            provincia_raw          VARCHAR(200) NULL,
            ciudad_raw             VARCHAR(200) NULL,
            telefono_raw           VARCHAR(200) NULL,
            facebook_raw           VARCHAR(300) NULL,
            web_raw                VARCHAR(300) NULL,
            programa_raw           VARCHAR(300) NULL,
            fecha_distincion_raw   VARCHAR(50)  NULL,
            fecha_revalidacion_raw VARCHAR(50)  NULL
        );

        SET @v_sql = N'
            BULK INSERT #StagingOrganizaciones
            FROM ''' + REPLACE(@v_ruta_completa, '''', '''''') + N'''
            WITH (
                FIELDTERMINATOR = '','',
                ROWTERMINATOR   = ''0x0a'',
                FIRSTROW        = 2,
                CODEPAGE        = ''65001'',
                MAXERRORS       = 2147483647
            );';

        EXEC sp_executesql @v_sql;

        ALTER TABLE #StagingOrganizaciones
            ADD row_num            INT           NULL,
                organizacion       VARCHAR(200)  NULL,
                rubro              VARCHAR(100)  NULL,
                subrubro           VARCHAR(100)  NULL,
                calle              VARCHAR(200)  NULL,
                numero             VARCHAR(50)   NULL,
                pais               VARCHAR(100)  NULL,
                provincia          VARCHAR(100)  NULL,
                ciudad             VARCHAR(100)  NULL,
                telefono           VARCHAR(100)  NULL,
                facebook           VARCHAR(200)  NULL,
                web                VARCHAR(200)  NULL,
                programa           VARCHAR(200)  NULL,
                fecha_distincion   DATE          NULL,
                fecha_revalidacion DATE          NULL,
                motivo_error       VARCHAR(500)  NULL;

        ----------------------------------------------------------
        -- 3) Poblar columnas de validación
        ----------------------------------------------------------

        -- Asignar número de fila
        ;WITH Num AS (
            SELECT row_num, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
            FROM #StagingOrganizaciones
        )
        UPDATE Num SET row_num = rn;

        -- Parsear columnas tipadas (una sola vez cada conversión)
        UPDATE #StagingOrganizaciones
        SET
            organizacion       = NULLIF(LTRIM(RTRIM(organizacion_raw)), ''),
            rubro              = NULLIF(LTRIM(RTRIM(rubro_raw)), ''),
            subrubro           = NULLIF(LTRIM(RTRIM(subrubro_raw)), ''),
            calle              = NULLIF(LTRIM(RTRIM(calle_raw)), ''),
            numero             = NULLIF(LTRIM(RTRIM(numero_raw)), ''),
            pais               = NULLIF(LTRIM(RTRIM(pais_raw)), ''),
            provincia          = NULLIF(LTRIM(RTRIM(provincia_raw)), ''),
            ciudad             = NULLIF(LTRIM(RTRIM(ciudad_raw)), ''),
            telefono           = NULLIF(LTRIM(RTRIM(telefono_raw)), ''),
            facebook           = NULLIF(LTRIM(RTRIM(facebook_raw)), ''),
            web                = NULLIF(LTRIM(RTRIM(web_raw)), ''),
            programa           = NULLIF(LTRIM(RTRIM(programa_raw)), ''),
            fecha_distincion   = TRY_CAST(LTRIM(RTRIM(REPLACE(fecha_distincion_raw,   CHAR(13), ''))) AS DATE),
            fecha_revalidacion = TRY_CAST(LTRIM(RTRIM(REPLACE(fecha_revalidacion_raw, CHAR(13), ''))) AS DATE);

        -- Validar usando las columnas ya computadas (sin repetir conversiones)
        UPDATE #StagingOrganizaciones
        SET motivo_error = CASE
                WHEN organizacion IS NULL
                    THEN N'El nombre de la organización es nulo o vacío.'
                WHEN rubro IS NULL
                    THEN N'El rubro es nulo o vacío.'
                WHEN LTRIM(RTRIM(REPLACE(ISNULL(fecha_distincion_raw, ''), CHAR(13), ''))) <> ''
                 AND fecha_distincion IS NULL
                    THEN N'La fecha de distinción es inválida.'
                WHEN LTRIM(RTRIM(REPLACE(ISNULL(fecha_revalidacion_raw, ''), CHAR(13), ''))) <> ''
                 AND fecha_revalidacion IS NULL
                    THEN N'La fecha de revalidación es inválida.'
                ELSE NULL
            END;

        -- Marcar duplicados dentro del archivo: conservar la última ocurrencia
        ;WITH Duplicados AS (
            SELECT row_num,
                   ROW_NUMBER() OVER (
                       PARTITION BY organizacion, calle, numero
                       ORDER BY row_num DESC
                   ) AS orden
            FROM #StagingOrganizaciones
            WHERE motivo_error IS NULL
        )
        UPDATE s
        SET s.motivo_error = N'Registro duplicado dentro del archivo (se conserva la última ocurrencia con esa clave).'
        FROM #StagingOrganizaciones s
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
            s.motivo_error,
            s.organizacion_raw,
            s.rubro_raw,
            s.calle_raw,
            s.numero_raw,
            s.fecha_distincion_raw
        FROM #StagingOrganizaciones s
        WHERE s.motivo_error IS NOT NULL;

        SET @v_rechazados = @@ROWCOUNT;

        ----------------------------------------------------------
        -- 5) Upsert sin MERGE sobre OrganizacionesDistinguidas
        ----------------------------------------------------------
        BEGIN TRANSACTION;

        -- 5a) Actualizar registros existentes cuyos datos cambiaron
        UPDATE dest
        SET dest.rubro               = s.rubro,
            dest.subrubro            = s.subrubro,
            dest.pais                = s.pais,
            dest.provincia           = s.provincia,
            dest.ciudad              = s.ciudad,
            dest.telefono            = s.telefono,
            dest.facebook            = s.facebook,
            dest.web                 = s.web,
            dest.programa            = s.programa,
            dest.fecha_distincion    = s.fecha_distincion,
            dest.fecha_revalidacion  = s.fecha_revalidacion,
            dest.fecha_actualizacion = SYSDATETIME()
        FROM estadisticas.OrganizacionesDistinguidas dest
        INNER JOIN #StagingOrganizaciones s
            ON  s.organizacion       = dest.organizacion
           AND ISNULL(s.calle, '')   = ISNULL(dest.calle, '')
           AND ISNULL(s.numero, '')  = ISNULL(dest.numero, '')
        WHERE s.motivo_error IS NULL
          AND (
                ISNULL(dest.rubro, '')     <> ISNULL(s.rubro, '')
             OR ISNULL(dest.subrubro, '')  <> ISNULL(s.subrubro, '')
             OR ISNULL(dest.pais, '')      <> ISNULL(s.pais, '')
             OR ISNULL(dest.provincia, '') <> ISNULL(s.provincia, '')
             OR ISNULL(dest.ciudad, '')    <> ISNULL(s.ciudad, '')
             OR ISNULL(dest.telefono, '')  <> ISNULL(s.telefono, '')
             OR ISNULL(dest.facebook, '')  <> ISNULL(s.facebook, '')
             OR ISNULL(dest.web, '')       <> ISNULL(s.web, '')
             OR ISNULL(dest.programa, '')  <> ISNULL(s.programa, '')
             OR ISNULL(CAST(dest.fecha_distincion   AS VARCHAR(20)), '')
                <> ISNULL(CAST(s.fecha_distincion   AS VARCHAR(20)), '')
             OR ISNULL(CAST(dest.fecha_revalidacion AS VARCHAR(20)), '')
                <> ISNULL(CAST(s.fecha_revalidacion AS VARCHAR(20)), '')
              );

        SET @v_actualizados = @@ROWCOUNT;

        -- 5b) Insertar organizaciones nuevas
        INSERT INTO estadisticas.OrganizacionesDistinguidas
            (organizacion, rubro, subrubro, calle, numero, pais, provincia, ciudad,
             telefono, facebook, web, programa, fecha_distincion, fecha_revalidacion)
        SELECT
            s.organizacion, s.rubro, s.subrubro, s.calle, s.numero, s.pais,
            s.provincia, s.ciudad, s.telefono, s.facebook, s.web, s.programa,
            s.fecha_distincion, s.fecha_revalidacion
        FROM #StagingOrganizaciones s
        WHERE s.motivo_error IS NULL
          AND NOT EXISTS (
              SELECT 1 FROM estadisticas.OrganizacionesDistinguidas dest
              WHERE dest.organizacion      = s.organizacion
                AND ISNULL(dest.calle, '')  = ISNULL(s.calle, '')
                AND ISNULL(dest.numero, '') = ISNULL(s.numero, '')
          );

        SET @v_insertados = @@ROWCOUNT;

        COMMIT TRANSACTION;

        ----------------------------------------------------------
        -- 6) Limpieza y resultado
        ----------------------------------------------------------
        DROP TABLE #StagingOrganizaciones;

        SELECT
            @v_insertados   AS registros_insertados,
            @v_actualizados AS registros_actualizados,
            @v_rechazados   AS registros_rechazados;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        IF OBJECT_ID('tempdb..#StagingOrganizaciones') IS NOT NULL DROP TABLE #StagingOrganizaciones;
        THROW;
    END CATCH
END
GO
