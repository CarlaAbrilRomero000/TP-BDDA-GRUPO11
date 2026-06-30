/*
==============================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Fecha:       29/06/2026
Descripción: Entrega 8 - Seguridad. Creación de roles de seguridad
             con permisos granulares y usuarios de prueba.
             Se ejecuta DESPUÉS de 10-ScriptSeguridad_Cifrado.sql
             (necesita la SYMMETRIC KEY SK_DNI y el CERTIFICATE
             CertDNI ya creados).

             Roles:
               - rol_admin       : administra todo el sistema y es
                                   el ÚNICO que puede DESCIFRAR el DNI.
               - rol_importador  : solo ejecuta los SPs de importación
                                   de datos (schema importaciones).
               - rol_consultas   : solo ejecuta reportes/consultas;
                                   puede listar guardaparques/guías
                                   pero NO puede descifrar el DNI.

             El detalle de permisos está documentado en el cuadro
             de roles de 12-Entrega8_Documentacion_Seguridad.md.
==============================================================
*/

USE ParquesNacionalesDB;
GO

-- ==============================================================
-- 1. CREACIÓN DE ROLES (idempotente)
-- ==============================================================
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rol_admin' AND type = 'R')
BEGIN
    PRINT 'Creando rol rol_admin...';
    CREATE ROLE rol_admin;
END
ELSE
    PRINT 'OK - rol_admin ya existe.';
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rol_importador' AND type = 'R')
BEGIN
    PRINT 'Creando rol rol_importador...';
    CREATE ROLE rol_importador;
END
ELSE
    PRINT 'OK - rol_importador ya existe.';
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rol_consultas' AND type = 'R')
BEGIN
    PRINT 'Creando rol rol_consultas...';
    CREATE ROLE rol_consultas;
END
ELSE
    PRINT 'OK - rol_consultas ya existe.';
GO

-- ==============================================================
-- 2. PERMISOS GRANULARES
-- ==============================================================
PRINT '===========================================================';
PRINT ' Asignando permisos a los roles';
PRINT '===========================================================';
GO

-- 2.1 rol_admin: EXECUTE sobre todos los esquemas con SPs del sistema
--     (ABM, lógica de negocio, APIs, importación y reportes).
GRANT EXECUTE ON SCHEMA::parques       TO rol_admin;
GRANT EXECUTE ON SCHEMA::personal      TO rol_admin;
GRANT EXECUTE ON SCHEMA::turismo       TO rol_admin;
GRANT EXECUTE ON SCHEMA::comercial     TO rol_admin;
GRANT EXECUTE ON SCHEMA::ventas        TO rol_admin;
GRANT EXECUTE ON SCHEMA::estadisticas  TO rol_admin;
GRANT EXECUTE ON SCHEMA::importaciones TO rol_admin;
GRANT EXECUTE ON SCHEMA::dbo           TO rol_admin;
-- Permiso para DESCIFRAR el DNI: solo rol_admin puede abrir la clave.
GRANT VIEW DEFINITION ON SYMMETRIC KEY::SK_DNI TO rol_admin;
GRANT CONTROL ON CERTIFICATE::CertDNI          TO rol_admin;
PRINT 'OK - Permisos de rol_admin asignados (incluye descifrado de DNI).';
GO

-- 2.2 rol_importador: solo SPs de importación de datos.
GRANT EXECUTE ON SCHEMA::importaciones TO rol_importador;
PRINT 'OK - Permisos de rol_importador asignados (solo importación).';
GO

-- 2.3 rol_consultas: solo reportes/consultas. Puede listar
--     guardaparques/guías, pero NO recibe permiso sobre la clave,
--     por lo que el descifrado del DNI le será denegado.
--     Las grants de reportes se aplican solo si el SP existe
--     (los reportes provienen de los scripts 07 y 08).
DECLARE @reportes TABLE (sp SYSNAME, id INT IDENTITY(1,1));
INSERT INTO @reportes (sp) VALUES
    ('dbo.Reporte_Visitas'), ('dbo.Ingresos_Parque'), ('dbo.Deudores_XML'),
    ('dbo.Matriz_Visitas'), ('dbo.Parques_Concesiones_XML'), ('dbo.Ingresos_Parque_USD');

DECLARE @sp SYSNAME, @sql NVARCHAR(300);

DECLARE @entero INT = 1;
WHILE @entero <= (SELECT MAX(id) FROM @reportes)
BEGIN
    SET @sp = (SELECT sp FROM @reportes WHERE id = @entero);
    IF OBJECT_ID(@sp, 'P') IS NOT NULL
    BEGIN
        SET @sql = 'GRANT EXECUTE ON OBJECT::' + @sp + ' TO rol_consultas;';
        EXEC(@sql);
    END
    ELSE
        PRINT 'AVISO - No existe el SP de reporte ' + @sp + ' (correr scripts 07/08); se omite la grant.';
    SET @entero = @entero + 1;
END

GRANT EXECUTE ON OBJECT::personal.GuardaparqueConsultar TO rol_consultas;
GRANT EXECUTE ON OBJECT::turismo.GuiaConsultar          TO rol_consultas;
PRINT 'OK - Permisos de rol_consultas asignados (reportes y consultas, sin descifrado).';
GO

-- ==============================================================
-- 3. USUARIOS DE PRUEBA (sin login, solo para testear permisos)
-- ==============================================================
PRINT '===========================================================';
PRINT ' Creando usuarios de prueba y asignándolos a sus roles';
PRINT '===========================================================';
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usr_admin')
    CREATE USER usr_admin WITHOUT LOGIN;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usr_importador')
    CREATE USER usr_importador WITHOUT LOGIN;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usr_consultas')
    CREATE USER usr_consultas WITHOUT LOGIN;
GO

ALTER ROLE rol_admin      ADD MEMBER usr_admin;
ALTER ROLE rol_importador ADD MEMBER usr_importador;
ALTER ROLE rol_consultas  ADD MEMBER usr_consultas;
PRINT 'OK - Usuarios de prueba asignados a sus roles.';
GO

PRINT '===========================================================';
PRINT ' Roles de seguridad creados y configurados.';
PRINT '===========================================================';
GO
