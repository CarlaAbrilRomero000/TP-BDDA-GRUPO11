/*
==============================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Fecha:       09/06/2026
Descripción: Script de testing para los SP ABM.
             Cubre casos exitosos con evidencia (SELECT) y
             casos de error que demuestran el comportamiento
             de las validaciones.

             Orden de ejecución:
               1. ScriptCreacionTablasYSchemas.sql
               2. ScriptABM_SPs.sql
               3. Este script
==============================================================
*/

USE ParquesNacionalesDB;
GO

-- ==============================================================
-- Variables de soporte para capturar IDs generados
-- ==============================================================
DECLARE
    @id_tipo_parque      INT,
    @id_tipo_visitante   INT,
    @id_forma_pago       INT,
    @id_tipo_atraccion   INT,
    @id_guardaparque     INT,
    @id_guia             INT,
    @id_parque           INT,
    @id_empresa          INT,
    @id_historial_gp     INT,
    @id_atraccion_tour   INT,
    @id_historial_precio INT,
    @id_concesion        INT,
    @id_obligacion       INT,
    @id_pago             INT,
    @id_ticket           INT,
    @id_detalle          INT;

PRINT '==============================================================';
PRINT ' SECCIÓN 1 — ALTAS EXITOSAS (casos exitosos)';
PRINT '==============================================================';

-- ---------------------------------------------------------------
PRINT '--- TEST A-01: Insertar TipoParque ---';
-- ---------------------------------------------------------------
EXEC parques.TipoParqueInsertar @p_descripcion = 'Parque Nacional TEST';
SELECT @id_tipo_parque = id_tipo_parque
FROM parques.TipoParque WHERE descripcion = 'Parque Nacional TEST';
PRINT 'OK — TipoParque insertado. ID: ' + CAST(@id_tipo_parque AS VARCHAR(10));

-- ---------------------------------------------------------------
PRINT '--- TEST A-02: Insertar TipoVisitante ---';
-- ---------------------------------------------------------------
EXEC ventas.TipoVisitanteInsertar @p_descripcion = 'Adulto TEST';
SELECT @id_tipo_visitante = id_tipo_visitante
FROM ventas.TipoVisitante WHERE descripcion = 'Adulto TEST';
PRINT 'OK — TipoVisitante insertado. ID: ' + CAST(@id_tipo_visitante AS VARCHAR(10));

-- ---------------------------------------------------------------
PRINT '--- TEST A-03: Insertar FormaPago ---';
-- ---------------------------------------------------------------
EXEC ventas.FormaPagoInsertar @p_descripcion = 'Efectivo TEST';
SELECT @id_forma_pago = id_forma_pago
FROM ventas.FormaPago WHERE descripcion = 'Efectivo TEST';
PRINT 'OK — FormaPago insertado. ID: ' + CAST(@id_forma_pago AS VARCHAR(10));

-- ---------------------------------------------------------------
PRINT '--- TEST A-04: Insertar TipoAtraccion ---';
-- ---------------------------------------------------------------
EXEC turismo.TipoAtraccionInsertar @p_descripcion = 'Senderismo TEST';
SELECT @id_tipo_atraccion = id_tipo_atraccion
FROM turismo.TipoAtraccion WHERE descripcion = 'Senderismo TEST';
PRINT 'OK — TipoAtraccion insertado. ID: ' + CAST(@id_tipo_atraccion AS VARCHAR(10));

-- ---------------------------------------------------------------
PRINT '--- TEST A-05: Insertar Guardaparque ---';
-- ---------------------------------------------------------------
EXEC personal.GuardaparqueInsertar
    @p_nombre   = 'Laura',
    @p_apellido = 'Ríos',
    @p_dni      = '30111222',
    @p_email    = 'laura.rios@test.com',
    @p_telefono = '011-1234-5678';
SELECT @id_guardaparque = id_guardaparque
FROM personal.Guardaparque WHERE dni = '30111222';
PRINT 'OK — Guardaparque insertado. ID: ' + CAST(@id_guardaparque AS VARCHAR(10));

-- ---------------------------------------------------------------
PRINT '--- TEST A-06: Insertar Guia ---';
-- ---------------------------------------------------------------
EXEC turismo.GuiaInsertar
    @p_nombre                = 'Carlos',
    @p_apellido              = 'Vera',
    @p_dni                   = '28999888',
    @p_especialidad          = 'Flora nativa',
    @p_vigencia_autorizacion = '2027-12-31';
SELECT @id_guia = id_guia FROM turismo.Guia WHERE dni = '28999888';
PRINT 'OK — Guia insertado. ID: ' + CAST(@id_guia AS VARCHAR(10));

-- ---------------------------------------------------------------
PRINT '--- TEST A-07: Insertar Parque ---';
-- ---------------------------------------------------------------
EXEC parques.ParqueInsertar
    @p_codigo_oficial = 'PN-TEST-01',
    @p_nombre         = 'Parque Las Pruebas',
    @p_ubicacion      = 'Provincia de Testing, Argentina',
    @p_superficie     = 12500.75,
    @p_id_tipo_parque = @id_tipo_parque;
SELECT @id_parque = id_parque FROM parques.Parque WHERE codigo_oficial = 'PN-TEST-01';
PRINT 'OK — Parque insertado. ID: ' + CAST(@id_parque AS VARCHAR(10));

-- ---------------------------------------------------------------
PRINT '--- TEST A-08: Insertar Empresa ---';
-- ---------------------------------------------------------------
EXEC comercial.EmpresaInsertar
    @p_cuit         = '30123456789',
    @p_razon_social = 'Servicios Patagónicos S.A. TEST',
    @p_telefono     = '0299-555-0000',
    @p_email        = 'contacto@servpat.test',
    @p_direccion    = 'Av. Principal 100, Neuquén';
SELECT @id_empresa = id_empresa FROM comercial.Empresa WHERE cuit = '30123456789';
PRINT 'OK — Empresa insertada. ID: ' + CAST(@id_empresa AS VARCHAR(10));

-- ---------------------------------------------------------------
PRINT '--- TEST A-09: Insertar HistorialGuardaparque ---';
-- ---------------------------------------------------------------
EXEC personal.HistorialGuardaparqueInsertar
    @p_id_guardaparque = @id_guardaparque,
    @p_id_parque       = @id_parque,
    @p_fecha_ingreso   = '2025-01-01';
SELECT @id_historial_gp = id_historial
FROM personal.HistorialGuardaparque
WHERE id_guardaparque = @id_guardaparque AND id_parque = @id_parque AND fecha_egreso IS NULL;
PRINT 'OK — HistorialGuardaparque insertado. ID: ' + CAST(@id_historial_gp AS VARCHAR(10));

-- ---------------------------------------------------------------
PRINT '--- TEST A-10: Insertar GuiaParque ---';
-- ---------------------------------------------------------------
EXEC turismo.GuiaParqueInsertar
    @p_id_guia            = @id_guia,
    @p_id_parque          = @id_parque,
    @p_fecha_autorizacion = '2025-03-01',
    @p_estado_autorizacion = 1;
PRINT 'OK — GuiaParque insertado (guía habilitado en el parque).';

-- ---------------------------------------------------------------
PRINT '--- TEST A-11: Insertar AtraccionTour ---';
-- ---------------------------------------------------------------
EXEC turismo.AtraccionTourInsertar
    @p_id_parque         = @id_parque,
    @p_id_tipo_atraccion = @id_tipo_atraccion,
    @p_nombre            = 'Tour Sendero del Cóndor TEST',
    @p_costo             = 1500.00,
    @p_cupo_maximo       = 20,
    @p_duracion          = 180;
SELECT @id_atraccion_tour = id_atraccion_tour
FROM turismo.AtraccionTour WHERE nombre = 'Tour Sendero del Cóndor TEST';
PRINT 'OK — AtraccionTour insertado. ID: ' + CAST(@id_atraccion_tour AS VARCHAR(10));

-- ---------------------------------------------------------------
PRINT '--- TEST A-12: Insertar TourGuia ---';
-- ---------------------------------------------------------------
EXEC turismo.TourGuiaInsertar
    @p_id_atraccion_tour = @id_atraccion_tour,
    @p_id_guia           = @id_guia;
PRINT 'OK — TourGuia insertado (guía asignado al tour).';

-- ---------------------------------------------------------------
PRINT '--- TEST A-13: Insertar HistorialPrecio ---';
-- ---------------------------------------------------------------
EXEC ventas.HistorialPrecioInsertar
    @p_precio            = 3200.00,
    @p_fecha_desde       = '2025-01-01',
    @p_id_parque         = @id_parque,
    @p_id_tipo_visitante = @id_tipo_visitante;
SELECT @id_historial_precio = id_historial_precio
FROM ventas.HistorialPrecio
WHERE id_parque = @id_parque AND id_tipo_visitante = @id_tipo_visitante;
PRINT 'OK — HistorialPrecio insertado. ID: ' + CAST(@id_historial_precio AS VARCHAR(10));

-- ---------------------------------------------------------------
PRINT '--- TEST A-14: Insertar Concesion ---';
-- ---------------------------------------------------------------
EXEC comercial.ConcesionInsertar
    @p_id_parque      = @id_parque,
    @p_id_empresa     = @id_empresa,
    @p_tipo_actividad = 'Restauración y gastronomía TEST',
    @p_fecha_inicio   = '2025-01-01',
    @p_fecha_fin      = '2025-06-30',
    @p_canon_mensual  = 85000.00;
SELECT @id_concesion = id_concesion
FROM comercial.Concesion
WHERE id_parque = @id_parque AND id_empresa = @id_empresa AND tipo_actividad = 'Restauración y gastronomía TEST';
PRINT 'OK — Concesion insertada. ID: ' + CAST(@id_concesion AS VARCHAR(10));

-- ---------------------------------------------------------------
PRINT '--- TEST A-15: Insertar ObligacionCanon ---';
-- ---------------------------------------------------------------
EXEC comercial.ObligacionCanonInsertar
    @p_id_concesion      = @id_concesion,
    @p_mes               = 7,
    @p_anio              = 2025,
    @p_monto_obligado    = 85000.00,
    @p_estado            = 'PENDIENTE',
    @p_fecha_vencimiento = '2025-08-10';
SELECT @id_obligacion = id_obligacion
FROM comercial.ObligacionCanon
WHERE id_concesion = @id_concesion AND mes = 7 AND anio = 2025;
PRINT 'OK — ObligacionCanon insertada. ID: ' + CAST(@id_obligacion AS VARCHAR(10));

-- ---------------------------------------------------------------
PRINT '--- TEST A-16: Insertar PagoCanon ---';
-- ---------------------------------------------------------------
EXEC comercial.PagoCanonInsertar
    @p_id_obligacion = @id_obligacion,
    @p_fecha_pago    = '2025-07-28',
    @p_monto_pagado  = 85000.00;
SELECT @id_pago = id_pago
FROM comercial.PagoCanon WHERE id_obligacion = @id_obligacion;
PRINT 'OK — PagoCanon insertado. ID: ' + CAST(@id_pago AS VARCHAR(10));

-- ---------------------------------------------------------------
PRINT '--- TEST A-17: Insertar Ticket ---';
-- ---------------------------------------------------------------
EXEC ventas.TicketInsertar
    @p_punto_venta   = '0001',
    @p_numero        = '00000001',
    @p_fecha_venta   = '2025-09-15 10:30:00',
    @p_id_forma_pago = @id_forma_pago,
    @p_total         = 6400.00;
SELECT @id_ticket = id_ticket
FROM ventas.Ticket WHERE punto_venta = '0001' AND numero = '00000001';
PRINT 'OK — Ticket insertado. ID: ' + CAST(@id_ticket AS VARCHAR(10));

-- ---------------------------------------------------------------
PRINT '--- TEST A-18: Insertar TicketDetalle ---';
-- ---------------------------------------------------------------
EXEC ventas.TicketDetalleInsertar
    @p_id_ticket           = @id_ticket,
    @p_id_parque           = @id_parque,
    @p_id_historial_precio = @id_historial_precio,
    @p_id_tipo_visitante   = @id_tipo_visitante,
    @p_id_atraccion_tour   = NULL,
    @p_fecha_acceso        = '2025-09-16',
    @p_cantidad            = 2,
    @p_precio_unitario     = 3200.00,
    @p_subtotal            = 6400.00;
SELECT @id_detalle = id_detalle
FROM ventas.TicketDetalle WHERE id_ticket = @id_ticket;
PRINT 'OK — TicketDetalle insertado. ID: ' + CAST(@id_detalle AS VARCHAR(10));

GO

-- ==============================================================
PRINT '';
PRINT '==============================================================';
PRINT ' SECCIÓN 2 — EVIDENCIA: CONSULTAS DE DATOS INSERTADOS';
PRINT '==============================================================';

SELECT 'TipoParque' AS tabla, id_tipo_parque AS id, descripcion AS detalle
FROM parques.TipoParque WHERE descripcion = 'Parque Nacional TEST';

SELECT 'TipoVisitante' AS tabla, id_tipo_visitante AS id, descripcion AS detalle
FROM ventas.TipoVisitante WHERE descripcion = 'Adulto TEST';

SELECT 'FormaPago' AS tabla, id_forma_pago AS id, descripcion AS detalle
FROM ventas.FormaPago WHERE descripcion = 'Efectivo TEST';

SELECT 'TipoAtraccion' AS tabla, id_tipo_atraccion AS id, descripcion AS detalle
FROM turismo.TipoAtraccion WHERE descripcion = 'Senderismo TEST';

SELECT 'Guardaparque' AS tabla, id_guardaparque AS id, nombre + ' ' + apellido AS detalle, activo
FROM personal.Guardaparque WHERE dni = '30111222';

SELECT 'Guia' AS tabla, id_guia AS id, nombre + ' ' + apellido AS detalle, vigencia_autorizacion
FROM turismo.Guia WHERE dni = '28999888';

SELECT 'Parque' AS tabla, id_parque AS id, nombre AS detalle, superficie
FROM parques.Parque WHERE codigo_oficial = 'PN-TEST-01';

SELECT 'Empresa' AS tabla, id_empresa AS id, razon_social AS detalle, cuit
FROM comercial.Empresa WHERE cuit = '30123456789';

SELECT 'HistorialGuardaparque' AS tabla,
       hg.id_historial AS id,
       g.nombre + ' ' + g.apellido AS guardaparque,
       p.nombre AS parque,
       hg.fecha_ingreso,
       hg.fecha_egreso
FROM personal.HistorialGuardaparque hg
JOIN personal.Guardaparque g ON g.id_guardaparque = hg.id_guardaparque
JOIN parques.Parque p ON p.id_parque = hg.id_parque
WHERE g.dni = '30111222';

SELECT 'GuiaParque' AS tabla,
       gp.id_guia, g.nombre + ' ' + g.apellido AS guia,
       p.nombre AS parque,
       gp.fecha_autorizacion,
       gp.estado_autorizacion
FROM turismo.GuiaParque gp
JOIN turismo.Guia g ON g.id_guia = gp.id_guia
JOIN parques.Parque p ON p.id_parque = gp.id_parque
WHERE g.dni = '28999888';

SELECT 'AtraccionTour' AS tabla,
       at.id_atraccion_tour AS id, at.nombre, at.costo, at.cupo_maximo, at.duracion
FROM turismo.AtraccionTour at
WHERE at.nombre = 'Tour Sendero del Cóndor TEST';

SELECT 'TourGuia' AS tabla,
       tg.id_atraccion_tour, at.nombre AS tour,
       g.nombre + ' ' + g.apellido AS guia
FROM turismo.TourGuia tg
JOIN turismo.AtraccionTour at ON at.id_atraccion_tour = tg.id_atraccion_tour
JOIN turismo.Guia g ON g.id_guia = tg.id_guia
WHERE at.nombre = 'Tour Sendero del Cóndor TEST';

SELECT 'HistorialPrecio' AS tabla,
       hp.id_historial_precio AS id, hp.precio, hp.fecha_desde,
       p.nombre AS parque, tv.descripcion AS tipo_visitante
FROM ventas.HistorialPrecio hp
JOIN parques.Parque p ON p.id_parque = hp.id_parque
JOIN ventas.TipoVisitante tv ON tv.id_tipo_visitante = hp.id_tipo_visitante
WHERE p.codigo_oficial = 'PN-TEST-01';

SELECT 'Concesion' AS tabla,
       c.id_concesion AS id, e.razon_social AS empresa,
       c.tipo_actividad, c.fecha_inicio, c.fecha_fin, c.canon_mensual
FROM comercial.Concesion c
JOIN comercial.Empresa e ON e.id_empresa = c.id_empresa
WHERE c.tipo_actividad = 'Restauración y gastronomía TEST';

SELECT 'ObligacionCanon' AS tabla,
       oc.id_obligacion AS id, oc.mes, oc.anio,
       oc.monto_obligado, oc.estado, oc.fecha_vencimiento
FROM comercial.ObligacionCanon oc
WHERE oc.mes = 7 AND oc.anio = 2025;

SELECT 'PagoCanon' AS tabla,
       pc.id_pago AS id, pc.fecha_pago, pc.monto_pagado,
       oc.estado AS estado_obligacion
FROM comercial.PagoCanon pc
JOIN comercial.ObligacionCanon oc ON oc.id_obligacion = pc.id_obligacion
WHERE oc.mes = 7 AND oc.anio = 2025;

SELECT 'Ticket' AS tabla,
       t.id_ticket AS id, t.punto_venta, t.numero,
       t.fecha_venta, t.total, fp.descripcion AS forma_pago
FROM ventas.Ticket t
JOIN ventas.FormaPago fp ON fp.id_forma_pago = t.id_forma_pago
WHERE t.punto_venta = '0001' AND t.numero = '00000001';

SELECT 'TicketDetalle' AS tabla,
       td.id_detalle AS id, td.cantidad, td.precio_unitario,
       td.subtotal, td.fecha_acceso
FROM ventas.TicketDetalle td
JOIN ventas.Ticket t ON t.id_ticket = td.id_ticket
WHERE t.punto_venta = '0001' AND t.numero = '00000001';

GO

-- ==============================================================
PRINT '';
PRINT '==============================================================';
PRINT ' SECCIÓN 3 — MODIFICACIONES EXITOSAS';
PRINT '==============================================================';

DECLARE @id_tipo_parque    INT, @id_tipo_visitante INT, @id_forma_pago    INT,
        @id_tipo_atraccion INT, @id_guardaparque   INT, @id_guia          INT,
        @id_parque         INT, @id_empresa        INT, @id_historial_gp  INT,
        @id_atraccion_tour INT, @id_historial_precio INT, @id_concesion   INT,
        @id_obligacion     INT, @id_ticket          INT, @id_detalle       INT;

SELECT @id_tipo_parque     = id_tipo_parque    FROM parques.TipoParque   WHERE descripcion      = 'Parque Nacional TEST';
SELECT @id_tipo_visitante  = id_tipo_visitante FROM ventas.TipoVisitante WHERE descripcion      = 'Adulto TEST';
SELECT @id_forma_pago      = id_forma_pago     FROM ventas.FormaPago     WHERE descripcion      = 'Efectivo TEST';
SELECT @id_tipo_atraccion  = id_tipo_atraccion FROM turismo.TipoAtraccion WHERE descripcion     = 'Senderismo TEST';
SELECT @id_guardaparque    = id_guardaparque   FROM personal.Guardaparque WHERE dni             = '30111222';
SELECT @id_guia            = id_guia           FROM turismo.Guia          WHERE dni             = '28999888';
SELECT @id_parque          = id_parque         FROM parques.Parque        WHERE codigo_oficial  = 'PN-TEST-01';
SELECT @id_empresa         = id_empresa        FROM comercial.Empresa     WHERE cuit            = '30123456789';
SELECT @id_historial_gp    = id_historial      FROM personal.HistorialGuardaparque
                             WHERE id_guardaparque = @id_guardaparque AND fecha_egreso IS NULL;
SELECT @id_atraccion_tour  = id_atraccion_tour FROM turismo.AtraccionTour WHERE nombre = 'Tour Sendero del Cóndor TEST';
SELECT @id_historial_precio = id_historial_precio FROM ventas.HistorialPrecio
                              WHERE id_parque = @id_parque AND id_tipo_visitante = @id_tipo_visitante;
SELECT @id_concesion       = id_concesion     FROM comercial.Concesion
                             WHERE tipo_actividad = 'Restauración y gastronomía TEST';
SELECT @id_obligacion      = id_obligacion    FROM comercial.ObligacionCanon
                             WHERE id_concesion = @id_concesion AND mes = 7 AND anio = 2025;
SELECT @id_ticket          = id_ticket        FROM ventas.Ticket WHERE punto_venta = '0001' AND numero = '00000001';
SELECT @id_detalle         = id_detalle       FROM ventas.TicketDetalle WHERE id_ticket = @id_ticket;

-- ---------------------------------------------------------------
PRINT '--- TEST M-01: Modificar TipoParque ---';
EXEC parques.TipoParqueModificar
    @p_id_tipo_parque = @id_tipo_parque,
    @p_descripcion    = 'Parque Nacional TEST (mod)';
PRINT 'OK — TipoParque modificado.';

-- ---------------------------------------------------------------
PRINT '--- TEST M-02: Modificar TipoVisitante ---';
EXEC ventas.TipoVisitanteModificar
    @p_id_tipo_visitante = @id_tipo_visitante,
    @p_descripcion       = 'Adulto TEST (mod)';
PRINT 'OK — TipoVisitante modificado.';

-- ---------------------------------------------------------------
PRINT '--- TEST M-03: Modificar Guardaparque ---';
EXEC personal.GuardaparqueModificar
    @p_id_guardaparque = @id_guardaparque,
    @p_nombre          = 'Laura',
    @p_apellido        = 'Ríos Gómez',
    @p_dni             = '30111222',
    @p_email           = 'laura.rios.gomez@test.com',
    @p_telefono        = '011-9999-8888';
PRINT 'OK — Guardaparque modificado.';

-- ---------------------------------------------------------------
PRINT '--- TEST M-04: Modificar GuiaParque (desactivar) ---';
EXEC turismo.GuiaParqueModificar
    @p_id_guia             = @id_guia,
    @p_id_parque           = @id_parque,
    @p_fecha_autorizacion  = '2025-03-01',
    @p_estado_autorizacion = 0;
PRINT 'OK — GuiaParque desactivado.';

-- Reactivar para no romper los tests siguientes
EXEC turismo.GuiaParqueModificar
    @p_id_guia             = @id_guia,
    @p_id_parque           = @id_parque,
    @p_fecha_autorizacion  = '2025-03-01',
    @p_estado_autorizacion = 1;
PRINT 'OK — GuiaParque reactivado.';

-- ---------------------------------------------------------------
PRINT '--- TEST M-05: Modificar Parque ---';
EXEC parques.ParqueModificar
    @p_id_parque      = @id_parque,
    @p_codigo_oficial = 'PN-TEST-01',
    @p_nombre         = 'Parque Las Pruebas (mod)',
    @p_ubicacion      = 'Provincia de Testing, Argentina',
    @p_superficie     = 13000.00,
    @p_id_tipo_parque = @id_tipo_parque;
PRINT 'OK — Parque modificado.';

-- ---------------------------------------------------------------
PRINT '--- TEST M-06: Modificar HistorialGuardaparque (cerrar período) ---';
EXEC personal.HistorialGuardaparqueModificar
    @p_id_historial  = @id_historial_gp,
    @p_fecha_egreso  = '2025-12-31',
    @p_motivo_egreso = 'Finalización de período de prueba';
PRINT 'OK — HistorialGuardaparque: período cerrado.';

-- ---------------------------------------------------------------
PRINT '--- TEST M-07: Modificar AtraccionTour ---';
EXEC turismo.AtraccionTourModificar
    @p_id_atraccion_tour = @id_atraccion_tour,
    @p_id_tipo_atraccion = @id_tipo_atraccion,
    @p_nombre            = 'Tour Sendero del Cóndor TEST (mod)',
    @p_costo             = 1800.00,
    @p_cupo_maximo       = 25,
    @p_duracion          = 200;
PRINT 'OK — AtraccionTour modificado.';

-- ---------------------------------------------------------------
PRINT '--- TEST M-08: Modificar ObligacionCanon ---';
EXEC comercial.ObligacionCanonModificar
    @p_id_obligacion     = @id_obligacion,
    @p_monto_obligado    = 87000.00,
    @p_estado            = 'PARCIAL',
    @p_fecha_vencimiento = '2025-08-15';
PRINT 'OK — ObligacionCanon modificada.';

-- ---------------------------------------------------------------
PRINT '--- TEST M-09: Modificar Ticket ---';
EXEC ventas.TicketModificar
    @p_id_ticket     = @id_ticket,
    @p_id_forma_pago = @id_forma_pago,
    @p_total         = 6400.00;
PRINT 'OK — Ticket modificado.';

-- ---------------------------------------------------------------
PRINT '--- TEST M-10: Modificar TicketDetalle ---';
EXEC ventas.TicketDetalleModificar
    @p_id_detalle      = @id_detalle,
    @p_cantidad        = 2,
    @p_precio_unitario = 3200.00,
    @p_subtotal        = 6400.00;
PRINT 'OK — TicketDetalle modificado.';

-- Evidencia de modificaciones
SELECT 'Parque (mod)' AS tabla, nombre, superficie FROM parques.Parque WHERE codigo_oficial = 'PN-TEST-01';
SELECT 'Guardaparque (mod)' AS tabla, nombre, apellido, email FROM personal.Guardaparque WHERE dni = '30111222';
SELECT 'HistorialGuardaparque (cerrado)' AS tabla, fecha_egreso, motivo_egreso
FROM personal.HistorialGuardaparque WHERE id_historial = @id_historial_gp;
SELECT 'ObligacionCanon (mod)' AS tabla, monto_obligado, estado, fecha_vencimiento
FROM comercial.ObligacionCanon WHERE id_obligacion = @id_obligacion;

GO

-- ==============================================================
PRINT '';
PRINT '==============================================================';
PRINT ' SECCIÓN 4 — TESTS DE VALIDACIÓN (deben generar errores)';
PRINT '==============================================================';
PRINT 'Cada test espera recibir un error. Si el bloque CATCH no';
PRINT 'ejecuta, la validación falla.';

-- ---------------------------------------------------------------
PRINT '';
PRINT '--- TEST V-01: TipoParque — descripción vacía ---';
BEGIN TRY
    EXEC parques.TipoParqueInsertar @p_descripcion = '';
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '--- TEST V-02: TipoParque — descripción duplicada ---';
BEGIN TRY
    EXEC parques.TipoParqueInsertar @p_descripcion = 'Parque Nacional TEST (mod)';
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '--- TEST V-03: Guardaparque — DNI duplicado ---';
BEGIN TRY
    EXEC personal.GuardaparqueInsertar
        @p_nombre   = 'Pedro',
        @p_apellido = 'Duplicado',
        @p_dni      = '30111222',  -- DNI ya registrado
        @p_email    = NULL,
        @p_telefono = NULL;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '--- TEST V-04: Guardaparque — formato email inválido ---';
BEGIN TRY
    EXEC personal.GuardaparqueInsertar
        @p_nombre   = 'Ana',
        @p_apellido = 'López',
        @p_dni      = '41000001',
        @p_email    = 'correo-invalido-sin-arroba',
        @p_telefono = NULL;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '--- TEST V-05: Empresa — CUIT con letras ---';
BEGIN TRY
    EXEC comercial.EmpresaInsertar
        @p_cuit         = '3012345678A',  -- carácter no numérico
        @p_razon_social = 'Empresa inválida S.A.',
        @p_telefono     = NULL,
        @p_email        = NULL,
        @p_direccion    = NULL;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '--- TEST V-06: Parque — superficie negativa ---';
DECLARE @tp INT;
SELECT @tp = id_tipo_parque FROM parques.TipoParque WHERE descripcion = 'Parque Nacional TEST (mod)';
BEGIN TRY
    EXEC parques.ParqueInsertar
        @p_codigo_oficial = 'PN-BAD-01',
        @p_nombre         = 'Parque Inválido',
        @p_ubicacion      = 'Ningún lugar',
        @p_superficie     = -100,
        @p_id_tipo_parque = @tp;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '--- TEST V-07: Parque — tipo de parque inexistente ---';
BEGIN TRY
    EXEC parques.ParqueInsertar
        @p_codigo_oficial = 'PN-BAD-02',
        @p_nombre         = 'Parque FK Error',
        @p_ubicacion      = 'Ningún lugar',
        @p_superficie     = 5000,
        @p_id_tipo_parque = 999999;  -- ID que no existe
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '--- TEST V-08: HistorialGuardaparque — período activo duplicado ---';
DECLARE @gp INT, @p INT;
SELECT @gp = id_guardaparque FROM personal.Guardaparque WHERE dni = '30111222';
SELECT @p  = id_parque       FROM parques.Parque WHERE codigo_oficial = 'PN-TEST-01';
-- Primero abrimos un nuevo período (el anterior fue cerrado en la sección modificaciones)
EXEC personal.HistorialGuardaparqueInsertar
    @p_id_guardaparque = @gp,
    @p_id_parque       = @p,
    @p_fecha_ingreso   = '2026-01-01';
PRINT 'Período activo reabierto para el test.';
BEGIN TRY
    -- Intentar abrir otro período cuando ya hay uno abierto
    EXEC personal.HistorialGuardaparqueInsertar
        @p_id_guardaparque = @gp,
        @p_id_parque       = @p,
        @p_fecha_ingreso   = '2026-02-01';
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '--- TEST V-09: TourGuia — guía sin habilitación activa en el parque ---';
DECLARE @at INT, @g2 INT;
SELECT @at = id_atraccion_tour FROM turismo.AtraccionTour WHERE nombre = 'Tour Sendero del Cóndor TEST (mod)';
-- Insertar un guía sin habilitación para el parque
EXEC turismo.GuiaInsertar
    @p_nombre                = 'Guía',
    @p_apellido              = 'Sin Habilitación',
    @p_dni                   = '99999901',
    @p_especialidad          = NULL,
    @p_vigencia_autorizacion = '2027-12-31';
SELECT @g2 = id_guia FROM turismo.Guia WHERE dni = '99999901';
BEGIN TRY
    EXEC turismo.TourGuiaInsertar
        @p_id_atraccion_tour = @at,
        @p_id_guia           = @g2;  -- no tiene GuiaParque para este parque
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '--- TEST V-10: ObligacionCanon — estado inválido ---';
DECLARE @con INT;
SELECT @con = id_concesion FROM comercial.Concesion WHERE tipo_actividad = 'Restauración y gastronomía TEST';
BEGIN TRY
    EXEC comercial.ObligacionCanonInsertar
        @p_id_concesion      = @con,
        @p_mes               = 8,
        @p_anio              = 2025,
        @p_monto_obligado    = 85000.00,
        @p_estado            = 'INVALIDO',  -- estado no permitido
        @p_fecha_vencimiento = '2025-09-10';
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '--- TEST V-11: ObligacionCanon — período duplicado ---';
BEGIN TRY
    EXEC comercial.ObligacionCanonInsertar
        @p_id_concesion      = @con,
        @p_mes               = 7,   -- combinación concesion+mes+año ya existe
        @p_anio              = 2025,
        @p_monto_obligado    = 85000.00,
        @p_estado            = 'PENDIENTE',
        @p_fecha_vencimiento = '2025-08-10';
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '--- TEST V-12: PagoCanon — obligación ya pagada ---';
DECLARE @ob INT;
SELECT @ob = id_obligacion FROM comercial.ObligacionCanon
WHERE id_concesion = @con AND mes = 7 AND anio = 2025;
-- La obligación fue marcada como PARCIAL en la sección modificaciones;
-- la marcamos como PAGADO para el test
EXEC comercial.ObligacionCanonModificar
    @p_id_obligacion     = @ob,
    @p_monto_obligado    = 87000.00,
    @p_estado            = 'PAGADO',
    @p_fecha_vencimiento = '2025-08-15';
BEGIN TRY
    EXEC comercial.PagoCanonInsertar
        @p_id_obligacion = @ob,
        @p_fecha_pago    = '2025-08-01',
        @p_monto_pagado  = 1000.00;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '--- TEST V-13: Ticket — total negativo ---';
DECLARE @fp INT;
SELECT @fp = id_forma_pago FROM ventas.FormaPago WHERE descripcion = 'Efectivo TEST';
BEGIN TRY
    EXEC ventas.TicketInsertar
        @p_punto_venta   = '0001',
        @p_numero        = '99999999',
        @p_fecha_venta   = '2025-10-01 08:00:00',
        @p_id_forma_pago = @fp,
        @p_total         = -500.00;  -- total negativo
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '--- TEST V-14: Ticket — punto de venta inválido ---';
BEGIN TRY
    EXEC ventas.TicketInsertar
        @p_punto_venta   = 'AB01',  -- no numérico
        @p_numero        = '00000002',
        @p_fecha_venta   = '2025-10-01 08:00:00',
        @p_id_forma_pago = @fp,
        @p_total         = 1000.00;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '--- TEST V-15: TicketDetalle — sin precio ni atracción ---';
DECLARE @tk INT;
SELECT @tk = id_ticket FROM ventas.Ticket WHERE punto_venta = '0001' AND numero = '00000001';
DECLARE @pk INT;
SELECT @pk = id_parque FROM parques.Parque WHERE codigo_oficial = 'PN-TEST-01';
BEGIN TRY
    EXEC ventas.TicketDetalleInsertar
        @p_id_ticket           = @tk,
        @p_id_parque           = @pk,
        @p_id_historial_precio = NULL,  -- ambos NULL: viola CK_TicketDetalle_Item
        @p_id_tipo_visitante   = NULL,
        @p_id_atraccion_tour   = NULL,
        @p_fecha_acceso        = '2025-09-16',
        @p_cantidad            = 1,
        @p_precio_unitario     = 100.00,
        @p_subtotal            = 100.00;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '--- TEST V-16: AtraccionTour — cupo máximo cero ---';
DECLARE @ta INT;
SELECT @ta = id_tipo_atraccion FROM turismo.TipoAtraccion WHERE descripcion = 'Senderismo TEST';
BEGIN TRY
    EXEC turismo.AtraccionTourInsertar
        @p_id_parque         = @pk,
        @p_id_tipo_atraccion = @ta,
        @p_nombre            = 'Tour inválido',
        @p_costo             = 500.00,
        @p_cupo_maximo       = 0,   -- debe ser > 0
        @p_duracion          = 60;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '--- TEST V-17: Concesion — canon mensual negativo ---';
DECLARE @emp_v17 INT;
SELECT @emp_v17 = id_empresa FROM comercial.Empresa WHERE cuit = '30123456789';
BEGIN TRY
    EXEC comercial.ConcesionInsertar
        @p_id_parque      = @pk,
        @p_id_empresa     = @emp_v17,
        @p_tipo_actividad = 'Actividad inválida',
        @p_fecha_inicio   = '2025-01-01',
        @p_fecha_fin      = '2025-12-31',
        @p_canon_mensual  = -1000;  -- debe ser > 0
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '--- TEST V-18: Eliminar Parque con dependencias ---';
BEGIN TRY
    EXEC parques.ParqueEliminar @p_id_parque = @pk;
    PRINT 'FALLO: debería haber generado error (existen concesiones).';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '--- TEST V-19: Eliminar Guardaparque ya inactivo ---';
-- Primero lo desactivamos
EXEC personal.GuardaparqueEliminar @p_id_guardaparque = @gp;
-- Intentar desactivarlo de nuevo
BEGIN TRY
    EXEC personal.GuardaparqueEliminar @p_id_guardaparque = @gp;
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

-- ---------------------------------------------------------------
PRINT '--- TEST V-20: Modificar con ID inexistente (genérico) ---';
BEGIN TRY
    EXEC parques.TipoParqueModificar
        @p_id_tipo_parque = 999999,
        @p_descripcion    = 'No existe';
    PRINT 'FALLO: debería haber generado error.';
END TRY
BEGIN CATCH
    PRINT 'OK — Error esperado: ' + ERROR_MESSAGE();
END CATCH;

GO

-- ==============================================================
PRINT '';
PRINT '==============================================================';
PRINT ' SECCIÓN 5 — BAJAS EXITOSAS (en orden inverso de dependencia)';
PRINT '==============================================================';

DECLARE
    @id_guardaparque   INT,
    @id_guia           INT,
    @id_guia_sin_hab   INT,
    @id_parque         INT,
    @id_empresa        INT,
    @id_atraccion_tour INT,
    @id_historial_precio INT,
    @id_concesion      INT,
    @id_obligacion     INT,
    @id_pago           INT,
    @id_ticket         INT,
    @id_detalle        INT,
    @id_historial_gp   INT,
    @id_tipo_parque    INT,
    @id_tipo_visitante INT,
    @id_forma_pago     INT,
    @id_tipo_atraccion INT;

SELECT @id_guardaparque    = id_guardaparque    FROM personal.Guardaparque    WHERE dni             = '30111222';
SELECT @id_guia            = id_guia            FROM turismo.Guia             WHERE dni             = '28999888';
SELECT @id_guia_sin_hab    = id_guia            FROM turismo.Guia             WHERE dni             = '99999901';
SELECT @id_parque          = id_parque          FROM parques.Parque           WHERE codigo_oficial  = 'PN-TEST-01';
SELECT @id_empresa         = id_empresa         FROM comercial.Empresa        WHERE cuit            = '30123456789';
SELECT @id_atraccion_tour  = id_atraccion_tour  FROM turismo.AtraccionTour    WHERE nombre LIKE     'Tour Sendero del Cóndor TEST%';
SELECT @id_historial_precio= id_historial_precio FROM ventas.HistorialPrecio  WHERE id_parque       = @id_parque;
SELECT @id_concesion       = id_concesion       FROM comercial.Concesion      WHERE tipo_actividad  = 'Restauración y gastronomía TEST';
SELECT @id_obligacion      = id_obligacion      FROM comercial.ObligacionCanon WHERE id_concesion   = @id_concesion AND mes = 7 AND anio = 2025;
SELECT @id_pago            = id_pago            FROM comercial.PagoCanon      WHERE id_obligacion   = @id_obligacion;
SELECT @id_ticket          = id_ticket          FROM ventas.Ticket            WHERE punto_venta     = '0001' AND numero = '00000001';
SELECT @id_detalle         = id_detalle         FROM ventas.TicketDetalle     WHERE id_ticket       = @id_ticket;
SELECT @id_historial_gp    = id_historial       FROM personal.HistorialGuardaparque
                             WHERE id_guardaparque = @id_guardaparque AND fecha_egreso IS NULL;
SELECT @id_tipo_parque     = id_tipo_parque     FROM parques.TipoParque       WHERE descripcion LIKE 'Parque Nacional TEST%';
SELECT @id_tipo_visitante  = id_tipo_visitante  FROM ventas.TipoVisitante     WHERE descripcion LIKE 'Adulto TEST%';
SELECT @id_forma_pago      = id_forma_pago      FROM ventas.FormaPago         WHERE descripcion     = 'Efectivo TEST';
SELECT @id_tipo_atraccion  = id_tipo_atraccion  FROM turismo.TipoAtraccion    WHERE descripcion     = 'Senderismo TEST';

-- TicketDetalle
EXEC ventas.TicketDetalleEliminar @p_id_detalle = @id_detalle;
PRINT 'OK — TicketDetalle eliminado.';

-- Ticket
EXEC ventas.TicketEliminar @p_id_ticket = @id_ticket;
PRINT 'OK — Ticket eliminado.';

-- PagoCanon
EXEC comercial.PagoCanonEliminar @p_id_pago = @id_pago;
PRINT 'OK — PagoCanon eliminado.';

-- ObligacionCanon
EXEC comercial.ObligacionCanonEliminar @p_id_obligacion = @id_obligacion;
PRINT 'OK — ObligacionCanon eliminada.';

-- Concesion
EXEC comercial.ConcesionEliminar @p_id_concesion = @id_concesion;
PRINT 'OK — Concesion eliminada.';

-- HistorialPrecio
EXEC ventas.HistorialPrecioEliminar @p_id_historial_precio = @id_historial_precio;
PRINT 'OK — HistorialPrecio eliminado.';

-- TourGuia
EXEC turismo.TourGuiaEliminar @p_id_atraccion_tour = @id_atraccion_tour, @p_id_guia = @id_guia;
PRINT 'OK — TourGuia eliminado.';

-- AtraccionTour
EXEC turismo.AtraccionTourEliminar @p_id_atraccion_tour = @id_atraccion_tour;
PRINT 'OK — AtraccionTour eliminado.';

-- GuiaParque
EXEC turismo.GuiaParqueEliminar @p_id_guia = @id_guia, @p_id_parque = @id_parque;
PRINT 'OK — GuiaParque eliminado.';

-- HistorialGuardaparque (período activo reabierto en V-08)
EXEC personal.HistorialGuardaparqueEliminar @p_id_historial = @id_historial_gp;
PRINT 'OK — HistorialGuardaparque (período activo) eliminado.';

-- Eliminar todos los historiales restantes del guardaparque de prueba (vía SP)
DECLARE @id_hist_rest INT;
WHILE EXISTS (SELECT 1 FROM personal.HistorialGuardaparque WHERE id_guardaparque = @id_guardaparque)
BEGIN
    SELECT TOP 1 @id_hist_rest = id_historial FROM personal.HistorialGuardaparque WHERE id_guardaparque = @id_guardaparque;
    EXEC personal.HistorialGuardaparqueEliminar @p_id_historial = @id_hist_rest;
END
PRINT 'OK — Historiales restantes del guardaparque de prueba eliminados.';

-- Parque
EXEC parques.ParqueEliminar @p_id_parque = @id_parque;
PRINT 'OK — Parque eliminado.';

-- Empresa
EXEC comercial.EmpresaEliminar @p_id_empresa = @id_empresa;
PRINT 'OK — Empresa eliminada.';

-- Guía sin habilitación (auxiliar del test V-09)
EXEC turismo.GuiaEliminar @p_id_guia = @id_guia_sin_hab;
PRINT 'OK — Guia auxiliar eliminado.';

-- Guia principal
EXEC turismo.GuiaEliminar @p_id_guia = @id_guia;
PRINT 'OK — Guia eliminado.';

-- Guardaparque (baja lógica ya aplicada en V-19; verificar que está inactivo)
SELECT 'Guardaparque (baja lógica)' AS tabla,
       nombre, apellido, activo
FROM personal.Guardaparque WHERE id_guardaparque = @id_guardaparque;

-- TipoAtraccion
EXEC turismo.TipoAtraccionEliminar @p_id_tipo_atraccion = @id_tipo_atraccion;
PRINT 'OK — TipoAtraccion eliminado.';

-- FormaPago
EXEC ventas.FormaPagoEliminar @p_id_forma_pago = @id_forma_pago;
PRINT 'OK — FormaPago eliminado.';

-- TipoVisitante
EXEC ventas.TipoVisitanteEliminar @p_id_tipo_visitante = @id_tipo_visitante;
PRINT 'OK — TipoVisitante eliminado.';

-- TipoParque
EXEC parques.TipoParqueEliminar @p_id_tipo_parque = @id_tipo_parque;
PRINT 'OK — TipoParque eliminado.';

GO

-- ==============================================================
PRINT '';
PRINT '==============================================================';
PRINT ' SECCIÓN 6 — EVIDENCIA FINAL: VERIFICAR LIMPIEZA';
PRINT '==============================================================';

SELECT CASE WHEN COUNT(*) = 0 THEN 'OK — Sin registros TEST en TipoParque'
            ELSE 'ATENCIÓN — Quedan ' + CAST(COUNT(*) AS VARCHAR) + ' registros' END AS resultado
FROM parques.TipoParque WHERE descripcion LIKE '%TEST%';

SELECT CASE WHEN COUNT(*) = 0 THEN 'OK — Sin registros TEST en Parque'
            ELSE 'ATENCIÓN — Quedan ' + CAST(COUNT(*) AS VARCHAR) + ' registros' END AS resultado
FROM parques.Parque WHERE codigo_oficial LIKE 'PN-TEST%';

SELECT CASE WHEN COUNT(*) = 0 THEN 'OK — Sin registros TEST en Empresa'
            ELSE 'ATENCIÓN — Quedan ' + CAST(COUNT(*) AS VARCHAR) + ' registros' END AS resultado
FROM comercial.Empresa WHERE razon_social LIKE '%TEST%';

SELECT CASE WHEN COUNT(*) = 0 THEN 'OK — Sin registros TEST en Ticket'
            ELSE 'ATENCIÓN — Quedan ' + CAST(COUNT(*) AS VARCHAR) + ' registros' END AS resultado
FROM ventas.Ticket WHERE punto_venta = '0001' AND numero = '00000001';

SELECT g.nombre + ' ' + g.apellido AS guardaparque_prueba,
       g.activo,
       CASE WHEN g.activo = 0 THEN 'OK — Baja lógica aplicada' ELSE 'ATENCIÓN — activo = 1' END AS resultado
FROM personal.Guardaparque g WHERE g.dni = '30111222';

GO
PRINT '';
PRINT '==============================================================';
PRINT ' Testing ABM completado.';
PRINT '==============================================================';
