/*
==============================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Fecha:       16/06/2026
Descripción: Script de testing para los SP de reportes (Entrega 7).

             Es self-contained y re-ejecutable: prepara sus propios
             datos de prueba (set 'REP-TEST'), ejecuta los 5 reportes
             y limpia los datos al final.

             Reportes ejercitados:
               - Reporte_Visitas         (visitas semana/mes/año)
               - Ingresos_Parque         (entradas + tours + concesiones)
               - Deudores_XML            (obligaciones vencidas con deuda)
               - Matriz_Visitas          (pivot de meses)
               - Parques_Concesiones_XML (parques + concesiones)

             Orden de ejecución:
               1. ScriptCreacionTablasYSchemas.sql
               2. ScriptABM_SPs.sql
               3. ScriptLogicaNegocio_SPs.sql
               4. ScriptReportes_SPs.sql
               5. Este script
==============================================================
*/

USE ParquesNacionalesDB;
GO

-- ==============================================================
-- LIMPIEZA PREVIA — elimina datos REP-TEST de corridas anteriores
--   (hace el script re-ejecutable; usa los SPs de baja).
--   Si no hay datos residuales, los bucles no hacen nada.
-- ==============================================================
SET NOCOUNT ON;

PRINT '==============================================================';
PRINT ' LIMPIEZA PREVIA — Eliminando datos REP-TEST residuales (si existen)';
PRINT '==============================================================';

DECLARE @id_prev INT;

-- TicketDetalle (detalles de los tickets REP-%)
WHILE EXISTS (SELECT 1 FROM ventas.TicketDetalle td JOIN ventas.Ticket t ON t.id_ticket = td.id_ticket WHERE t.numero LIKE 'REP-%')
BEGIN
    SELECT TOP 1 @id_prev = td.id_detalle FROM ventas.TicketDetalle td JOIN ventas.Ticket t ON t.id_ticket = td.id_ticket WHERE t.numero LIKE 'REP-%';
    EXEC ventas.TicketDetalleEliminar @p_id_detalle = @id_prev;
END

-- Ticket
WHILE EXISTS (SELECT 1 FROM ventas.Ticket WHERE numero LIKE 'REP-%')
BEGIN
    SELECT TOP 1 @id_prev = id_ticket FROM ventas.Ticket WHERE numero LIKE 'REP-%';
    EXEC ventas.TicketEliminar @p_id_ticket = @id_prev;
END

-- PagoCanon (pagos de obligaciones de concesiones REP-TEST)
WHILE EXISTS (SELECT 1 FROM comercial.PagoCanon pc JOIN comercial.ObligacionCanon oc ON oc.id_obligacion = pc.id_obligacion JOIN comercial.Concesion c ON c.id_concesion = oc.id_concesion WHERE c.tipo_actividad LIKE '%REP-TEST')
BEGIN
    SELECT TOP 1 @id_prev = pc.id_pago FROM comercial.PagoCanon pc JOIN comercial.ObligacionCanon oc ON oc.id_obligacion = pc.id_obligacion JOIN comercial.Concesion c ON c.id_concesion = oc.id_concesion WHERE c.tipo_actividad LIKE '%REP-TEST';
    EXEC comercial.PagoCanonEliminar @p_id_pago = @id_prev;
END

-- ObligacionCanon
WHILE EXISTS (SELECT 1 FROM comercial.ObligacionCanon oc JOIN comercial.Concesion c ON c.id_concesion = oc.id_concesion WHERE c.tipo_actividad LIKE '%REP-TEST')
BEGIN
    SELECT TOP 1 @id_prev = oc.id_obligacion FROM comercial.ObligacionCanon oc JOIN comercial.Concesion c ON c.id_concesion = oc.id_concesion WHERE c.tipo_actividad LIKE '%REP-TEST';
    EXEC comercial.ObligacionCanonEliminar @p_id_obligacion = @id_prev;
END

-- Concesion
WHILE EXISTS (SELECT 1 FROM comercial.Concesion WHERE tipo_actividad LIKE '%REP-TEST')
BEGIN
    SELECT TOP 1 @id_prev = id_concesion FROM comercial.Concesion WHERE tipo_actividad LIKE '%REP-TEST';
    EXEC comercial.ConcesionEliminar @p_id_concesion = @id_prev;
END

-- HistorialPrecio (de los parques PN-REP%)
WHILE EXISTS (SELECT 1 FROM ventas.HistorialPrecio hp JOIN parques.Parque p ON p.id_parque = hp.id_parque WHERE p.codigo_oficial LIKE 'PN-REP%')
BEGIN
    SELECT TOP 1 @id_prev = hp.id_historial_precio FROM ventas.HistorialPrecio hp JOIN parques.Parque p ON p.id_parque = hp.id_parque WHERE p.codigo_oficial LIKE 'PN-REP%';
    EXEC ventas.HistorialPrecioEliminar @p_id_historial_precio = @id_prev;
END

-- AtraccionTour
WHILE EXISTS (SELECT 1 FROM turismo.AtraccionTour WHERE nombre LIKE '%REP-TEST')
BEGIN
    SELECT TOP 1 @id_prev = id_atraccion_tour FROM turismo.AtraccionTour WHERE nombre LIKE '%REP-TEST';
    EXEC turismo.AtraccionTourEliminar @p_id_atraccion_tour = @id_prev;
END

-- Parque
WHILE EXISTS (SELECT 1 FROM parques.Parque WHERE codigo_oficial LIKE 'PN-REP%')
BEGIN
    SELECT TOP 1 @id_prev = id_parque FROM parques.Parque WHERE codigo_oficial LIKE 'PN-REP%';
    EXEC parques.ParqueEliminar @p_id_parque = @id_prev;
END

-- Empresa
WHILE EXISTS (SELECT 1 FROM comercial.Empresa WHERE cuit IN ('30700000011', '30700000022'))
BEGIN
    SELECT TOP 1 @id_prev = id_empresa FROM comercial.Empresa WHERE cuit IN ('30700000011', '30700000022');
    EXEC comercial.EmpresaEliminar @p_id_empresa = @id_prev;
END

-- TipoParque
WHILE EXISTS (SELECT 1 FROM parques.TipoParque WHERE descripcion LIKE '%REP-TEST')
BEGIN
    SELECT TOP 1 @id_prev = id_tipo_parque FROM parques.TipoParque WHERE descripcion LIKE '%REP-TEST';
    EXEC parques.TipoParqueEliminar @p_id_tipo_parque = @id_prev;
END

-- TipoVisitante
WHILE EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE descripcion LIKE '%REP-TEST')
BEGIN
    SELECT TOP 1 @id_prev = id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion LIKE '%REP-TEST';
    EXEC ventas.TipoVisitanteEliminar @p_id_tipo_visitante = @id_prev;
END

-- FormaPago
WHILE EXISTS (SELECT 1 FROM ventas.FormaPago WHERE descripcion LIKE '%REP-TEST')
BEGIN
    SELECT TOP 1 @id_prev = id_forma_pago FROM ventas.FormaPago WHERE descripcion LIKE '%REP-TEST';
    EXEC ventas.FormaPagoEliminar @p_id_forma_pago = @id_prev;
END

-- TipoAtraccion
WHILE EXISTS (SELECT 1 FROM turismo.TipoAtraccion WHERE descripcion LIKE '%REP-TEST')
BEGIN
    SELECT TOP 1 @id_prev = id_tipo_atraccion FROM turismo.TipoAtraccion WHERE descripcion LIKE '%REP-TEST';
    EXEC turismo.TipoAtraccionEliminar @p_id_tipo_atraccion = @id_prev;
END

PRINT 'OK - Limpieza previa completada.';
GO

-- ==============================================================
-- PREPARACIÓN — INSERCIÓN DE DATOS DE PRUEBA (vía Store Procedures)
-- (Todo en un único batch para reutilizar las variables con los
--  IDs recuperados después de cada alta)
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
PRINT ' PREPARACIÓN 1 — Tablas maestras (tipos, forma de pago, empresas)';
PRINT '==============================================================';

EXEC parques.TipoParqueInsertar @p_descripcion = 'Parque Nacional REP-TEST';
SELECT @id_tipo_parque = id_tipo_parque FROM parques.TipoParque WHERE descripcion = 'Parque Nacional REP-TEST';
PRINT 'OK - TipoParque insertado. ID: ' + CAST(@id_tipo_parque AS VARCHAR(10));

EXEC ventas.TipoVisitanteInsertar @p_descripcion = 'Adulto REP-TEST';
SELECT @id_tv_adulto = id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Adulto REP-TEST';
PRINT 'OK - TipoVisitante (Adulto) insertado. ID: ' + CAST(@id_tv_adulto AS VARCHAR(10));

EXEC ventas.TipoVisitanteInsertar @p_descripcion = 'Menor REP-TEST';
SELECT @id_tv_menor = id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion = 'Menor REP-TEST';
PRINT 'OK - TipoVisitante (Menor) insertado. ID: ' + CAST(@id_tv_menor AS VARCHAR(10));

EXEC ventas.FormaPagoInsertar @p_descripcion = 'Efectivo REP-TEST';
SELECT @id_forma_pago = id_forma_pago FROM ventas.FormaPago WHERE descripcion = 'Efectivo REP-TEST';
PRINT 'OK - FormaPago insertado. ID: ' + CAST(@id_forma_pago AS VARCHAR(10));

EXEC turismo.TipoAtraccionInsertar @p_descripcion = 'Trekking REP-TEST';
SELECT @id_tipo_atraccion = id_tipo_atraccion FROM turismo.TipoAtraccion WHERE descripcion = 'Trekking REP-TEST';
PRINT 'OK - TipoAtraccion insertado. ID: ' + CAST(@id_tipo_atraccion AS VARCHAR(10));

EXEC comercial.EmpresaInsertar
    @p_cuit         = '30700000011',
    @p_razon_social = 'Servicios Iguazú S.A. REP-TEST',
    @p_telefono     = '03757-555-0001',
    @p_email        = 'contacto@iguazurep.com',
    @p_direccion    = 'Puerto Iguazú, Misiones';
SELECT @id_empresa1 = id_empresa FROM comercial.Empresa WHERE cuit = '30700000011';
PRINT 'OK - Empresa 1 insertada. ID: ' + CAST(@id_empresa1 AS VARCHAR(10));

EXEC comercial.EmpresaInsertar
    @p_cuit         = '30700000022',
    @p_razon_social = 'Excursiones Sur S.R.L. REP-TEST',
    @p_telefono     = '0294-555-0002',
    @p_email        = 'info@excursionesrep.com',
    @p_direccion    = 'Bariloche, Río Negro';
SELECT @id_empresa2 = id_empresa FROM comercial.Empresa WHERE cuit = '30700000022';
PRINT 'OK - Empresa 2 insertada. ID: ' + CAST(@id_empresa2 AS VARCHAR(10));

PRINT '';
PRINT '==============================================================';
PRINT ' PREPARACIÓN 2 — Parques';
PRINT '==============================================================';

EXEC parques.ParqueInsertar
    @p_codigo_oficial = 'PN-REP-01',
    @p_nombre         = 'Iguazú REP-TEST',
    @p_ubicacion      = 'Misiones, Argentina',
    @p_superficie     = 67620.00,
    @p_id_tipo_parque = @id_tipo_parque;
SELECT @id_parque1 = id_parque FROM parques.Parque WHERE codigo_oficial = 'PN-REP-01';
PRINT 'OK - Parque 1 insertado. ID: ' + CAST(@id_parque1 AS VARCHAR(10));

EXEC parques.ParqueInsertar
    @p_codigo_oficial = 'PN-REP-02',
    @p_nombre         = 'Nahuel Huapi REP-TEST',
    @p_ubicacion      = 'Río Negro / Neuquén, Argentina',
    @p_superficie     = 717261.00,
    @p_id_tipo_parque = @id_tipo_parque;
SELECT @id_parque2 = id_parque FROM parques.Parque WHERE codigo_oficial = 'PN-REP-02';
PRINT 'OK - Parque 2 insertado. ID: ' + CAST(@id_parque2 AS VARCHAR(10));

PRINT '';
PRINT '==============================================================';
PRINT ' PREPARACIÓN 3 — Historial de precios (entradas) y atracciones (tours)';
PRINT '==============================================================';

EXEC ventas.HistorialPrecioInsertar
    @p_precio            = 5000.00,
    @p_fecha_desde       = '2025-01-01',
    @p_id_parque         = @id_parque1,
    @p_id_tipo_visitante = @id_tv_adulto;
SELECT @hp_p1_adulto = id_historial_precio FROM ventas.HistorialPrecio
WHERE id_parque = @id_parque1 AND id_tipo_visitante = @id_tv_adulto;
PRINT 'OK - HistorialPrecio P1/Adulto insertado. ID: ' + CAST(@hp_p1_adulto AS VARCHAR(10));

EXEC ventas.HistorialPrecioInsertar
    @p_precio            = 2500.00,
    @p_fecha_desde       = '2025-01-01',
    @p_id_parque         = @id_parque1,
    @p_id_tipo_visitante = @id_tv_menor;
SELECT @hp_p1_menor = id_historial_precio FROM ventas.HistorialPrecio
WHERE id_parque = @id_parque1 AND id_tipo_visitante = @id_tv_menor;
PRINT 'OK - HistorialPrecio P1/Menor insertado. ID: ' + CAST(@hp_p1_menor AS VARCHAR(10));

EXEC ventas.HistorialPrecioInsertar
    @p_precio            = 4000.00,
    @p_fecha_desde       = '2025-01-01',
    @p_id_parque         = @id_parque2,
    @p_id_tipo_visitante = @id_tv_adulto;
SELECT @hp_p2_adulto = id_historial_precio FROM ventas.HistorialPrecio
WHERE id_parque = @id_parque2 AND id_tipo_visitante = @id_tv_adulto;
PRINT 'OK - HistorialPrecio P2/Adulto insertado. ID: ' + CAST(@hp_p2_adulto AS VARCHAR(10));

EXEC turismo.AtraccionTourInsertar
    @p_id_parque         = @id_parque1,
    @p_id_tipo_atraccion = @id_tipo_atraccion,
    @p_nombre            = 'Sendero Garganta del Diablo REP-TEST',
    @p_costo             = 8000.00,
    @p_cupo_maximo       = 30,
    @p_duracion          = 120;
SELECT @at_p1 = id_atraccion_tour FROM turismo.AtraccionTour WHERE nombre = 'Sendero Garganta del Diablo REP-TEST';
PRINT 'OK - AtraccionTour P1 insertada. ID: ' + CAST(@at_p1 AS VARCHAR(10));

EXEC turismo.AtraccionTourInsertar
    @p_id_parque         = @id_parque2,
    @p_id_tipo_atraccion = @id_tipo_atraccion,
    @p_nombre            = 'Trekking Cerro Catedral REP-TEST',
    @p_costo             = 6000.00,
    @p_cupo_maximo       = 20,
    @p_duracion          = 180;
SELECT @at_p2 = id_atraccion_tour FROM turismo.AtraccionTour WHERE nombre = 'Trekking Cerro Catedral REP-TEST';
PRINT 'OK - AtraccionTour P2 insertada. ID: ' + CAST(@at_p2 AS VARCHAR(10));

PRINT '';
PRINT '==============================================================';
PRINT ' PREPARACIÓN 4 — Concesiones, obligaciones de canon y pagos';
PRINT '    (alimenta Deudores_XML y la parte de concesiones';
PRINT '     de Ingresos_Parque)';
PRINT '==============================================================';

-- Concesión 1: Parque 1 / Empresa 1
EXEC comercial.ConcesionInsertar
    @p_id_parque      = @id_parque1,
    @p_id_empresa     = @id_empresa1,
    @p_tipo_actividad = 'Gastronomía REP-TEST',
    @p_fecha_inicio   = '2026-01-01',
    @p_fecha_fin      = '2026-12-31',
    @p_canon_mensual  = 50000.00;
SELECT @id_concesion1 = id_concesion FROM comercial.Concesion WHERE tipo_actividad = 'Gastronomía REP-TEST';
PRINT 'OK - Concesión 1 insertada. ID: ' + CAST(@id_concesion1 AS VARCHAR(10));

-- Concesión 2: Parque 2 / Empresa 2
EXEC comercial.ConcesionInsertar
    @p_id_parque      = @id_parque2,
    @p_id_empresa     = @id_empresa2,
    @p_tipo_actividad = 'Alquiler de kayaks REP-TEST',
    @p_fecha_inicio   = '2026-01-01',
    @p_fecha_fin      = '2026-12-31',
    @p_canon_mensual  = 30000.00;
SELECT @id_concesion2 = id_concesion FROM comercial.Concesion WHERE tipo_actividad = 'Alquiler de kayaks REP-TEST';
PRINT 'OK - Concesión 2 insertada. ID: ' + CAST(@id_concesion2 AS VARCHAR(10));

-- Obligaciones de la Concesión 1 (vencidas, ya pasó el 2026-06-16)
-- Se cargan en estado PENDIENTE; el estado final lo determina el pago.
EXEC comercial.ObligacionCanonInsertar
    @p_id_concesion      = @id_concesion1, @p_mes = 1, @p_anio = 2026,
    @p_monto_obligado    = 50000.00, @p_estado = 'PENDIENTE', @p_fecha_vencimiento = '2026-01-10';
SELECT @ob_ene = id_obligacion FROM comercial.ObligacionCanon WHERE id_concesion = @id_concesion1 AND mes = 1 AND anio = 2026;

EXEC comercial.ObligacionCanonInsertar
    @p_id_concesion      = @id_concesion1, @p_mes = 2, @p_anio = 2026,
    @p_monto_obligado    = 50000.00, @p_estado = 'PENDIENTE', @p_fecha_vencimiento = '2026-02-10';
SELECT @ob_feb = id_obligacion FROM comercial.ObligacionCanon WHERE id_concesion = @id_concesion1 AND mes = 2 AND anio = 2026;

-- Marzo: PENDIENTE sin pagos (debe figurar con deuda de 50000)
EXEC comercial.ObligacionCanonInsertar
    @p_id_concesion      = @id_concesion1, @p_mes = 3, @p_anio = 2026,
    @p_monto_obligado    = 50000.00, @p_estado = 'PENDIENTE', @p_fecha_vencimiento = '2026-03-10';
SELECT @ob_mar = id_obligacion FROM comercial.ObligacionCanon WHERE id_concesion = @id_concesion1 AND mes = 3 AND anio = 2026;

-- Concesión 2: VENCIDO sin pagos (deuda de 30000)
EXEC comercial.ObligacionCanonInsertar
    @p_id_concesion      = @id_concesion2, @p_mes = 1, @p_anio = 2026,
    @p_monto_obligado    = 30000.00, @p_estado = 'VENCIDO', @p_fecha_vencimiento = '2026-01-10';
SELECT @ob_p2 = id_obligacion FROM comercial.ObligacionCanon WHERE id_concesion = @id_concesion2 AND mes = 1 AND anio = 2026;

PRINT 'OK - 2 concesiones y 4 obligaciones insertadas.';

-- Pagos de canon (vía SP). El estado se ajusta luego con ObligacionCanonModificar,
-- porque PagoCanonInsertar no permite pagar una obligación ya marcada como PAGADO.
--   Enero concesión 1: pago total -> queda PAGADO (deuda 0, no figura como deudor)
EXEC comercial.PagoCanonInsertar @p_id_obligacion = @ob_ene, @p_fecha_pago = '2026-01-08', @p_monto_pagado = 50000.00;
EXEC comercial.ObligacionCanonModificar @p_id_obligacion = @ob_ene, @p_monto_obligado = 50000.00, @p_estado = 'PAGADO', @p_fecha_vencimiento = '2026-01-10';

--   Febrero concesión 1: pago parcial -> queda PARCIAL (deuda 30000)
EXEC comercial.PagoCanonInsertar @p_id_obligacion = @ob_feb, @p_fecha_pago = '2026-02-09', @p_monto_pagado = 20000.00;
EXEC comercial.ObligacionCanonModificar @p_id_obligacion = @ob_feb, @p_monto_obligado = 50000.00, @p_estado = 'PARCIAL', @p_fecha_vencimiento = '2026-02-10';

PRINT 'OK - 2 pagos de canon registrados.';
PRINT '     Deudores esperados: Febrero ($30000), Marzo ($50000) y Concesión 2 ($30000).';

PRINT '';
PRINT '==============================================================';
PRINT ' PREPARACIÓN 5 — Tickets y detalles (visitas e ingresos por entradas/tours)';
PRINT '    Fechas distribuidas en varios meses y 2 años distintos';
PRINT '    El total de cada ticket es la suma de sus subtotales.';
PRINT '==============================================================';

-- Ticket 1 (REP-0001) total = 214500 (50000+40000+12500+60000+32000+20000)
EXEC ventas.TicketInsertar
    @p_punto_venta = '0001', @p_numero = 'REP-0001',
    @p_fecha_venta = '2026-01-15 10:00:00', @p_id_forma_pago = @id_forma_pago, @p_total = 214500.00;
SELECT @id_ticket1 = id_ticket FROM ventas.Ticket WHERE numero = 'REP-0001';

-- Ticket 2 (REP-0002) total = 263000 (100000+75000+48000+28000+12000)
EXEC ventas.TicketInsertar
    @p_punto_venta = '0001', @p_numero = 'REP-0002',
    @p_fecha_venta = '2026-07-05 09:30:00', @p_id_forma_pago = @id_forma_pago, @p_total = 263000.00;
SELECT @id_ticket2 = id_ticket FROM ventas.Ticket WHERE numero = 'REP-0002';

-- Ticket 3 (REP-0003) total = 57000 (45000+12000)
EXEC ventas.TicketInsertar
    @p_punto_venta = '0002', @p_numero = 'REP-0003',
    @p_fecha_venta = '2025-12-30 11:00:00', @p_id_forma_pago = @id_forma_pago, @p_total = 57000.00;
SELECT @id_ticket3 = id_ticket FROM ventas.Ticket WHERE numero = 'REP-0003';

-- ----- Detalles del Parque 1 (Iguazú): entradas -----
EXEC ventas.TicketDetalleInsertar @p_id_ticket = @id_ticket1, @p_id_parque = @id_parque1, @p_id_historial_precio = @hp_p1_adulto, @p_id_tipo_visitante = @id_tv_adulto, @p_id_atraccion_tour = NULL, @p_fecha_acceso = '2026-01-15', @p_cantidad = 10, @p_precio_unitario = 5000.00, @p_subtotal = 50000.00;
EXEC ventas.TicketDetalleInsertar @p_id_ticket = @id_ticket1, @p_id_parque = @id_parque1, @p_id_historial_precio = @hp_p1_adulto, @p_id_tipo_visitante = @id_tv_adulto, @p_id_atraccion_tour = NULL, @p_fecha_acceso = '2026-02-20', @p_cantidad =  8, @p_precio_unitario = 5000.00, @p_subtotal = 40000.00;
EXEC ventas.TicketDetalleInsertar @p_id_ticket = @id_ticket1, @p_id_parque = @id_parque1, @p_id_historial_precio = @hp_p1_menor,  @p_id_tipo_visitante = @id_tv_menor,  @p_id_atraccion_tour = NULL, @p_fecha_acceso = '2026-02-20', @p_cantidad =  5, @p_precio_unitario = 2500.00, @p_subtotal = 12500.00;
EXEC ventas.TicketDetalleInsertar @p_id_ticket = @id_ticket1, @p_id_parque = @id_parque1, @p_id_historial_precio = @hp_p1_adulto, @p_id_tipo_visitante = @id_tv_adulto, @p_id_atraccion_tour = NULL, @p_fecha_acceso = '2026-03-10', @p_cantidad = 12, @p_precio_unitario = 5000.00, @p_subtotal = 60000.00;
EXEC ventas.TicketDetalleInsertar @p_id_ticket = @id_ticket2, @p_id_parque = @id_parque1, @p_id_historial_precio = @hp_p1_adulto, @p_id_tipo_visitante = @id_tv_adulto, @p_id_atraccion_tour = NULL, @p_fecha_acceso = '2026-07-05', @p_cantidad = 20, @p_precio_unitario = 5000.00, @p_subtotal = 100000.00;
EXEC ventas.TicketDetalleInsertar @p_id_ticket = @id_ticket2, @p_id_parque = @id_parque1, @p_id_historial_precio = @hp_p1_adulto, @p_id_tipo_visitante = @id_tv_adulto, @p_id_atraccion_tour = NULL, @p_fecha_acceso = '2026-12-22', @p_cantidad = 15, @p_precio_unitario = 5000.00, @p_subtotal = 75000.00;
EXEC ventas.TicketDetalleInsertar @p_id_ticket = @id_ticket3, @p_id_parque = @id_parque1, @p_id_historial_precio = @hp_p1_adulto, @p_id_tipo_visitante = @id_tv_adulto, @p_id_atraccion_tour = NULL, @p_fecha_acceso = '2025-07-10', @p_cantidad =  9, @p_precio_unitario = 5000.00, @p_subtotal = 45000.00;

-- ----- Detalles del Parque 1: tours -----
EXEC ventas.TicketDetalleInsertar @p_id_ticket = @id_ticket1, @p_id_parque = @id_parque1, @p_id_historial_precio = NULL, @p_id_tipo_visitante = NULL, @p_id_atraccion_tour = @at_p1, @p_fecha_acceso = '2026-01-16', @p_cantidad = 4, @p_precio_unitario = 8000.00, @p_subtotal = 32000.00;
EXEC ventas.TicketDetalleInsertar @p_id_ticket = @id_ticket2, @p_id_parque = @id_parque1, @p_id_historial_precio = NULL, @p_id_tipo_visitante = NULL, @p_id_atraccion_tour = @at_p1, @p_fecha_acceso = '2026-07-06', @p_cantidad = 6, @p_precio_unitario = 8000.00, @p_subtotal = 48000.00;

-- ----- Detalles del Parque 2 (Nahuel Huapi): entradas -----
EXEC ventas.TicketDetalleInsertar @p_id_ticket = @id_ticket1, @p_id_parque = @id_parque2, @p_id_historial_precio = @hp_p2_adulto, @p_id_tipo_visitante = @id_tv_adulto, @p_id_atraccion_tour = NULL, @p_fecha_acceso = '2026-02-11', @p_cantidad = 5, @p_precio_unitario = 4000.00, @p_subtotal = 20000.00;
EXEC ventas.TicketDetalleInsertar @p_id_ticket = @id_ticket2, @p_id_parque = @id_parque2, @p_id_historial_precio = @hp_p2_adulto, @p_id_tipo_visitante = @id_tv_adulto, @p_id_atraccion_tour = NULL, @p_fecha_acceso = '2026-08-03', @p_cantidad = 7, @p_precio_unitario = 4000.00, @p_subtotal = 28000.00;
EXEC ventas.TicketDetalleInsertar @p_id_ticket = @id_ticket3, @p_id_parque = @id_parque2, @p_id_historial_precio = @hp_p2_adulto, @p_id_tipo_visitante = @id_tv_adulto, @p_id_atraccion_tour = NULL, @p_fecha_acceso = '2025-12-30', @p_cantidad = 3, @p_precio_unitario = 4000.00, @p_subtotal = 12000.00;

-- ----- Detalles del Parque 2: tours -----
EXEC ventas.TicketDetalleInsertar @p_id_ticket = @id_ticket2, @p_id_parque = @id_parque2, @p_id_historial_precio = NULL, @p_id_tipo_visitante = NULL, @p_id_atraccion_tour = @at_p2, @p_fecha_acceso = '2026-08-04', @p_cantidad = 2, @p_precio_unitario = 6000.00, @p_subtotal = 12000.00;

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

PRINT 'OK - Datos de prueba cargados.';
GO

-- ==============================================================
PRINT '';
PRINT '==============================================================';
PRINT ' SECCIÓN 1 — EJECUCIÓN Y PRUEBA DE LOS REPORTES (ENTREGA 7)';
PRINT '==============================================================';
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 1: Reporte de visitas por semana, mes y año, por parque';
PRINT '-------------------------------------------------------------------------';
-- RESULTADO ESPERADO: una fila por parque/año/mes/semana con la cantidad de
-- visitas (suma de cantidades de los TicketDetalle). Debe incluir ambos
-- parques REP-TEST (Iguazú y Nahuel Huapi) y discriminar los accesos de 2025
-- y 2026 cargados en la preparación. El total de visitas debe coincidir con
-- la suma de las cantidades de los 13 detalles insertados.
EXEC dbo.Reporte_Visitas;
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 2: Ingresos por parque por semana, mes y año (Consolidado)';
PRINT '-------------------------------------------------------------------------';
-- RESULTADO ESPERADO: una fila por parque/año/mes/semana con los ingresos
-- discriminados en Entradas, Tours y Concesiones, y el Total_General como su
-- suma. Las entradas/tours provienen de los subtotales de TicketDetalle y las
-- concesiones de los PagoCanon registrados (enero $50000 + febrero $20000 de
-- la Concesión 1). El gran total de entradas+tours debe coincidir con la suma
-- de los subtotales de los 13 detalles.
EXEC dbo.Ingresos_Parque;
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 3: Deudores de Concesiones (Formato XML)';
PRINT '-------------------------------------------------------------------------';
-- RESULTADO ESPERADO: un documento XML con las obligaciones con deuda. Según
-- los datos cargados deben figurar exactamente 3 deudas:
--   - Concesión 1 / Febrero 2026: deuda $30000 (pago parcial de $20000)
--   - Concesión 1 / Marzo 2026:   deuda $50000 (PENDIENTE sin pagos)
--   - Concesión 2 / Enero 2026:   deuda $30000 (VENCIDO sin pagos)
-- NO debe aparecer Enero de la Concesión 1 (quedó PAGADO, deuda 0).
EXEC dbo.Deudores_XML;
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 4: Matriz de visitas (Tabla Cruzada / Pivot de meses)';
PRINT '-------------------------------------------------------------------------';
-- RESULTADO ESPERADO: una tabla cruzada (pivot) con una fila por parque y una
-- columna por mes (Enero..Diciembre), donde cada celda es la cantidad de
-- visitas de ese parque en ese mes. Los meses sin accesos deben mostrar 0 (o
-- NULL según la implementación). La suma de toda la matriz debe coincidir con
-- el total de visitas del Test 1.
EXEC dbo.Matriz_Visitas;
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 5: Parques y Concesiones (Formato XML Anidado)';
PRINT '-------------------------------------------------------------------------';
-- RESULTADO ESPERADO: un XML anidado con cada parque y, dentro, sus
-- concesiones. Para los datos REP-TEST: el Parque 1 (Iguazú) con la concesión
-- "Gastronomía REP-TEST" y el Parque 2 (Nahuel Huapi) con "Alquiler de kayaks
-- REP-TEST". Cada parque debe anidar su(s) concesión(es) como elementos hijos.
EXEC dbo.Parques_Concesiones_XML;
GO

-- ==============================================================
PRINT '';
PRINT '==============================================================';
PRINT ' SECCIÓN 2 — LIMPIEZA DE DATOS DE TESTING';
PRINT '==============================================================';

SET NOCOUNT ON;

-- Limpieza vía Store Procedures de baja, en orden hijo -> padre.
-- Como hay varias filas por tabla, se itera llamando al SP por cada ID.
DECLARE @id INT;

-- TicketDetalle (detalles de los tickets REP-%)
WHILE EXISTS (SELECT 1 FROM ventas.TicketDetalle td JOIN ventas.Ticket t ON t.id_ticket = td.id_ticket WHERE t.numero LIKE 'REP-%')
BEGIN
    SELECT TOP 1 @id = td.id_detalle FROM ventas.TicketDetalle td JOIN ventas.Ticket t ON t.id_ticket = td.id_ticket WHERE t.numero LIKE 'REP-%';
    EXEC ventas.TicketDetalleEliminar @p_id_detalle = @id;
END

-- Ticket
WHILE EXISTS (SELECT 1 FROM ventas.Ticket WHERE numero LIKE 'REP-%')
BEGIN
    SELECT TOP 1 @id = id_ticket FROM ventas.Ticket WHERE numero LIKE 'REP-%';
    EXEC ventas.TicketEliminar @p_id_ticket = @id;
END

-- PagoCanon (pagos de obligaciones de concesiones REP-TEST)
WHILE EXISTS (SELECT 1 FROM comercial.PagoCanon pc JOIN comercial.ObligacionCanon oc ON oc.id_obligacion = pc.id_obligacion JOIN comercial.Concesion c ON c.id_concesion = oc.id_concesion WHERE c.tipo_actividad LIKE '%REP-TEST')
BEGIN
    SELECT TOP 1 @id = pc.id_pago FROM comercial.PagoCanon pc JOIN comercial.ObligacionCanon oc ON oc.id_obligacion = pc.id_obligacion JOIN comercial.Concesion c ON c.id_concesion = oc.id_concesion WHERE c.tipo_actividad LIKE '%REP-TEST';
    EXEC comercial.PagoCanonEliminar @p_id_pago = @id;
END

-- ObligacionCanon
WHILE EXISTS (SELECT 1 FROM comercial.ObligacionCanon oc JOIN comercial.Concesion c ON c.id_concesion = oc.id_concesion WHERE c.tipo_actividad LIKE '%REP-TEST')
BEGIN
    SELECT TOP 1 @id = oc.id_obligacion FROM comercial.ObligacionCanon oc JOIN comercial.Concesion c ON c.id_concesion = oc.id_concesion WHERE c.tipo_actividad LIKE '%REP-TEST';
    EXEC comercial.ObligacionCanonEliminar @p_id_obligacion = @id;
END

-- Concesion
WHILE EXISTS (SELECT 1 FROM comercial.Concesion WHERE tipo_actividad LIKE '%REP-TEST')
BEGIN
    SELECT TOP 1 @id = id_concesion FROM comercial.Concesion WHERE tipo_actividad LIKE '%REP-TEST';
    EXEC comercial.ConcesionEliminar @p_id_concesion = @id;
END

-- HistorialPrecio (de los parques PN-REP%)
WHILE EXISTS (SELECT 1 FROM ventas.HistorialPrecio hp JOIN parques.Parque p ON p.id_parque = hp.id_parque WHERE p.codigo_oficial LIKE 'PN-REP%')
BEGIN
    SELECT TOP 1 @id = hp.id_historial_precio FROM ventas.HistorialPrecio hp JOIN parques.Parque p ON p.id_parque = hp.id_parque WHERE p.codigo_oficial LIKE 'PN-REP%';
    EXEC ventas.HistorialPrecioEliminar @p_id_historial_precio = @id;
END

-- AtraccionTour
WHILE EXISTS (SELECT 1 FROM turismo.AtraccionTour WHERE nombre LIKE '%REP-TEST')
BEGIN
    SELECT TOP 1 @id = id_atraccion_tour FROM turismo.AtraccionTour WHERE nombre LIKE '%REP-TEST';
    EXEC turismo.AtraccionTourEliminar @p_id_atraccion_tour = @id;
END

-- Parque
WHILE EXISTS (SELECT 1 FROM parques.Parque WHERE codigo_oficial LIKE 'PN-REP%')
BEGIN
    SELECT TOP 1 @id = id_parque FROM parques.Parque WHERE codigo_oficial LIKE 'PN-REP%';
    EXEC parques.ParqueEliminar @p_id_parque = @id;
END

-- Empresa
WHILE EXISTS (SELECT 1 FROM comercial.Empresa WHERE cuit IN ('30700000011', '30700000022'))
BEGIN
    SELECT TOP 1 @id = id_empresa FROM comercial.Empresa WHERE cuit IN ('30700000011', '30700000022');
    EXEC comercial.EmpresaEliminar @p_id_empresa = @id;
END

-- TipoParque
WHILE EXISTS (SELECT 1 FROM parques.TipoParque WHERE descripcion LIKE '%REP-TEST')
BEGIN
    SELECT TOP 1 @id = id_tipo_parque FROM parques.TipoParque WHERE descripcion LIKE '%REP-TEST';
    EXEC parques.TipoParqueEliminar @p_id_tipo_parque = @id;
END

-- TipoVisitante
WHILE EXISTS (SELECT 1 FROM ventas.TipoVisitante WHERE descripcion LIKE '%REP-TEST')
BEGIN
    SELECT TOP 1 @id = id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion LIKE '%REP-TEST';
    EXEC ventas.TipoVisitanteEliminar @p_id_tipo_visitante = @id;
END

-- FormaPago
WHILE EXISTS (SELECT 1 FROM ventas.FormaPago WHERE descripcion LIKE '%REP-TEST')
BEGIN
    SELECT TOP 1 @id = id_forma_pago FROM ventas.FormaPago WHERE descripcion LIKE '%REP-TEST';
    EXEC ventas.FormaPagoEliminar @p_id_forma_pago = @id;
END

-- TipoAtraccion
WHILE EXISTS (SELECT 1 FROM turismo.TipoAtraccion WHERE descripcion LIKE '%REP-TEST')
BEGIN
    SELECT TOP 1 @id = id_tipo_atraccion FROM turismo.TipoAtraccion WHERE descripcion LIKE '%REP-TEST';
    EXEC turismo.TipoAtraccionEliminar @p_id_tipo_atraccion = @id;
END

PRINT 'OK - Datos de testing eliminados (vía SPs de baja).';

-- Verificar limpieza
SELECT CASE WHEN COUNT(*) = 0 THEN 'OK - Sin parques REP-TEST residuales'
            ELSE 'ATENCIÓN - Quedan ' + CAST(COUNT(*) AS VARCHAR) + ' parques' END AS resultado
FROM parques.Parque WHERE codigo_oficial LIKE 'PN-REP%';

SELECT CASE WHEN COUNT(*) = 0 THEN 'OK - Sin tickets REP-TEST residuales'
            ELSE 'ATENCIÓN - Quedan ' + CAST(COUNT(*) AS VARCHAR) + ' tickets' END AS resultado
FROM ventas.Ticket WHERE numero LIKE 'REP-%';

SELECT CASE WHEN COUNT(*) = 0 THEN 'OK - Sin concesiones REP-TEST residuales'
            ELSE 'ATENCIÓN - Quedan ' + CAST(COUNT(*) AS VARCHAR) + ' concesiones' END AS resultado
FROM comercial.Concesion WHERE tipo_actividad LIKE '%REP-TEST';

GO

PRINT '';
PRINT '==============================================================';
PRINT ' Testing de Reportes completado.';
PRINT '==============================================================';
