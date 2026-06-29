/*
=============================================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Archivo:     07-ScriptReportes_SPs.sql
Descripción: Creación de Store Procedures para Reportes (Transaccionales y XML).
=============================================================================
*/

USE ParquesNacionalesDB;
GO

PRINT '=========================================================================';
PRINT 'INICIANDO CREACIÓN DE STORE PROCEDURES DE REPORTES (ENTREGA 7)';
PRINT '=========================================================================';
GO

-- =========================================================================
-- 1. REPORTE DE VISITAS POR SEMANA, MES Y AÑO, POR PARQUE
-- =========================================================================
PRINT 'Creando o actualizando Store Procedure dbo.Reporte_Visitas...';
GO
CREATE OR ALTER PROCEDURE dbo.Reporte_Visitas
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        p.nombre AS Parque,
        YEAR(td.fecha_acceso) AS Anio,
        MONTH(td.fecha_acceso) AS Mes,
        DATEPART(WEEK, td.fecha_acceso) AS Semana,
        SUM(td.cantidad) AS Total_Visitas
    FROM ventas.TicketDetalle td
    JOIN parques.Parque p ON td.id_parque = p.id_parque
    GROUP BY 
        p.nombre, 
        YEAR(td.fecha_acceso), 
        MONTH(td.fecha_acceso), 
        DATEPART(WEEK, td.fecha_acceso)
    ORDER BY 
        Parque, Anio, Mes, Semana;
END;
GO
PRINT 'OK - Store Procedure dbo.Reporte_Visitas creado/actualizado con exito.';
GO


-- =========================================================================
-- 2. INGRESOS POR PARQUE POR SEMANA, MES Y AÑO
-- =========================================================================
PRINT 'Creando o actualizando Store Procedure dbo.Ingresos_Parque...';
GO
CREATE OR ALTER PROCEDURE dbo.Ingresos_Parque
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        Parque, 
        Anio, 
        Mes, 
        Semana,
        SUM(Ingreso_Entradas) AS Total_Entradas,
        SUM(Ingreso_Tours) AS Total_Tours,
        SUM(Ingreso_Concesiones) AS Total_Concesiones,
        SUM(Ingreso_Entradas + Ingreso_Tours + Ingreso_Concesiones) AS Total_General
    FROM (
        -- Ingresos por Entradas y Tours
        SELECT 
            p.nombre AS Parque,
            YEAR(td.fecha_acceso) AS Anio,
            MONTH(td.fecha_acceso) AS Mes,
            DATEPART(WEEK, td.fecha_acceso) AS Semana,
            SUM(CASE WHEN td.id_atraccion_tour IS NULL THEN td.subtotal ELSE 0 END) AS Ingreso_Entradas,
            SUM(CASE WHEN td.id_atraccion_tour IS NOT NULL THEN td.subtotal ELSE 0 END) AS Ingreso_Tours,
            0 AS Ingreso_Concesiones
        FROM ventas.TicketDetalle td
        JOIN parques.Parque p ON td.id_parque = p.id_parque
        GROUP BY p.nombre, td.fecha_acceso

        UNION ALL

        -- Ingresos por Concesiones
        SELECT 
            p.nombre AS Parque,
            YEAR(pc.fecha_pago) AS Anio,
            MONTH(pc.fecha_pago) AS Mes,
            DATEPART(WEEK, pc.fecha_pago) AS Semana,
            0, 0,
            SUM(pc.monto_pagado) AS Ingreso_Concesiones
        FROM comercial.PagoCanon pc
        JOIN comercial.ObligacionCanon oc ON pc.id_obligacion = oc.id_obligacion
        JOIN comercial.Concesion c ON oc.id_concesion = c.id_concesion
        JOIN parques.Parque p ON c.id_parque = p.id_parque
        GROUP BY p.nombre, pc.fecha_pago
    ) AS consolidados
    GROUP BY Parque, Anio, Mes, Semana
    ORDER BY Parque, Anio, Mes, Semana;
END;
GO
PRINT 'OK - Store Procedure dbo.Ingresos_Parque creado/actualizado con exito.';
GO


-- =========================================================================
-- 3. DEUDORES (RETORNA XML)
-- =========================================================================
PRINT 'Creando o actualizando Store Procedure dbo.Deudores_XML...';
GO
CREATE OR ALTER PROCEDURE dbo.Deudores_XML
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        e.razon_social AS 'Empresa',
        c.tipo_actividad AS 'Actividad',
        oc.mes AS 'Mes',
        oc.anio AS 'Anio',
        (oc.monto_obligado - ISNULL(SUM(pc.monto_pagado), 0)) AS 'MontoAdeudado'
    FROM comercial.ObligacionCanon oc
    JOIN comercial.Concesion c ON oc.id_concesion = c.id_concesion
    JOIN comercial.Empresa e ON c.id_empresa = e.id_empresa
    LEFT JOIN comercial.PagoCanon pc ON oc.id_obligacion = pc.id_obligacion
    WHERE oc.fecha_vencimiento < CAST(GETDATE() AS DATE)
    GROUP BY e.razon_social, c.tipo_actividad, oc.id_obligacion, oc.mes, oc.anio, oc.monto_obligado
    HAVING (oc.monto_obligado - ISNULL(SUM(pc.monto_pagado), 0)) > 0
    FOR XML PATH('Deudor'), ROOT('ReporteDeudores');
END;
GO
PRINT 'OK - Store Procedure dbo.Deudores_XML creado/actualizado con exito.';
GO


-- =========================================================================
-- 4. MATRIZ DE VISITAS (PIVOT)
-- =========================================================================
PRINT 'Creando o actualizando Store Procedure dbo.Matriz_Visitas...';
GO
CREATE OR ALTER PROCEDURE dbo.Matriz_Visitas
    @Anio INT = NULL -- Parametro opcional para filtrar por año
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        Parque,
        ISNULL([1], 0) AS Ene,
        ISNULL([2], 0) AS Feb,
        ISNULL([3], 0) AS Mar,
        ISNULL([4], 0) AS Abr,
        ISNULL([5], 0) AS May,
        ISNULL([6], 0) AS Jun,
        ISNULL([7], 0) AS Jul,
        ISNULL([8], 0) AS Ago,
        ISNULL([9], 0) AS Sep,
        ISNULL([10], 0) AS Oct,
        ISNULL([11], 0) AS Nov,
        ISNULL([12], 0) AS Dic
    FROM (
        -- Origen de datos para el Pivot
        SELECT 
            p.nombre AS Parque,
            MONTH(td.fecha_acceso) AS Mes,
            td.cantidad
        FROM ventas.TicketDetalle td
        JOIN parques.Parque p ON td.id_parque = p.id_parque
        WHERE (@Anio IS NULL OR YEAR(td.fecha_acceso) = @Anio)
    ) AS DatosOrigen
    PIVOT (
        SUM(cantidad)
        FOR Mes IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
    ) AS TablaPivot
    ORDER BY Parque;
END;
GO
PRINT 'OK - Store Procedure dbo.Matriz_Visitas creado/actualizado con exito.';
GO


-- =========================================================================
-- 5. PARQUES Y CONCESIONES (RETORNA XML ANIDADO)
-- =========================================================================
PRINT 'Creando o actualizando Store Procedure dbo.Parques_Concesiones_XML...';
GO
CREATE OR ALTER PROCEDURE dbo.Parques_Concesiones_XML
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        p.nombre AS '@Nombre',
        (
            SELECT 
                e.razon_social AS 'Titular',
                c.tipo_actividad AS 'Servicio',
                c.fecha_inicio AS 'FechaInicio'
            FROM comercial.Concesion c
            JOIN comercial.Empresa e ON c.id_empresa = e.id_empresa
            WHERE c.id_parque = p.id_parque
            FOR XML PATH('Concesion'), TYPE
        )
    FROM parques.Parque p
    FOR XML PATH('Parque'), ROOT('SistemaParques');
END;
GO
PRINT 'OK - Store Procedure dbo.Parques_Concesiones_XML creado/actualizado con exito.';
GO

PRINT '=========================================================================';
PRINT 'FIN DEL SCRIPT: TODOS LOS STORE PROCEDURES FUERON CREADOS';
PRINT '=========================================================================';
GO