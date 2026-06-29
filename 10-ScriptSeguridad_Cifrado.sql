/*
==============================================================
Universidad: Universidad Nacional de La Matanza
Materia:     3641 - Bases de Datos Aplicada
Grupo:       11
Integrantes: Federico Augusto Cusa Ortiz, Carla Abril Romero, Lautaro Garat
Fecha:       29/06/2026
Descripción: Entrega 8 - Seguridad. Script de MODIFICACIÓN que
             aplica cifrado al dato sensible DNI sobre el sistema
             ya existente (tablas personal.Guardaparque y
             turismo.Guia, y sus SPs ABM).

             El script está pensado para correr DESPUÉS de los
             scripts 01-09. Realiza una demostración guiada:
               1) Muestra el DNI en texto plano (ANTES).
               2) Crea los objetos criptográficos.
               3) Agrega columnas cifradas y migra los datos.
               4) Muestra el DNI ya cifrado (DESPUÉS).
               5) Descifra para probar el acceso (PRUEBA).
               6) Elimina la columna en texto plano.
               7) Redefine los SPs ABM para cifrar/descifrar.

             Decisiones de diseño:
             - Cifrado simétrico AES_256 (jerarquía Master Key ->
               Certificado -> Symmetric Key), enfoque estándar del
               curso (Unidad 6).
             - El DNI se guarda SOLO cifrado en la columna
               dni_cifrado VARBINARY. Se elimina la columna en
               texto plano.
             - Como ENCRYPTBYKEY usa un IV aleatorio (el ciphertext
               cambia en cada cifrado), no sirve para verificar
               unicidad. Por eso se agrega dni_hash (SHA2_256,
               determinístico) con constraint UNIQUE: permite
               detectar duplicados sin descifrar.
==============================================================
*/

USE ParquesNacionalesDB;
GO

-- ==============================================================
-- 1. DEMOSTRACIÓN — ESTADO ANTES DEL CIFRADO (DNI en texto plano)
--    Se ejecuta solo si la columna 'dni' todavía existe, para que
--    el script sea re-ejecutable sin romperse.
-- ==============================================================
PRINT '===========================================================';
PRINT ' ANTES DEL CIFRADO — DNI en texto plano';
PRINT '===========================================================';
GO
IF COL_LENGTH('personal.Guardaparque', 'dni') IS NOT NULL
BEGIN
    PRINT 'personal.Guardaparque (DNI en claro):';
    SELECT id_guardaparque, nombre, apellido, dni
    FROM personal.Guardaparque
    ORDER BY id_guardaparque;
END
ELSE
    PRINT 'OK - personal.Guardaparque ya no tiene la columna dni en texto plano (cifrado ya aplicado).';
GO
IF COL_LENGTH('turismo.Guia', 'dni') IS NOT NULL
BEGIN
    PRINT 'turismo.Guia (DNI en claro):';
    SELECT id_guia, nombre, apellido, dni
    FROM turismo.Guia
    ORDER BY id_guia;
END
ELSE
    PRINT 'OK - turismo.Guia ya no tiene la columna dni en texto plano (cifrado ya aplicado).';
GO

-- ==============================================================
-- 2. OBJETOS CRIPTOGRÁFICOS (Master Key -> Certificado -> Symmetric Key)
-- ==============================================================
PRINT '===========================================================';
PRINT ' Creando objetos criptográficos';
PRINT '===========================================================';
GO

-- 2.1 Database Master Key (protege a los certificados de la BD)
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
BEGIN
    PRINT 'Creando DATABASE MASTER KEY...';
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'P@rqu3sN@cion@les#2026$MasterKey';
END
ELSE
    PRINT 'OK - DATABASE MASTER KEY ya existe, se omite creación.';
GO

-- 2.2 Certificado que protege la clave simétrica
IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = 'CertDNI')
BEGIN
    PRINT 'Creando CERTIFICATE CertDNI...';
    CREATE CERTIFICATE CertDNI
        WITH SUBJECT = 'Certificado para cifrado de DNI (datos personales)',
             EXPIRY_DATE = '2035-12-31';
END
ELSE
    PRINT 'OK - CERTIFICATE CertDNI ya existe, se omite creación.';
GO

-- 2.3 Clave simétrica AES_256
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = 'SK_DNI')
BEGIN
    PRINT 'Creando SYMMETRIC KEY SK_DNI...';
    CREATE SYMMETRIC KEY SK_DNI
        WITH ALGORITHM = AES_256
        ENCRYPTION BY CERTIFICATE CertDNI;
END
ELSE
    PRINT 'OK - SYMMETRIC KEY SK_DNI ya existe, se omite creación.';
GO

-- ==============================================================
-- 3. AGREGAR COLUMNAS CIFRADAS (dni_cifrado + dni_hash)
-- ==============================================================
PRINT '===========================================================';
PRINT ' Agregando columnas dni_cifrado y dni_hash';
PRINT '===========================================================';
GO

-- 3.1 personal.Guardaparque
IF COL_LENGTH('personal.Guardaparque', 'dni_cifrado') IS NULL
BEGIN
    PRINT 'Agregando columna personal.Guardaparque.dni_cifrado...';
    ALTER TABLE personal.Guardaparque ADD dni_cifrado VARBINARY(256) NULL;
END
ELSE
    PRINT 'OK - personal.Guardaparque.dni_cifrado ya existe.';
GO
IF COL_LENGTH('personal.Guardaparque', 'dni_hash') IS NULL
BEGIN
    PRINT 'Agregando columna personal.Guardaparque.dni_hash...';
    ALTER TABLE personal.Guardaparque ADD dni_hash VARBINARY(32) NULL;
END
ELSE
    PRINT 'OK - personal.Guardaparque.dni_hash ya existe.';
GO

-- 3.2 turismo.Guia
IF COL_LENGTH('turismo.Guia', 'dni_cifrado') IS NULL
BEGIN
    PRINT 'Agregando columna turismo.Guia.dni_cifrado...';
    ALTER TABLE turismo.Guia ADD dni_cifrado VARBINARY(256) NULL;
END
ELSE
    PRINT 'OK - turismo.Guia.dni_cifrado ya existe.';
GO
IF COL_LENGTH('turismo.Guia', 'dni_hash') IS NULL
BEGIN
    PRINT 'Agregando columna turismo.Guia.dni_hash...';
    ALTER TABLE turismo.Guia ADD dni_hash VARBINARY(32) NULL;
END
ELSE
    PRINT 'OK - turismo.Guia.dni_hash ya existe.';
GO

-- ==============================================================
-- 4. BACKFILL — cifrar el DNI existente y calcular su hash
--    Solo corre si la columna en texto plano 'dni' todavía existe.
-- ==============================================================
PRINT '===========================================================';
PRINT ' Migrando (cifrando) los DNI existentes';
PRINT '===========================================================';
GO

OPEN SYMMETRIC KEY SK_DNI DECRYPTION BY CERTIFICATE CertDNI;

IF COL_LENGTH('personal.Guardaparque', 'dni') IS NOT NULL
BEGIN
    PRINT 'Cifrando DNI de personal.Guardaparque...';
    -- SQL dinámico: la columna 'dni' puede no existir en re-ejecuciones,
    -- por eso se referencia dentro de EXEC para que compile siempre.
    EXEC('
        UPDATE personal.Guardaparque
        SET dni_cifrado = ENCRYPTBYKEY(KEY_GUID(''SK_DNI''), dni),
            dni_hash    = HASHBYTES(''SHA2_256'', dni)
        WHERE dni IS NOT NULL;');
END
ELSE
    PRINT 'OK - personal.Guardaparque ya estaba migrado.';

IF COL_LENGTH('turismo.Guia', 'dni') IS NOT NULL
BEGIN
    PRINT 'Cifrando DNI de turismo.Guia...';
    EXEC('
        UPDATE turismo.Guia
        SET dni_cifrado = ENCRYPTBYKEY(KEY_GUID(''SK_DNI''), dni),
            dni_hash    = HASHBYTES(''SHA2_256'', dni)
        WHERE dni IS NOT NULL;');
END
ELSE
    PRINT 'OK - turismo.Guia ya estaba migrado.';

CLOSE SYMMETRIC KEY SK_DNI;
GO

-- ==============================================================
-- 5. DEMOSTRACIÓN — ESTADO DESPUÉS DEL CIFRADO (DNI cifrado)
-- ==============================================================
PRINT '===========================================================';
PRINT ' DESPUÉS DEL CIFRADO — DNI almacenado como VARBINARY';
PRINT '===========================================================';
GO
PRINT 'personal.Guardaparque (DNI cifrado + hash):';
SELECT id_guardaparque, nombre, apellido, dni_cifrado, dni_hash
FROM personal.Guardaparque
ORDER BY id_guardaparque;

PRINT 'turismo.Guia (DNI cifrado + hash):';
SELECT id_guia, nombre, apellido, dni_cifrado, dni_hash
FROM turismo.Guia
ORDER BY id_guia;
GO

-- ==============================================================
-- 6. DEMOSTRACIÓN — PRUEBA DE ACCESO (descifrado)
--    Se abre la clave y se recupera el DNI original.
-- ==============================================================
PRINT '===========================================================';
PRINT ' PRUEBA DE ACCESO — DNI descifrado a partir del VARBINARY';
PRINT '===========================================================';
GO
OPEN SYMMETRIC KEY SK_DNI DECRYPTION BY CERTIFICATE CertDNI;

PRINT 'personal.Guardaparque (DNI descifrado):';
SELECT id_guardaparque, nombre, apellido,
       CONVERT(VARCHAR(20), DECRYPTBYKEY(dni_cifrado)) AS dni_descifrado
FROM personal.Guardaparque
ORDER BY id_guardaparque;

PRINT 'turismo.Guia (DNI descifrado):';
SELECT id_guia, nombre, apellido,
       CONVERT(VARCHAR(20), DECRYPTBYKEY(dni_cifrado)) AS dni_descifrado
FROM turismo.Guia
ORDER BY id_guia;

CLOSE SYMMETRIC KEY SK_DNI;
GO

-- ==============================================================
-- 7. ELIMINAR LA COLUMNA EN TEXTO PLANO Y SU CONSTRAINT UNIQUE
--    Reemplazar la unicidad por la del hash determinístico.
-- ==============================================================
PRINT '===========================================================';
PRINT ' Eliminando columna dni en texto plano (queda solo cifrada)';
PRINT '===========================================================';
GO

-- 7.1 personal.Guardaparque: drop del UNIQUE auto-generado sobre dni, luego de la columna
IF COL_LENGTH('personal.Guardaparque', 'dni') IS NOT NULL
BEGIN
    DECLARE @cns_gp SYSNAME, @sql_gp NVARCHAR(MAX);

    SELECT @cns_gp = kc.name
    FROM sys.key_constraints kc
    JOIN sys.index_columns ic ON ic.object_id = kc.parent_object_id AND ic.index_id = kc.unique_index_id
    JOIN sys.columns c        ON c.object_id  = ic.object_id        AND c.column_id = ic.column_id
    WHERE kc.parent_object_id = OBJECT_ID('personal.Guardaparque')
      AND kc.type = 'UQ' AND c.name = 'dni';

    IF @cns_gp IS NOT NULL
    BEGIN
        SET @sql_gp = 'ALTER TABLE personal.Guardaparque DROP CONSTRAINT ' + QUOTENAME(@cns_gp) + ';';
        PRINT 'Eliminando constraint UNIQUE ' + @cns_gp + ' de personal.Guardaparque...';
        EXEC(@sql_gp);
    END

    PRINT 'Eliminando columna personal.Guardaparque.dni...';
    ALTER TABLE personal.Guardaparque DROP COLUMN dni;
END
ELSE
    PRINT 'OK - personal.Guardaparque.dni ya fue eliminada.';
GO

-- 7.2 turismo.Guia: idem
IF COL_LENGTH('turismo.Guia', 'dni') IS NOT NULL
BEGIN
    DECLARE @cns_g SYSNAME, @sql_g NVARCHAR(MAX);

    SELECT @cns_g = kc.name
    FROM sys.key_constraints kc
    JOIN sys.index_columns ic ON ic.object_id = kc.parent_object_id AND ic.index_id = kc.unique_index_id
    JOIN sys.columns c        ON c.object_id  = ic.object_id        AND c.column_id = ic.column_id
    WHERE kc.parent_object_id = OBJECT_ID('turismo.Guia')
      AND kc.type = 'UQ' AND c.name = 'dni';

    IF @cns_g IS NOT NULL
    BEGIN
        SET @sql_g = 'ALTER TABLE turismo.Guia DROP CONSTRAINT ' + QUOTENAME(@cns_g) + ';';
        PRINT 'Eliminando constraint UNIQUE ' + @cns_g + ' de turismo.Guia...';
        EXEC(@sql_g);
    END

    PRINT 'Eliminando columna turismo.Guia.dni...';
    ALTER TABLE turismo.Guia DROP COLUMN dni;
END
ELSE
    PRINT 'OK - turismo.Guia.dni ya fue eliminada.';
GO

-- 7.3 Unicidad por hash (reemplaza la unicidad del DNI en claro)
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = 'UQ_Guardaparque_DniHash')
BEGIN
    PRINT 'Creando UNIQUE UQ_Guardaparque_DniHash...';
    ALTER TABLE personal.Guardaparque
        ADD CONSTRAINT UQ_Guardaparque_DniHash UNIQUE (dni_hash);
END
ELSE
    PRINT 'OK - UQ_Guardaparque_DniHash ya existe.';
GO
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name = 'UQ_Guia_DniHash')
BEGIN
    PRINT 'Creando UNIQUE UQ_Guia_DniHash...';
    ALTER TABLE turismo.Guia
        ADD CONSTRAINT UQ_Guia_DniHash UNIQUE (dni_hash);
END
ELSE
    PRINT 'OK - UQ_Guia_DniHash ya existe.';
GO

-- ==============================================================
-- 8. REDEFINICIÓN DE SPs ABM AFECTADOS (cifran/descifran el DNI)
-- ==============================================================
PRINT '===========================================================';
PRINT ' Redefiniendo SPs ABM para operar con el DNI cifrado';
PRINT '===========================================================';
GO

-- --------------------------------------------------------------
-- personal.GuardaparqueInsertar — cifra el DNI al dar de alta
-- --------------------------------------------------------------
CREATE OR ALTER PROCEDURE personal.GuardaparqueInsertar
    @p_nombre   VARCHAR(50),
    @p_apellido VARCHAR(50),
    @p_dni      VARCHAR(20),
    @p_email    VARCHAR(100) = NULL,
    @p_telefono VARCHAR(50)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';
    DECLARE @hash VARBINARY(32) = HASHBYTES('SHA2_256', @p_dni);

    IF LTRIM(RTRIM(ISNULL(@p_nombre, ''))) = ''
        SET @errores += N'- El nombre es obligatorio.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_apellido, ''))) = ''
        SET @errores += N'- El apellido es obligatorio.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_dni, ''))) = ''
        SET @errores += N'- El DNI es obligatorio.' + CHAR(13);
    -- Unicidad por hash determinístico (no requiere descifrar)
    IF EXISTS (SELECT 1 FROM personal.Guardaparque WHERE dni_hash = @hash)
        SET @errores += N'- Ya existe un guardaparque registrado con ese DNI.' + CHAR(13);
    IF @p_email IS NOT NULL AND @p_email NOT LIKE '%@%.%'
        SET @errores += N'- El formato del email no es válido.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    OPEN SYMMETRIC KEY SK_DNI DECRYPTION BY CERTIFICATE CertDNI;

    INSERT INTO personal.Guardaparque (nombre, apellido, dni_cifrado, dni_hash, email, telefono, activo)
    VALUES (@p_nombre, @p_apellido,
            ENCRYPTBYKEY(KEY_GUID('SK_DNI'), @p_dni), @hash,
            @p_email, @p_telefono, 1);

    CLOSE SYMMETRIC KEY SK_DNI;
END
GO

-- --------------------------------------------------------------
-- personal.GuardaparqueModificar — re-cifra el DNI al modificar
-- --------------------------------------------------------------
CREATE OR ALTER PROCEDURE personal.GuardaparqueModificar
    @p_id_guardaparque INT,
    @p_nombre          VARCHAR(50),
    @p_apellido        VARCHAR(50),
    @p_dni             VARCHAR(20),
    @p_email           VARCHAR(100) = NULL,
    @p_telefono        VARCHAR(50)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';
    DECLARE @hash VARBINARY(32) = HASHBYTES('SHA2_256', @p_dni);

    IF NOT EXISTS (SELECT 1 FROM personal.Guardaparque WHERE id_guardaparque = @p_id_guardaparque)
        SET @errores += N'- No existe un guardaparque con el ID indicado.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_nombre, ''))) = ''
        SET @errores += N'- El nombre es obligatorio.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_apellido, ''))) = ''
        SET @errores += N'- El apellido es obligatorio.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_dni, ''))) = ''
        SET @errores += N'- El DNI es obligatorio.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM personal.Guardaparque WHERE dni_hash = @hash AND id_guardaparque != @p_id_guardaparque)
        SET @errores += N'- Ya existe otro guardaparque con ese DNI.' + CHAR(13);
    IF @p_email IS NOT NULL AND @p_email NOT LIKE '%@%.%'
        SET @errores += N'- El formato del email no es válido.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    OPEN SYMMETRIC KEY SK_DNI DECRYPTION BY CERTIFICATE CertDNI;

    UPDATE personal.Guardaparque
    SET nombre = @p_nombre, apellido = @p_apellido,
        dni_cifrado = ENCRYPTBYKEY(KEY_GUID('SK_DNI'), @p_dni),
        dni_hash    = @hash,
        email = @p_email, telefono = @p_telefono
    WHERE id_guardaparque = @p_id_guardaparque;

    CLOSE SYMMETRIC KEY SK_DNI;
END
GO

-- --------------------------------------------------------------
-- personal.GuardaparqueConsultar — devuelve el DNI DESCIFRADO
-- (descifra sin preguntar; el acceso lo controlan los roles)
-- @p_id_guardaparque NULL => devuelve todos
-- --------------------------------------------------------------
CREATE OR ALTER PROCEDURE personal.GuardaparqueConsultar
    @p_id_guardaparque INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    OPEN SYMMETRIC KEY SK_DNI DECRYPTION BY CERTIFICATE CertDNI;

    SELECT id_guardaparque, nombre, apellido,
           CONVERT(VARCHAR(20), DECRYPTBYKEY(dni_cifrado)) AS dni,
           email, telefono, activo
    FROM personal.Guardaparque
    WHERE (@p_id_guardaparque IS NULL OR id_guardaparque = @p_id_guardaparque)
    ORDER BY id_guardaparque;

    CLOSE SYMMETRIC KEY SK_DNI;
END
GO

-- --------------------------------------------------------------
-- turismo.GuiaInsertar — cifra el DNI al dar de alta
-- --------------------------------------------------------------
CREATE OR ALTER PROCEDURE turismo.GuiaInsertar
    @p_nombre                VARCHAR(50),
    @p_apellido              VARCHAR(50),
    @p_dni                   VARCHAR(20),
    @p_especialidad          VARCHAR(100) = NULL,
    @p_vigencia_autorizacion DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';
    DECLARE @hash VARBINARY(32) = HASHBYTES('SHA2_256', @p_dni);

    IF LTRIM(RTRIM(ISNULL(@p_nombre, ''))) = ''
        SET @errores += N'- El nombre es obligatorio.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_apellido, ''))) = ''
        SET @errores += N'- El apellido es obligatorio.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_dni, ''))) = ''
        SET @errores += N'- El DNI es obligatorio.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM turismo.Guia WHERE dni_hash = @hash)
        SET @errores += N'- Ya existe un guía registrado con ese DNI.' + CHAR(13);
    IF @p_vigencia_autorizacion IS NULL
        SET @errores += N'- La vigencia de autorización es obligatoria.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    OPEN SYMMETRIC KEY SK_DNI DECRYPTION BY CERTIFICATE CertDNI;

    INSERT INTO turismo.Guia (nombre, apellido, dni_cifrado, dni_hash, especialidad, vigencia_autorizacion)
    VALUES (@p_nombre, @p_apellido,
            ENCRYPTBYKEY(KEY_GUID('SK_DNI'), @p_dni), @hash,
            @p_especialidad, @p_vigencia_autorizacion);

    CLOSE SYMMETRIC KEY SK_DNI;
END
GO

-- --------------------------------------------------------------
-- turismo.GuiaModificar — re-cifra el DNI al modificar
-- --------------------------------------------------------------
CREATE OR ALTER PROCEDURE turismo.GuiaModificar
    @p_id_guia               INT,
    @p_nombre                VARCHAR(50),
    @p_apellido              VARCHAR(50),
    @p_dni                   VARCHAR(20),
    @p_especialidad          VARCHAR(100) = NULL,
    @p_vigencia_autorizacion DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores NVARCHAR(MAX) = N'';
    DECLARE @hash VARBINARY(32) = HASHBYTES('SHA2_256', @p_dni);

    IF NOT EXISTS (SELECT 1 FROM turismo.Guia WHERE id_guia = @p_id_guia)
        SET @errores += N'- No existe un guía con el ID indicado.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_nombre, ''))) = ''
        SET @errores += N'- El nombre es obligatorio.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_apellido, ''))) = ''
        SET @errores += N'- El apellido es obligatorio.' + CHAR(13);
    IF LTRIM(RTRIM(ISNULL(@p_dni, ''))) = ''
        SET @errores += N'- El DNI es obligatorio.' + CHAR(13);
    IF EXISTS (SELECT 1 FROM turismo.Guia WHERE dni_hash = @hash AND id_guia != @p_id_guia)
        SET @errores += N'- Ya existe otro guía con ese DNI.' + CHAR(13);
    IF @p_vigencia_autorizacion IS NULL
        SET @errores += N'- La vigencia de autorización es obligatoria.' + CHAR(13);

    IF @errores != N'' THROW 50000, @errores, 1;

    OPEN SYMMETRIC KEY SK_DNI DECRYPTION BY CERTIFICATE CertDNI;

    UPDATE turismo.Guia
    SET nombre = @p_nombre, apellido = @p_apellido,
        dni_cifrado = ENCRYPTBYKEY(KEY_GUID('SK_DNI'), @p_dni),
        dni_hash    = @hash,
        especialidad = @p_especialidad, vigencia_autorizacion = @p_vigencia_autorizacion
    WHERE id_guia = @p_id_guia;

    CLOSE SYMMETRIC KEY SK_DNI;
END
GO

-- --------------------------------------------------------------
-- turismo.GuiaConsultar — devuelve el DNI DESCIFRADO
-- --------------------------------------------------------------
CREATE OR ALTER PROCEDURE turismo.GuiaConsultar
    @p_id_guia INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    OPEN SYMMETRIC KEY SK_DNI DECRYPTION BY CERTIFICATE CertDNI;

    SELECT id_guia, nombre, apellido,
           CONVERT(VARCHAR(20), DECRYPTBYKEY(dni_cifrado)) AS dni,
           especialidad, vigencia_autorizacion
    FROM turismo.Guia
    WHERE (@p_id_guia IS NULL OR id_guia = @p_id_guia)
    ORDER BY id_guia;

    CLOSE SYMMETRIC KEY SK_DNI;
END
GO

PRINT '===========================================================';
PRINT ' Cifrado del DNI aplicado correctamente.';
PRINT '===========================================================';
GO
