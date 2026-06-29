/*
==============================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Fecha:       29/06/2026
Descripción: Entrega 8 - Seguridad. Pruebas del cifrado del DNI.
             Se ejecuta DESPUÉS de 10-ScriptSeguridad_Cifrado.sql.
             Verifica que:
               1) El alta vía SP guarda el DNI cifrado (VARBINARY),
                  no en texto plano.
               2) La consulta vía SP devuelve el DNI descifrado.
               3) La unicidad por hash rechaza DNIs duplicados.
               4) La modificación vía SP re-cifra el DNI.
==============================================================
*/

USE ParquesNacionalesDB;
GO

PRINT '===========================================================';
PRINT ' TEST C-01: Alta de guardaparque -> DNI almacenado cifrado';
PRINT '===========================================================';
GO
BEGIN TRY
    EXEC personal.GuardaparqueInsertar
        @p_nombre   = 'Test',
        @p_apellido = 'Cifrado',
        @p_dni      = '45123456',
        @p_email    = 'test.cifrado@parques.gob.ar',
        @p_telefono = '1144556677';
    PRINT 'OK - Alta realizada.';
END TRY
BEGIN CATCH
    PRINT 'ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- En la tabla el DNI es binario (no hay columna en texto plano)
PRINT 'Contenido crudo en la tabla (debe verse VARBINARY en dni_cifrado):';
SELECT id_guardaparque, nombre, apellido, dni_cifrado, dni_hash
FROM personal.Guardaparque
WHERE dni_hash = HASHBYTES('SHA2_256', '45123456');
GO

PRINT '===========================================================';
PRINT ' TEST C-02: Consulta vía SP -> DNI descifrado correctamente';
PRINT '===========================================================';
GO
DECLARE @id INT = (SELECT id_guardaparque FROM personal.Guardaparque
                   WHERE dni_hash = HASHBYTES('SHA2_256', '45123456'));
EXEC personal.GuardaparqueConsultar @p_id_guardaparque = @id;
PRINT 'Se espera dni = 45123456 en la columna descifrada.';
GO

PRINT '===========================================================';
PRINT ' TEST C-03: Alta con DNI duplicado -> rechazada por hash';
PRINT '===========================================================';
GO
BEGIN TRY
    EXEC personal.GuardaparqueInsertar
        @p_nombre   = 'Otro',
        @p_apellido = 'Duplicado',
        @p_dni      = '45123456',   -- mismo DNI que C-01
        @p_email    = NULL,
        @p_telefono = NULL;
    PRINT 'ERROR: se permitió un DNI duplicado (no debería).';
END TRY
BEGIN CATCH
    PRINT 'OK - Rechazado correctamente: ' + ERROR_MESSAGE();
END CATCH
GO

PRINT '===========================================================';
PRINT ' TEST C-04: Modificación del DNI -> se re-cifra el valor';
PRINT '===========================================================';
GO
DECLARE @id INT = (SELECT id_guardaparque FROM personal.Guardaparque
                   WHERE dni_hash = HASHBYTES('SHA2_256', '45123456'));
DECLARE @cif_antes VARBINARY(256) = (SELECT dni_cifrado FROM personal.Guardaparque WHERE id_guardaparque = @id);

EXEC personal.GuardaparqueModificar
    @p_id_guardaparque = @id,
    @p_nombre   = 'Test',
    @p_apellido = 'Cifrado',
    @p_dni      = '45999888',   -- nuevo DNI
    @p_email    = 'test.cifrado@parques.gob.ar',
    @p_telefono = '1144556677';

DECLARE @cif_despues VARBINARY(256) = (SELECT dni_cifrado FROM personal.Guardaparque WHERE id_guardaparque = @id);

IF @cif_antes <> @cif_despues
    PRINT 'OK - El DNI cifrado cambió tras la modificación.';
ELSE
    PRINT 'ERROR: el DNI cifrado no cambió.';

PRINT 'Consulta descifrada (se espera dni = 45999888):';
EXEC personal.GuardaparqueConsultar @p_id_guardaparque = @id;
GO

PRINT '===========================================================';
PRINT ' TEST C-05: Alta y consulta de guía con DNI cifrado';
PRINT '===========================================================';
GO
BEGIN TRY
    EXEC turismo.GuiaInsertar
        @p_nombre                = 'Guia',
        @p_apellido              = 'Cifrada',
        @p_dni                   = '46555444',
        @p_especialidad          = 'Flora andina',
        @p_vigencia_autorizacion = '2027-12-31';
    PRINT 'OK - Alta de guía realizada.';
END TRY
BEGIN CATCH
    PRINT 'ERROR inesperado: ' + ERROR_MESSAGE();
END CATCH

DECLARE @idg INT = (SELECT id_guia FROM turismo.Guia WHERE dni_hash = HASHBYTES('SHA2_256', '46555444'));
PRINT 'Consulta descifrada del guía (se espera dni = 46555444):';
EXEC turismo.GuiaConsultar @p_id_guia = @idg;
GO

-- --------------------------------------------------------------
-- LIMPIEZA de los datos de prueba (opcional)
-- --------------------------------------------------------------
PRINT '===========================================================';
PRINT ' Limpieza de datos de prueba';
PRINT '===========================================================';
GO
DELETE FROM personal.Guardaparque WHERE dni_hash = HASHBYTES('SHA2_256', '45999888');
DELETE FROM turismo.Guia          WHERE dni_hash = HASHBYTES('SHA2_256', '46555444');
PRINT 'OK - Datos de prueba eliminados.';
GO
