/*
==============================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Fecha:       29/06/2026
Descripción: Entrega 8 - Seguridad. Muestreo representativo de los
             permisos de los roles. Se ejecuta DESPUÉS de
             10-ScriptSeguridad_Cifrado.sql y 11-ScriptSeguridad_Roles.sql.

             No se prueba exhaustivamente cada permiso (sería muy
             extenso): se valida una muestra representativa, con
             foco en la restricción de DESCIFRADO del DNI.

             Para los allow/deny se usa HAS_PERMS_BY_NAME (1 = tiene
             permiso, 0 = denegado) bajo EXECUTE AS, y ejecuciones
             reales para el caso del descifrado del DNI.
==============================================================
*/

USE ParquesNacionalesDB;
GO

-- ==============================================================
-- TEST R-01: rol_admin DESCIFRA el DNI (caso permitido, destacado)
-- ==============================================================
PRINT '===========================================================';
PRINT ' TEST R-01: usr_admin ejecuta GuardaparqueConsultar -> descifra OK';
PRINT '===========================================================';
GO
EXECUTE AS USER = 'usr_admin';
BEGIN TRY
    EXEC personal.GuardaparqueConsultar;   -- abre la clave y descifra
    PRINT 'OK - usr_admin pudo descifrar el DNI.';
END TRY
BEGIN CATCH
    PRINT 'ERROR (no esperado): ' + ERROR_MESSAGE();
END CATCH
REVERT;
GO

-- ==============================================================
-- TEST R-02: rol_consultas NO puede descifrar el DNI (restricción clave)
--   Tiene EXECUTE sobre el SP, pero no permiso sobre la clave:
--   el OPEN SYMMETRIC KEY falla.
-- ==============================================================
PRINT '===========================================================';
PRINT ' TEST R-02: usr_consultas ejecuta GuardaparqueConsultar -> descifrado DENEGADO';
PRINT '===========================================================';
GO
EXECUTE AS USER = 'usr_consultas';
BEGIN TRY
    EXEC personal.GuardaparqueConsultar;
    PRINT 'ERROR: usr_consultas pudo descifrar (no debería).';
END TRY
BEGIN CATCH
    PRINT 'OK - Descifrado denegado para usr_consultas: ' + ERROR_MESSAGE();
END CATCH
REVERT;
GO

-- ==============================================================
-- TEST R-03: Matriz de permisos de usr_consultas (muestra)
-- ==============================================================
PRINT '===========================================================';
PRINT ' TEST R-03: permisos de usr_consultas (1=permitido, 0=denegado)';
PRINT '===========================================================';
GO
EXECUTE AS USER = 'usr_consultas';
SELECT
    HAS_PERMS_BY_NAME('dbo.Reporte_Visitas', 'OBJECT', 'EXECUTE')            AS reporte_visitas_permitido,
    HAS_PERMS_BY_NAME('personal.GuardaparqueConsultar', 'OBJECT', 'EXECUTE') AS consultar_gp_permitido,
    HAS_PERMS_BY_NAME('personal.GuardaparqueInsertar', 'OBJECT', 'EXECUTE')  AS abm_gp_permitido,
    HAS_PERMS_BY_NAME('importaciones.ImportarEstadisticasVisitantes', 'OBJECT', 'EXECUTE') AS importar_permitido;
PRINT 'Esperado: reporte=1, consultar=1, abm=0, importar=0';
REVERT;
GO

-- ==============================================================
-- TEST R-04: usr_consultas intenta un ABM -> EXECUTE denegado
-- ==============================================================
PRINT '===========================================================';
PRINT ' TEST R-04: usr_consultas intenta personal.GuardaparqueInsertar -> DENEGADO';
PRINT '===========================================================';
GO
EXECUTE AS USER = 'usr_consultas';
BEGIN TRY
    EXEC personal.GuardaparqueInsertar
        @p_nombre = 'X', @p_apellido = 'Y', @p_dni = '11111111';
    PRINT 'ERROR: usr_consultas pudo ejecutar un ABM (no debería).';
END TRY
BEGIN CATCH
    PRINT 'OK - ABM denegado para usr_consultas: ' + ERROR_MESSAGE();
END CATCH
REVERT;
GO

-- ==============================================================
-- TEST R-05: Matriz de permisos de usr_importador (muestra)
-- ==============================================================
PRINT '===========================================================';
PRINT ' TEST R-05: permisos de usr_importador (1=permitido, 0=denegado)';
PRINT '===========================================================';
GO
EXECUTE AS USER = 'usr_importador';
SELECT
    HAS_PERMS_BY_NAME('importaciones.ImportarEstadisticasVisitantes', 'OBJECT', 'EXECUTE') AS importar_permitido,
    HAS_PERMS_BY_NAME('dbo.Reporte_Visitas', 'OBJECT', 'EXECUTE')            AS reporte_permitido,
    HAS_PERMS_BY_NAME('personal.GuardaparqueInsertar', 'OBJECT', 'EXECUTE')  AS abm_permitido,
    HAS_PERMS_BY_NAME('personal.GuardaparqueConsultar', 'OBJECT', 'EXECUTE') AS consultar_permitido;
PRINT 'Esperado: importar=1, reporte=0, abm=0, consultar=0';
REVERT;
GO

-- ==============================================================
-- TEST R-06: Matriz de permisos de usr_admin (muestra)
-- ==============================================================
PRINT '===========================================================';
PRINT ' TEST R-06: permisos de usr_admin (1=permitido, 0=denegado)';
PRINT '===========================================================';
GO
EXECUTE AS USER = 'usr_admin';
SELECT
    HAS_PERMS_BY_NAME('personal.GuardaparqueInsertar', 'OBJECT', 'EXECUTE')  AS abm_permitido,
    HAS_PERMS_BY_NAME('importaciones.ImportarEstadisticasVisitantes', 'OBJECT', 'EXECUTE') AS importar_permitido,
    HAS_PERMS_BY_NAME('dbo.Reporte_Visitas', 'OBJECT', 'EXECUTE')            AS reporte_permitido,
    HAS_PERMS_BY_NAME('personal.GuardaparqueConsultar', 'OBJECT', 'EXECUTE') AS consultar_permitido;
PRINT 'Esperado: todos = 1 (y además es el único que puede descifrar el DNI, ver R-01)';
REVERT;
GO

PRINT '===========================================================';
PRINT ' Muestreo de permisos de roles finalizado.';
PRINT '===========================================================';
GO
