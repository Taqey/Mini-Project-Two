USE CentralSuperStoreDB;
GO

CREATE OR ALTER PROCEDURE bronze.usp_LoadBronze
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID('bronze.RawData', 'U') IS NULL
    BEGIN
        CREATE TABLE bronze.RawData
        (
            BronzeID     INT IDENTITY(1,1) PRIMARY KEY,
            RowID        NVARCHAR(255),
            OrderID      NVARCHAR(255),
            OrderDate    NVARCHAR(255),
            ShipDate     NVARCHAR(255),
            ShipMode     NVARCHAR(255),
            CustomerID   NVARCHAR(255),
            CustomerName NVARCHAR(255),
            Segment      NVARCHAR(255),
            Country      NVARCHAR(255),
            City         NVARCHAR(255),
            State        NVARCHAR(255),
            PostalCode   NVARCHAR(255),
            Region       NVARCHAR(255),
            ProductID    NVARCHAR(255),
            Category     NVARCHAR(255),
            SubCategory  NVARCHAR(255),
            ProductName  NVARCHAR(255),
            Sales        NVARCHAR(255),
            Quantity     NVARCHAR(255),
            Discount     NVARCHAR(255),
            Profit       NVARCHAR(255)
        );
    END;

    INSERT INTO bronze.RawData
    (
        RowID, OrderID, OrderDate, ShipDate, ShipMode, CustomerID, CustomerName,
        Segment, Country, City, State, PostalCode, Region, ProductID, Category,
        SubCategory, ProductName, Sales, Quantity, Discount, Profit
    )
    SELECT
        RowID, OrderID, OrderDate, ShipDate, ShipMode, CustomerID, CustomerName,
        Segment, Country, City, State, PostalCode, Region, ProductID, Category,
        SubCategory, ProductName, Sales, Quantity, Discount, Profit
    FROM staging.RawData
    EXCEPT
    SELECT
        RowID, OrderID, OrderDate, ShipDate, ShipMode, CustomerID, CustomerName,
        Segment, Country, City, State, PostalCode, Region, ProductID, Category,
        SubCategory, ProductName, Sales, Quantity, Discount, Profit
    FROM bronze.RawData;
END;
GO