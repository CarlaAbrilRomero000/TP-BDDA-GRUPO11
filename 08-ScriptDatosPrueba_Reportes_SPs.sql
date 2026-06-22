/*
==============================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Fecha:       16/06/2026
Descripción: Entrega 7 - Datos de prueba (INSERTs) para validar
             los Store Procedures de reportes (07-ScriptReportes_SPs.sql).

             Carga un set de datos coherente que ejercita los 5
             reportes:
               - Reporte_Visitas         (visitas semana/mes/año)
               - Ingresos_Parque         (entradas + tours + concesiones)
               - Deudores_XML            (obligaciones vencidas con deuda)
               - Matriz_Visitas          (pivot de meses)
               - Parques_Concesiones_XML (parques + concesiones)

             El script es RE-EJECUTABLE: borra los datos 'REP-TEST'
             previos antes de volver a insertarlos.

             Orden de ejecución sugerido:
               1. 01-ScriptCreacionTablasYSchemas.sql
               2. 02-ScriptABM_SPs.sql
               3. 03-ScriptLogicaNegocio_SPs.sql
               4. 07-ScriptReportes_SPs.sql
               5. Este script (09)
               6. 08-ScriptTesting_Reportes_SPs.sql
==============================================================
*/

USE ParquesNacionalesDB;
GO

SET NOCOUNT ON;

PRINT '==============================================================';
PRINT ' LIMPIEZA de datos REP-TEST previos (para re-ejecución)';
PRINT '==============================================================';

-- Borrado en orden seguro respecto de las claves foráneas
DELETE FROM ventas.TicketDetalle
WHERE id_ticket IN (SELECT id_ticket FROM ventas.Ticket WHERE numero LIKE 'REP-%');
DELETE FROM ventas.Ticket WHERE numero LIKE 'REP-%';

DELETE FROM comercial.PagoCanon
WHERE id_obligacion IN (
    SELECT oc.id_obligacion FROM comercial.ObligacionCanon oc
    JOIN comercial.Concesion c ON c.id_concesion = oc.id_concesion
    WHERE c.tipo_actividad LIKE '%REP-TEST');
DELETE FROM comercial.ObligacionCanon
WHERE id_concesion IN (SELECT id_concesion FROM comercial.Concesion WHERE tipo_actividad LIKE '%REP-TEST');
DELETE FROM comercial.Concesion WHERE tipo_actividad LIKE '%REP-TEST';

DELETE FROM turismo.AtraccionTour WHERE nombre LIKE '%REP-TEST';
DELETE FROM ventas.HistorialPrecio
WHERE id_parque IN (SELECT id_parque FROM parques.Parque WHERE codigo_oficial LIKE 'PN-REP%');
DELETE FROM parques.Parque WHERE codigo_oficial LIKE 'PN-REP%';

DELETE FROM comercial.Empresa WHERE cuit IN ('30700000011', '30700000022');
DELETE FROM parques.TipoParque   WHERE descripcion LIKE '%REP-TEST';
DELETE FROM ventas.TipoVisitante WHERE descripcion LIKE '%REP-TEST';
DELETE FROM ventas.FormaPago     WHERE descripcion LIKE '%REP-TEST';
DELETE FROM turismo.TipoAtraccion WHERE descripcion LIKE '%REP-TEST';

PRINT 'OK - Datos REP-TEST previos eliminados (si existían).';
GO

-- ==============================================================
-- INSERCIÓN DE DATOS DE PRUEBA
-- (Todo en un único batch para poder reutilizar las variables
--  con los IDs generados por las columnas IDENTITY)
-- ==============================================================
SET NOCOUNT ON;

DECLARE
    @id_tipo_parque      INT,
    @id_tv_adulto        INT,
    @id_tv_menor         INT,
    @id_forma_pago       INT,
    @id_tipo_atraccion   INT,
    @id_parque1          INT,
    @id_parque2          INT,
    @id_empresa1         INT,
    @id_empresa2         INT,
    @hp_p1_adulto        INT,
    @hp_p1_menor         INT,
    @hp_p2_adulto        INT,
    @at_p1               INT,
    @at_p2               INT,
    @id_concesion1       INT,
    @id_concesion2       INT,
    @ob_ene              INT,
    @ob_feb              INT,
    @ob_mar              INT,
    @ob_p2               INT,
    @id_ticket1          INT,
    @id_ticket2          INT,
    @id_ticket3          INT;

PRINT '';
PRINT '==============================================================';
PRINT ' 1) Tablas maestras (tipos, forma de pago, empresas)';
PRINT '==============================================================';

INSERT INTO parques.TipoParque (descripcion) VALUES ('Parque Nacional REP-TEST');
SET @id_tipo_parque = SCOPE_IDENTITY();

INSERT INTO ventas.TipoVisitante (descripcion) VALUES ('Adulto REP-TEST');
SET @id_tv_adulto = SCOPE_IDENTITY();
INSERT INTO ventas.TipoVisitante (descripcion) VALUES ('Menor REP-TEST');
SET @id_tv_menor = SCOPE_IDENTITY();

INSERT INTO ventas.FormaPago (descripcion) VALUES ('Efectivo REP-TEST');
SET @id_forma_pago = SCOPE_IDENTITY();

INSERT INTO turismo.TipoAtraccion (descripcion) VALUES ('Trekking REP-TEST');
SET @id_tipo_atraccion = SCOPE_IDENTITY();

INSERT INTO comercial.Empresa (cuit, razon_social, telefono, email, direccion)
VALUES ('30700000011', 'Servicios Iguazú S.A. REP-TEST', '03757-555-0001', 'contacto@iguazurep.com', 'Puerto Iguazú, Misiones');
SET @id_empresa1 = SCOPE_IDENTITY();

INSERT INTO comercial.Empresa (cuit, razon_social, telefono, email, direccion)
VALUES ('30700000022', 'Excursiones Sur S.R.L. REP-TEST', '0294-555-0002', 'info@excursionesrep.com', 'Bariloche, Río Negro');
SET @id_empresa2 = SCOPE_IDENTITY();

PRINT 'OK - Tipos, forma de pago y empresas insertados.';

PRINT '';
PRINT '==============================================================';
PRINT ' 2) Parques';
PRINT '==============================================================';

INSERT INTO parques.Parque (codigo_oficial, nombre, ubicacion, superficie, id_tipo_parque)
VALUES ('PN-REP-01', 'Iguazú REP-TEST', 'Misiones, Argentina', 67620.00, @id_tipo_parque);
SET @id_parque1 = SCOPE_IDENTITY();

INSERT INTO parques.Parque (codigo_oficial, nombre, ubicacion, superficie, id_tipo_parque)
VALUES ('PN-REP-02', 'Nahuel Huapi REP-TEST', 'Río Negro / Neuquén, Argentina', 717261.00, @id_tipo_parque);
SET @id_parque2 = SCOPE_IDENTITY();

PRINT 'OK - 2 parques insertados.';

PRINT '';
PRINT '==============================================================';
PRINT ' 3) Historial de precios (entradas) y atracciones (tours)';
PRINT '==============================================================';

INSERT INTO ventas.HistorialPrecio (precio, fecha_desde, id_parque, id_tipo_visitante)
VALUES (5000.00, '2025-01-01', @id_parque1, @id_tv_adulto);
SET @hp_p1_adulto = SCOPE_IDENTITY();

INSERT INTO ventas.HistorialPrecio (precio, fecha_desde, id_parque, id_tipo_visitante)
VALUES (2500.00, '2025-01-01', @id_parque1, @id_tv_menor);
SET @hp_p1_menor = SCOPE_IDENTITY();

INSERT INTO ventas.HistorialPrecio (precio, fecha_desde, id_parque, id_tipo_visitante)
VALUES (4000.00, '2025-01-01', @id_parque2, @id_tv_adulto);
SET @hp_p2_adulto = SCOPE_IDENTITY();

INSERT INTO turismo.AtraccionTour (id_parque, id_tipo_atraccion, nombre, costo, cupo_maximo, duracion)
VALUES (@id_parque1, @id_tipo_atraccion, 'Sendero Garganta del Diablo REP-TEST', 8000.00, 30, 120);
SET @at_p1 = SCOPE_IDENTITY();

INSERT INTO turismo.AtraccionTour (id_parque, id_tipo_atraccion, nombre, costo, cupo_maximo, duracion)
VALUES (@id_parque2, @id_tipo_atraccion, 'Trekking Cerro Catedral REP-TEST', 6000.00, 20, 180);
SET @at_p2 = SCOPE_IDENTITY();

PRINT 'OK - Historial de precios y atracciones insertados.';

PRINT '';
PRINT '==============================================================';
PRINT ' 4) Concesiones, obligaciones de canon y pagos';
PRINT '    (alimenta Deudores_XML y la parte de concesiones';
PRINT '     de Ingresos_Parque)';
PRINT '==============================================================';

-- Concesión 1: Parque 1 / Empresa 1
INSERT INTO comercial.Concesion (id_parque, id_empresa, tipo_actividad, fecha_inicio, fecha_fin, canon_mensual)
VALUES (@id_parque1, @id_empresa1, 'Gastronomía REP-TEST', '2026-01-01', '2026-12-31', 50000.00);
SET @id_concesion1 = SCOPE_IDENTITY();

-- Concesión 2: Parque 2 / Empresa 2
INSERT INTO comercial.Concesion (id_parque, id_empresa, tipo_actividad, fecha_inicio, fecha_fin, canon_mensual)
VALUES (@id_parque2, @id_empresa2, 'Alquiler de kayaks REP-TEST', '2026-01-01', '2026-12-31', 30000.00);
SET @id_concesion2 = SCOPE_IDENTITY();

-- Obligaciones de la Concesión 1 (vencidas, ya pasó el 2026-06-16)
--   Enero  -> PAGADA total (NO debe figurar como deudor)
INSERT INTO comercial.ObligacionCanon (id_concesion, mes, anio, monto_obligado, estado, fecha_vencimiento)
VALUES (@id_concesion1, 1, 2026, 50000.00, 'PAGADO', '2026-01-10');
SET @ob_ene = SCOPE_IDENTITY();
--   Febrero -> PARCIAL (debe figurar con deuda de 30000)
INSERT INTO comercial.ObligacionCanon (id_concesion, mes, anio, monto_obligado, estado, fecha_vencimiento)
VALUES (@id_concesion1, 2, 2026, 50000.00, 'PARCIAL', '2026-02-10');
SET @ob_feb = SCOPE_IDENTITY();
--   Marzo   -> PENDIENTE sin pagos (debe figurar con deuda de 50000)
INSERT INTO comercial.ObligacionCanon (id_concesion, mes, anio, monto_obligado, estado, fecha_vencimiento)
VALUES (@id_concesion1, 3, 2026, 50000.00, 'PENDIENTE', '2026-03-10');
SET @ob_mar = SCOPE_IDENTITY();

-- Obligación de la Concesión 2 -> VENCIDO sin pagos (deuda de 30000)
INSERT INTO comercial.ObligacionCanon (id_concesion, mes, anio, monto_obligado, estado, fecha_vencimiento)
VALUES (@id_concesion2, 1, 2026, 30000.00, 'VENCIDO', '2026-01-10');
SET @ob_p2 = SCOPE_IDENTITY();

-- Pagos de canon
--   Enero concesión 1: pago total
INSERT INTO comercial.PagoCanon (id_obligacion, fecha_pago, monto_pagado)
VALUES (@ob_ene, '2026-01-08', 50000.00);
--   Febrero concesión 1: pago parcial (queda debiendo 30000)
INSERT INTO comercial.PagoCanon (id_obligacion, fecha_pago, monto_pagado)
VALUES (@ob_feb, '2026-02-09', 20000.00);

PRINT 'OK - 2 concesiones, 4 obligaciones y 2 pagos insertados.';
PRINT '     Deudores esperados: Febrero ($30000), Marzo ($50000) y Concesión 2 ($30000).';

PRINT '';
PRINT '==============================================================';
PRINT ' 5) Tickets y detalles (visitas e ingresos por entradas/tours)';
PRINT '    Fechas distribuidas en varios meses y 2 años distintos';
PRINT '==============================================================';

INSERT INTO ventas.Ticket (punto_venta, numero, fecha_venta, id_forma_pago, total)
VALUES ('0001', 'REP-0001', '2026-01-15 10:00:00', @id_forma_pago, 0);
SET @id_ticket1 = SCOPE_IDENTITY();

INSERT INTO ventas.Ticket (punto_venta, numero, fecha_venta, id_forma_pago, total)
VALUES ('0001', 'REP-0002', '2026-07-05 09:30:00', @id_forma_pago, 0);
SET @id_ticket2 = SCOPE_IDENTITY();

INSERT INTO ventas.Ticket (punto_venta, numero, fecha_venta, id_forma_pago, total)
VALUES ('0002', 'REP-0003', '2025-12-30 11:00:00', @id_forma_pago, 0);
SET @id_ticket3 = SCOPE_IDENTITY();

-- ----- Detalles del Parque 1 (Iguazú): entradas adulto -----
INSERT INTO ventas.TicketDetalle (id_ticket, id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal) VALUES
 (@id_ticket1, @id_parque1, @hp_p1_adulto, @id_tv_adulto, NULL, '2026-01-15', 10, 5000.00,  50000.00),
 (@id_ticket1, @id_parque1, @hp_p1_adulto, @id_tv_adulto, NULL, '2026-02-20',  8, 5000.00,  40000.00),
 (@id_ticket1, @id_parque1, @hp_p1_menor,  @id_tv_menor,  NULL, '2026-02-20',  5, 2500.00,  12500.00),
 (@id_ticket1, @id_parque1, @hp_p1_adulto, @id_tv_adulto, NULL, '2026-03-10', 12, 5000.00,  60000.00),
 (@id_ticket2, @id_parque1, @hp_p1_adulto, @id_tv_adulto, NULL, '2026-07-05', 20, 5000.00, 100000.00),
 (@id_ticket2, @id_parque1, @hp_p1_adulto, @id_tv_adulto, NULL, '2026-12-22', 15, 5000.00,  75000.00),
 (@id_ticket3, @id_parque1, @hp_p1_adulto, @id_tv_adulto, NULL, '2025-07-10',  9, 5000.00,  45000.00);

-- ----- Detalles del Parque 1: tours -----
INSERT INTO ventas.TicketDetalle (id_ticket, id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal) VALUES
 (@id_ticket1, @id_parque1, NULL, NULL, @at_p1, '2026-01-16', 4, 8000.00, 32000.00),
 (@id_ticket2, @id_parque1, NULL, NULL, @at_p1, '2026-07-06', 6, 8000.00, 48000.00);

-- ----- Detalles del Parque 2 (Nahuel Huapi): entradas adulto -----
INSERT INTO ventas.TicketDetalle (id_ticket, id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal) VALUES
 (@id_ticket1, @id_parque2, @hp_p2_adulto, @id_tv_adulto, NULL, '2026-02-11', 5, 4000.00, 20000.00),
 (@id_ticket2, @id_parque2, @hp_p2_adulto, @id_tv_adulto, NULL, '2026-08-03', 7, 4000.00, 28000.00),
 (@id_ticket3, @id_parque2, @hp_p2_adulto, @id_tv_adulto, NULL, '2025-12-30', 3, 4000.00, 12000.00);

-- ----- Detalles del Parque 2: tours -----
INSERT INTO ventas.TicketDetalle (id_ticket, id_parque, id_historial_precio, id_tipo_visitante, id_atraccion_tour, fecha_acceso, cantidad, precio_unitario, subtotal) VALUES
 (@id_ticket2, @id_parque2, NULL, NULL, @at_p2, '2026-08-04', 2, 6000.00, 12000.00);

-- Ajuste de totales de cada ticket = suma de sus subtotales
UPDATE t
SET t.total = x.suma
FROM ventas.Ticket t
JOIN (SELECT id_ticket, SUM(subtotal) AS suma FROM ventas.TicketDetalle GROUP BY id_ticket) x
  ON x.id_ticket = t.id_ticket
WHERE t.numero LIKE 'REP-%';

PRINT 'OK - 3 tickets y 13 detalles insertados.';

PRINT '';
PRINT '==============================================================';
PRINT ' RESUMEN DE DATOS CARGADOS';
PRINT '==============================================================';
SELECT 'Parques'        AS entidad, COUNT(*) AS cant FROM parques.Parque        WHERE codigo_oficial LIKE 'PN-REP%'
UNION ALL SELECT 'Tickets',        COUNT(*) FROM ventas.Ticket                  WHERE numero LIKE 'REP-%'
UNION ALL SELECT 'TicketDetalle',  COUNT(*) FROM ventas.TicketDetalle td        WHERE td.id_ticket IN (SELECT id_ticket FROM ventas.Ticket WHERE numero LIKE 'REP-%')
UNION ALL SELECT 'Concesiones',    COUNT(*) FROM comercial.Concesion            WHERE tipo_actividad LIKE '%REP-TEST'
UNION ALL SELECT 'Obligaciones',   COUNT(*) FROM comercial.ObligacionCanon oc   WHERE oc.id_concesion IN (SELECT id_concesion FROM comercial.Concesion WHERE tipo_actividad LIKE '%REP-TEST')
UNION ALL SELECT 'PagosCanon',     COUNT(*) FROM comercial.PagoCanon pc         WHERE pc.id_obligacion IN (SELECT oc.id_obligacion FROM comercial.ObligacionCanon oc JOIN comercial.Concesion c ON c.id_concesion = oc.id_concesion WHERE c.tipo_actividad LIKE '%REP-TEST');

PRINT '';
PRINT '==============================================================';
PRINT ' Datos de prueba cargados. Ahora ejecutá';
PRINT ' 08-ScriptTesting_Reportes_SPs.sql para ver los reportes.';
PRINT '==============================================================';
GO