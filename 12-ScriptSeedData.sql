/*
==============================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Fecha:       29/06/2026
Descripción: Script de carga (SEED DATA) del juego de datos
             exigido por los Criterios de Aceptación.

             Genera (vía stored procedures, sin tocar tablas
             directamente):
               - 10 parques
               - 20 guardaparques
               - 20 guías
               - 30 actividades/tours
               - 10 concesiones (vigentes y vencidas)
               - Historial de ventas de entradas

             Casos obligatorios representados:
               1. Un parque con múltiples actividades simultáneas
                  (parque SEED-PN01 con varios tours vendidos en
                  la misma fecha de acceso).
               2. Un tour con cupo completo (Tour Demo Cupo
                  Completo: ventas que igualan su cupo_maximo).
               3. Concesión vigente y vencida.
               (4. Importación con errores parciales -> ver
                   13-ScriptSeed_ImportacionErrores.sql)

             Se ejecuta DESPUÉS de los scripts 01–11. Es
             idempotente: si ya fue sembrado (existe el parque
             centinela SEED-PN01) no vuelve a cargar.

             Nota T-SQL: EXEC no admite expresiones como
             argumentos; por eso cada valor se calcula primero
             en una variable y luego se pasa al SP.
==============================================================
*/

USE ParquesNacionalesDB;
GO

SET NOCOUNT ON;

-- ==============================================================
-- Guarda de idempotencia
-- ==============================================================
IF EXISTS (SELECT 1 FROM parques.Parque WHERE codigo_oficial = 'SEED-PN01')
BEGIN
    PRINT 'OK - El juego de datos ya fue sembrado (existe SEED-PN01). No se vuelve a cargar.';
    RETURN;
END

PRINT '===========================================================';
PRINT ' Sembrando juego de datos...';
PRINT '===========================================================';

DECLARE @i INT;
DECLARE @id INT, @id_parque INT, @id_guia INT, @id_tour INT, @id_empresa INT;
DECLARE @cupo INT, @costo DECIMAL(12,2), @precio DECIMAL(12,2);
DECLARE @id_tv_res INT, @id_tv_nores INT, @id_fp_efectivo INT, @id_tp_nacional INT;
DECLARE @total DECIMAL(12,2), @cant INT, @sub DECIMAL(12,2);
DECLARE @det ventas.tt_DetalleVenta;

-- Variables de trabajo para los parámetros de los SP
DECLARE @v_codigo VARCHAR(50), @v_nombre VARCHAR(100), @v_ubic VARCHAR(255), @v_superf DECIMAL(12,2);
DECLARE @v_dni VARCHAR(20), @v_email VARCHAR(100), @v_tel VARCHAR(50);
DECLARE @v_apellido VARCHAR(50), @v_nombre_p VARCHAR(50);
DECLARE @v_cuit CHAR(11), @v_razon VARCHAR(150), @v_dir VARCHAR(255);
DECLARE @v_tnombre VARCHAR(100), @v_dur INT, @v_id_ta INT, @v_parque_seq INT;
DECLARE @v_actividad VARCHAR(100), @v_canon DECIMAL(12,2), @v_fini DATE, @v_ffin DATE;
DECLARE @v_num VARCHAR(50), @v_fventa DATETIME2, @v_facc DATE;

-- Pools de nombres para datos más realistas
DECLARE @nombres TABLE (rn INT IDENTITY(1,1), val VARCHAR(50));
INSERT INTO @nombres (val) VALUES
 ('Juan'),('María'),('Carlos'),('Lucía'),('Pedro'),
 ('Ana'),('Diego'),('Sofía'),('Martín'),('Valentina');

DECLARE @apellidos TABLE (rn INT IDENTITY(1,1), val VARCHAR(50));
INSERT INTO @apellidos (val) VALUES
 ('Gómez'),('Pérez'),('Rodríguez'),('Fernández'),('López'),
 ('Díaz'),('Martínez'),('Romero'),('Sosa'),('Torres');

-- ==============================================================
-- 1. TABLAS MAESTRAS (solo si no existen)
-- ==============================================================
PRINT 'Cargando tablas maestras...';

IF NOT EXISTS (SELECT 1 FROM parques.TipoParque WHERE descripcion = 'Nacional')           EXEC parques.TipoParqueInsertar 'Nacional';
IF NOT EXISTS (SELECT 1 FROM parques.TipoParque WHERE descripcion = 'Provincial')          EXEC parques.TipoParqueInsertar 'Provincial';
IF NOT EXISTS (SELECT 1 FROM parques.TipoParque WHERE descripcion = 'Reserva Natural')      EXEC parques.TipoParqueInsertar 'Reserva Natural';
IF NOT EXISTS (SELECT 1 FROM parques.TipoParque WHERE descripcion = 'Monumento Natural')    EXEC parques.TipoParqueInsertar 'Monumento Natural';
IF NOT EXISTS (SELECT 1 FROM parques.TipoParque WHERE descripcion = 'Parque Marino')        EXEC parques.TipoParqueInsertar 'Parque Marino';

IF NOT EXISTS (SELECT 1 FROM turismo.TipoAtraccion WHERE descripcion = 'Senderismo')        EXEC turismo.TipoAtraccionInsertar 'Senderismo';
IF NOT EXISTS (SELECT 1 FROM turismo.TipoAtraccion WHERE descripcion = 'Avistaje de aves')  EXEC turismo.TipoAtraccionInsertar 'Avistaje de aves';
IF NOT EXISTS (SELECT 1 FROM turismo.TipoAtraccion WHERE descripcion = 'Navegación')        EXEC turismo.TipoAtraccionInsertar 'Navegación';
IF NOT EXISTS (SELECT 1 FROM turismo.TipoAtraccion WHERE descripcion = 'Cabalgata')         EXEC turismo.TipoAtraccionInsertar 'Cabalgata';
IF NOT EXISTS (SELECT 1 FROM turismo.TipoAtraccion WHERE descripcion = 'Escalada')          EXEC turismo.TipoAtraccionInsertar 'Escalada';
IF NOT EXISTS (SELECT 1 FROM turismo.TipoAtraccion WHERE descripcion = 'Visita guiada')     EXEC turismo.TipoAtraccionInsertar 'Visita guiada';
IF NOT EXISTS (SELECT 1 FROM turismo.TipoAtraccion WHERE descripcion = 'Camping')           EXEC turismo.TipoAtraccionInsertar 'Camping';
IF NOT EXISTS (SELECT 1 FROM turismo.TipoAtraccion WHERE descripcion = 'Buceo')             EXEC turismo.TipoAtraccionInsertar 'Buceo';

IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE descripcion = 'Residente')          EXEC ventas.TipoVisitanteInsertar 'Residente';
IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE descripcion = 'No residente')       EXEC ventas.TipoVisitanteInsertar 'No residente';
IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE descripcion = 'Jubilado')           EXEC ventas.TipoVisitanteInsertar 'Jubilado';
IF NOT EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE descripcion = 'Menor')              EXEC ventas.TipoVisitanteInsertar 'Menor';

IF NOT EXISTS (SELECT 1 FROM ventas.FormaPago WHERE descripcion = 'Efectivo')               EXEC ventas.FormaPagoInsertar 'Efectivo';
IF NOT EXISTS (SELECT 1 FROM ventas.FormaPago WHERE descripcion = 'Débito')                 EXEC ventas.FormaPagoInsertar 'Débito';
IF NOT EXISTS (SELECT 1 FROM ventas.FormaPago WHERE descripcion = 'Crédito')                EXEC ventas.FormaPagoInsertar 'Crédito';

SELECT @id_tp_nacional = id_tipo_parque    FROM parques.TipoParque   WHERE descripcion = 'Nacional';
SELECT @id_tv_res      = id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Residente';
SELECT @id_tv_nores    = id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'No residente';
SELECT @id_fp_efectivo = id_forma_pago     FROM ventas.FormaPago     WHERE descripcion = 'Efectivo';

-- Tipos de atracción disponibles (para repartir entre los tours)
DECLARE @ta TABLE (rn INT IDENTITY(1,1), id INT);
INSERT INTO @ta (id) SELECT id_tipo_atraccion FROM turismo.TipoAtraccion ORDER BY id_tipo_atraccion;
DECLARE @ta_count INT = (SELECT COUNT(*) FROM @ta);

-- ==============================================================
-- 2. EMPRESAS (6) -> #empresas
-- ==============================================================
PRINT 'Cargando empresas...';
CREATE TABLE #empresas (seq INT, id INT);
SET @i = 1;
WHILE @i <= 6
BEGIN
    SET @v_cuit  = '307000000' + RIGHT('0' + CAST(@i AS VARCHAR(2)), 2);
    SET @v_razon = CONCAT('Concesionaria del Sur ', @i, ' S.A.');
    SET @v_dir   = CONCAT('Av. Principal ', @i * 100);
    EXEC comercial.EmpresaInsertar
        @p_cuit         = @v_cuit,
        @p_razon_social = @v_razon,
        @p_email        = NULL,
        @p_telefono     = NULL,
        @p_direccion    = @v_dir;
    INSERT INTO #empresas (seq, id) VALUES (@i, CAST(IDENT_CURRENT('comercial.Empresa') AS INT));
    SET @i += 1;
END

-- ==============================================================
-- 3. PARQUES (10) -> #parques
-- ==============================================================
PRINT 'Cargando 10 parques...';
CREATE TABLE #parques (seq INT, id INT);
SET @i = 1;
WHILE @i <= 10
BEGIN
    SET @v_codigo = CONCAT('SEED-PN', RIGHT('0' + CAST(@i AS VARCHAR(2)), 2));
    SET @v_nombre = CONCAT('Parque Nacional Demo ', @i);
    SET @v_ubic   = CONCAT('Provincia Demo ', @i);
    SET @v_superf = 1000.50 + @i * 250;
    EXEC parques.ParqueInsertar
        @p_codigo_oficial = @v_codigo,
        @p_nombre         = @v_nombre,
        @p_ubicacion      = @v_ubic,
        @p_superficie     = @v_superf,
        @p_id_tipo_parque = @id_tp_nacional;
    INSERT INTO #parques (seq, id) VALUES (@i, CAST(IDENT_CURRENT('parques.Parque') AS INT));
    SET @i += 1;
END

-- ==============================================================
-- 4. GUARDAPARQUES (20) -> #guardaparques  (DNI se cifra en el SP)
-- ==============================================================
PRINT 'Cargando 20 guardaparques...';
CREATE TABLE #guardaparques (seq INT, id INT);
SET @i = 1;
WHILE @i <= 20
BEGIN
    SET @v_nombre_p = (SELECT val FROM @nombres   WHERE rn = ((@i - 1) % 10) + 1);
    SET @v_apellido = (SELECT val FROM @apellidos WHERE rn = ((@i * 3) % 10) + 1);
    SET @v_dni      = CAST(50000000 + @i AS VARCHAR(20));
    SET @v_email    = CONCAT('gp', @i, '@parques.gob.ar');
    SET @v_tel      = CONCAT('011-4000-', RIGHT('000' + CAST(@i AS VARCHAR(4)), 4));
    EXEC personal.GuardaparqueInsertar
        @p_nombre   = @v_nombre_p,
        @p_apellido = @v_apellido,
        @p_dni      = @v_dni,
        @p_email    = @v_email,
        @p_telefono = @v_tel;
    INSERT INTO #guardaparques (seq, id) VALUES (@i, CAST(IDENT_CURRENT('personal.Guardaparque') AS INT));
    SET @i += 1;
END

-- Asignar los primeros 10 guardaparques a un parque (historial)
SET @i = 1;
WHILE @i <= 10
BEGIN
    SELECT @id = id FROM #guardaparques WHERE seq = @i;
    SELECT @id_parque = id FROM #parques WHERE seq = @i;
    EXEC personal.HistorialGuardaparqueInsertar
        @p_id_guardaparque = @id,
        @p_id_parque       = @id_parque,
        @p_fecha_ingreso   = '2025-01-15';
    SET @i += 1;
END

-- ==============================================================
-- 5. GUÍAS (20) -> #guias  (DNI se cifra en el SP)
-- ==============================================================
PRINT 'Cargando 20 guías...';
CREATE TABLE #guias (seq INT, id INT);
SET @i = 1;
WHILE @i <= 20
BEGIN
    SET @v_nombre_p = (SELECT val FROM @nombres   WHERE rn = ((@i * 7) % 10) + 1);
    SET @v_apellido = (SELECT val FROM @apellidos WHERE rn = ((@i - 1) % 10) + 1);
    SET @v_dni      = CAST(51000000 + @i AS VARCHAR(20));
    EXEC turismo.GuiaInsertar
        @p_nombre                = @v_nombre_p,
        @p_apellido              = @v_apellido,
        @p_dni                   = @v_dni,
        @p_especialidad          = 'Turismo de naturaleza',
        @p_vigencia_autorizacion = '2028-12-31';
    INSERT INTO #guias (seq, id) VALUES (@i, CAST(IDENT_CURRENT('turismo.Guia') AS INT));
    SET @i += 1;
END

-- Habilitar cada guía en un parque: guía g -> parque ((g-1)%10)+1
SET @i = 1;
WHILE @i <= 20
BEGIN
    SELECT @id_guia = id FROM #guias WHERE seq = @i;
    SELECT @id_parque = id FROM #parques WHERE seq = ((@i - 1) % 10) + 1;
    EXEC turismo.GuiaParqueInsertar
        @p_id_guia             = @id_guia,
        @p_id_parque           = @id_parque,
        @p_fecha_autorizacion  = '2025-02-01',
        @p_estado_autorizacion = 1;
    SET @i += 1;
END

-- ==============================================================
-- 6. TOURS / ACTIVIDADES (30) -> #tours
--    Tours 1..6 en el parque 1 (caso 1: actividades múltiples).
--    Tour 1 = "Tour Demo Cupo Completo" con cupo chico (caso 2).
-- ==============================================================
PRINT 'Cargando 30 actividades/tours...';
CREATE TABLE #tours (seq INT, id INT, id_parque INT, cupo INT, costo DECIMAL(12,2));
SET @i = 1;
WHILE @i <= 30
BEGIN
    SET @v_parque_seq = CASE WHEN @i <= 6 THEN 1 ELSE 2 + ((@i - 7) % 9) END;
    SELECT @id_parque = id FROM #parques WHERE seq = @v_parque_seq;

    SET @cupo     = CASE WHEN @i = 1 THEN 10 ELSE 30 + (@i % 5) * 10 END;
    SET @costo    = 5000 + @i * 100;
    SET @v_tnombre = CASE WHEN @i = 1 THEN 'Tour Demo Cupo Completo' ELSE CONCAT('Tour Demo ', @i) END;
    SET @v_id_ta  = (SELECT id FROM @ta WHERE rn = ((@i - 1) % @ta_count) + 1);
    SET @v_dur    = 60 + (@i % 4) * 30;

    EXEC turismo.AtraccionTourInsertar
        @p_id_parque         = @id_parque,
        @p_id_tipo_atraccion = @v_id_ta,
        @p_nombre            = @v_tnombre,
        @p_costo             = @costo,
        @p_cupo_maximo       = @cupo,
        @p_duracion          = @v_dur;

    SET @id_tour = CAST(IDENT_CURRENT('turismo.AtraccionTour') AS INT);
    INSERT INTO #tours (seq, id, id_parque, cupo, costo) VALUES (@i, @id_tour, @id_parque, @cupo, @costo);

    -- Asignar una guía habilitada en el parque del tour (guía seq = parque seq, 1..10)
    SELECT @id_guia = id FROM #guias WHERE seq = @v_parque_seq;
    IF @id_guia IS NOT NULL
        EXEC turismo.TourGuiaInsertar @p_id_atraccion_tour = @id_tour, @p_id_guia = @id_guia;

    SET @i += 1;
END

-- ==============================================================
-- 7. HISTORIAL DE PRECIOS (entrada por parque, Residente y No residente)
--    -> #precios  (se usa el precio Residente para vender entradas)
-- ==============================================================
PRINT 'Cargando historial de precios de entrada...';
CREATE TABLE #precios (id_parque INT, id_precio INT, precio DECIMAL(12,2));
SET @i = 1;
WHILE @i <= 10
BEGIN
    SELECT @id_parque = id FROM #parques WHERE seq = @i;
    SET @precio = 3000 + @i * 100;

    EXEC ventas.HistorialPrecioInsertar
        @p_precio            = @precio,
        @p_fecha_desde       = '2026-01-01',
        @p_id_parque         = @id_parque,
        @p_id_tipo_visitante = @id_tv_res;
    INSERT INTO #precios (id_parque, id_precio, precio)
        VALUES (@id_parque, CAST(IDENT_CURRENT('ventas.HistorialPrecio') AS INT), @precio);

    SET @precio = @precio * 3;   -- no residente paga más
    EXEC ventas.HistorialPrecioInsertar
        @p_precio            = @precio,
        @p_fecha_desde       = '2026-01-01',
        @p_id_parque         = @id_parque,
        @p_id_tipo_visitante = @id_tv_nores;
    SET @i += 1;
END

-- ==============================================================
-- 8. CONCESIONES (10) — 6 vigentes + 4 vencidas (caso 3)
-- ==============================================================
PRINT 'Cargando 10 concesiones (vigentes y vencidas)...';
DECLARE @actividades TABLE (rn INT IDENTITY(1,1), val VARCHAR(100));
INSERT INTO @actividades (val) VALUES
 ('Camping'),('Cafetería'),('Alquiler de equipos'),('Transporte'),
 ('Souvenirs'),('Guía turística'),('Restaurante'),('Kiosco');

SET @i = 1;
WHILE @i <= 10
BEGIN
    SELECT @id_parque  = id FROM #parques  WHERE seq = ((@i - 1) % 10) + 1;
    SELECT @id_empresa = id FROM #empresas WHERE seq = ((@i - 1) % 6) + 1;
    SET @v_actividad = (SELECT val FROM @actividades WHERE rn = ((@i - 1) % 8) + 1);
    SET @v_canon     = 50000 + @i * 5000;

    IF @i <= 6
    BEGIN
        -- Vigentes: empezaron hace unos meses y terminan en el futuro
        SET @v_fini = DATEADD(MONTH, -6, CAST(GETDATE() AS DATE));
        SET @v_ffin = DATEADD(MONTH, 12, CAST(GETDATE() AS DATE));
    END
    ELSE
    BEGIN
        -- Vencidas: empezaron y terminaron en el pasado
        SET @v_fini = DATEADD(MONTH, -24, CAST(GETDATE() AS DATE));
        SET @v_ffin = DATEADD(MONTH, -8,  CAST(GETDATE() AS DATE));
    END

    EXEC comercial.ConcesionConObligacionesRegistrar
        @p_id_parque      = @id_parque,
        @p_id_empresa     = @id_empresa,
        @p_tipo_actividad = @v_actividad,
        @p_fecha_inicio   = @v_fini,
        @p_fecha_fin      = @v_ffin,
        @p_canon_mensual  = @v_canon;
    SET @i += 1;
END

-- ==============================================================
-- 9. HISTORIAL DE VENTAS DE ENTRADAS
-- ==============================================================
PRINT 'Registrando historial de ventas...';

-- Datos del tour de cupo completo (tour seq = 1)
DECLARE @tour_cupo_id INT, @tour_cupo_parque INT, @tour_cupo_costo DECIMAL(12,2);
SELECT @tour_cupo_id = id, @tour_cupo_parque = id_parque, @tour_cupo_costo = costo
FROM #tours WHERE seq = 1;

-- 9.a CASO 2: ventas que completan el cupo del tour (10 = 6 + 4) en la misma fecha
DELETE FROM @det;
SET @cant = 6; SET @sub = @cant * @tour_cupo_costo;
INSERT INTO @det (id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal)
VALUES (@tour_cupo_parque, NULL, NULL, @tour_cupo_id, '2026-03-15', @cant, @tour_cupo_costo, @sub);
EXEC ventas.VentaRegistrar '0001', 'SEED-T0001', '2026-03-10T10:00:00', @id_fp_efectivo, @sub, @det;

DELETE FROM @det;
SET @cant = 4; SET @sub = @cant * @tour_cupo_costo;
INSERT INTO @det (id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal)
VALUES (@tour_cupo_parque, NULL, NULL, @tour_cupo_id, '2026-03-15', @cant, @tour_cupo_costo, @sub);
EXEC ventas.VentaRegistrar '0001', 'SEED-T0002', '2026-03-12T11:00:00', @id_fp_efectivo, @sub, @det;

-- 9.b CASO 1: varios tours del parque 1 vendidos en la MISMA fecha de acceso (simultáneos)
DELETE FROM @det;
SET @total = 0;
SELECT @id_parque = id FROM #parques WHERE seq = 1;
SET @i = 2;  -- tours 2..6 del parque 1
WHILE @i <= 6
BEGIN
    SELECT @id_tour = id, @costo = costo FROM #tours WHERE seq = @i;
    SET @cant = 2; SET @sub = @cant * @costo;
    INSERT INTO @det (id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal)
    VALUES (@id_parque, NULL, NULL, @id_tour, '2026-03-20', @cant, @costo, @sub);
    SET @total += @sub;
    SET @i += 1;
END
EXEC ventas.VentaRegistrar '0001', 'SEED-T0003', '2026-03-18T09:30:00', @id_fp_efectivo, @total, @det;

-- 9.c Historial de ventas de ENTRADAS (un ticket por parque)
SET @i = 1;
WHILE @i <= 10
BEGIN
    SELECT @id_parque = id FROM #parques WHERE seq = @i;
    SELECT @id = id_precio, @precio = precio FROM #precios WHERE id_parque = @id_parque;
    SET @cant   = 1 + (@i % 5);
    SET @sub    = @cant * @precio;
    SET @v_num  = CONCAT('SEED-E', RIGHT('000' + CAST(@i AS VARCHAR(4)), 4));
    SET @v_facc = DATEADD(DAY, @i, '2026-02-01');
    SET @v_fventa = @v_facc;

    DELETE FROM @det;
    INSERT INTO @det (id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal)
    VALUES (@id_parque, @id, @id_tv_res, NULL, @v_facc, @cant, @precio, @sub);

    EXEC ventas.VentaRegistrar
        @p_punto_venta   = '0002',
        @p_numero        = @v_num,
        @p_fecha_venta   = @v_fventa,
        @p_id_forma_pago = @id_fp_efectivo,
        @p_total         = @sub,
        @p_detalles      = @det;
    SET @i += 1;
END

PRINT '===========================================================';
PRINT ' Juego de datos sembrado correctamente.';
PRINT '===========================================================';

DROP TABLE #empresas;
DROP TABLE #parques;
DROP TABLE #guardaparques;
DROP TABLE #guias;
DROP TABLE #tours;
DROP TABLE #precios;
GO

-- ==============================================================
-- VERIFICACIÓN DEL JUEGO DE DATOS (conteos y casos obligatorios)
-- ==============================================================
PRINT '===========================================================';
PRINT ' Verificación de conteos (mínimos exigidos)';
PRINT '===========================================================';
GO
SELECT 'Parques'        AS entidad, COUNT(*) AS cantidad, 10 AS minimo FROM parques.Parque
UNION ALL SELECT 'Tours',          COUNT(*), 30 FROM turismo.AtraccionTour
UNION ALL SELECT 'Guías',          COUNT(*), 20 FROM turismo.Guia
UNION ALL SELECT 'Guardaparques',  COUNT(*), 20 FROM personal.Guardaparque
UNION ALL SELECT 'Concesiones',    COUNT(*), 10 FROM comercial.Concesion
UNION ALL SELECT 'Tickets',        COUNT(*), 0  FROM ventas.Ticket
UNION ALL SELECT 'Detalle ventas', COUNT(*), 0  FROM ventas.TicketDetalle;
GO

PRINT '--- CASO 1: parque SEED-PN01 con múltiples actividades simultáneas (misma fecha_acceso) ---';
GO
SELECT td.fecha_acceso,
       COUNT(DISTINCT td.id_atraccion_tour) AS actividades_simultaneas
FROM ventas.TicketDetalle td
JOIN parques.Parque p ON p.id_parque = td.id_parque
WHERE p.codigo_oficial = 'SEED-PN01' AND td.id_atraccion_tour IS NOT NULL
GROUP BY td.fecha_acceso
HAVING COUNT(DISTINCT td.id_atraccion_tour) > 1;
GO

PRINT '--- CASO 2: tour con cupo completo (vendido = cupo_maximo) ---';
GO
SELECT at.nombre,
       at.cupo_maximo,
       SUM(td.cantidad) AS vendido,
       CASE WHEN SUM(td.cantidad) >= at.cupo_maximo THEN 'CUPO COMPLETO' ELSE 'con lugar' END AS estado
FROM turismo.AtraccionTour at
JOIN ventas.TicketDetalle td ON td.id_atraccion_tour = at.id_atraccion_tour
WHERE at.nombre = 'Tour Demo Cupo Completo'
GROUP BY at.nombre, at.cupo_maximo;
GO

PRINT '--- CASO 3: concesiones vigentes y vencidas ---';
GO
SELECT CASE WHEN fecha_fin >= CAST(GETDATE() AS DATE) THEN 'VIGENTE' ELSE 'VENCIDA' END AS situacion,
       COUNT(*) AS cantidad
FROM comercial.Concesion
GROUP BY CASE WHEN fecha_fin >= CAST(GETDATE() AS DATE) THEN 'VIGENTE' ELSE 'VENCIDA' END;
GO
