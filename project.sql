IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = 'CentralSuperStoreDB')
begin
    CREATE DATABASE CentralSuperStoreDB;
end
GO
USE CentralSuperStoreDB;
SELECT *
FROM sys.schemas;

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'staging')
    EXEC('CREATE SCHEMA staging');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'bronze')
    EXEC('CREATE SCHEMA bronze');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'silver')
    EXEC('CREATE SCHEMA silver');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
    EXEC('CREATE SCHEMA gold');
GO




