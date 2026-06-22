/*
=============================================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Archivo:     08-ScriptTesting_Reportes_SPs.sql
Descripción: Script para la ejecución y prueba de los Store Procedures
             de reportes desarrollados en la Entrega 7.
=============================================================================
*/

USE ParquesNacionalesDB;
GO

PRINT '=========================================================================';
PRINT 'INICIANDO TESTING DE REPORTES (ENTREGA 7)';
PRINT 'Nota: Ejecutar primero el script 09 para tener los datos insertados.';
PRINT '=========================================================================';
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 1: Reporte de visitas por semana, mes y año, por parque';
PRINT '-------------------------------------------------------------------------';
EXEC dbo.Reporte_Visitas;
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 2: Ingresos por parque por semana, mes y año (Consolidado)';
PRINT '-------------------------------------------------------------------------';
EXEC dbo.Ingresos_Parque;
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 3: Deudores de Concesiones (Formato XML)';
PRINT '-------------------------------------------------------------------------';
EXEC dbo.Deudores_XML;
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 4: Matriz de visitas (Tabla Cruzada / Pivot de meses)';
PRINT '-------------------------------------------------------------------------';
EXEC dbo.Matriz_Visitas;
GO

PRINT '';
PRINT '-------------------------------------------------------------------------';
PRINT 'Test 5: Parques y Concesiones (Formato XML Anidado)';
PRINT '-------------------------------------------------------------------------';
EXEC dbo.Parques_Concesiones_XML;
GO

PRINT '';
PRINT '=========================================================================';
PRINT 'FIN DEL TESTING DE REPORTES';
PRINT '=========================================================================';
GO