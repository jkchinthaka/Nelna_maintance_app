-- ============================================================================
-- STEP 1: Run this as a sysadmin (Windows Auth / sa account)
-- Creates the database and grants nelna_user full access
-- ============================================================================
USE master;
GO

-- Create the database
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'nelna_maintenance')
BEGIN
    CREATE DATABASE nelna_maintenance
        COLLATE SQL_Latin1_General_CP1_CI_AS;
    PRINT 'Database nelna_maintenance created.';
END
ELSE
    PRINT 'Database nelna_maintenance already exists.';
GO

-- Grant nelna_user access as db_owner
USE nelna_maintenance;
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'nelna_user')
BEGIN
    CREATE USER nelna_user FOR LOGIN nelna_user;
    PRINT 'User nelna_user mapped.';
END
ALTER ROLE db_owner ADD MEMBER nelna_user;
PRINT 'nelna_user added to db_owner. Ready to create tables.';
GO
