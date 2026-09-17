USE CentralSuperStoreDB;
GO

CREATE OR ALTER PROCEDURE dbo.usp_RunFullPipeline
    @FilePath NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        EXEC staging.usp_LoadStaging @FilePath = @FilePath;
        EXEC bronze.usp_LoadBronze;
        EXEC silver.usp_LoadSilver;
        EXEC gold.usp_LoadGold;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO