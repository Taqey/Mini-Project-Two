IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = 'CentralSuperStoreDB')
    CREATE DATABASE CentralSuperStoreDB;

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

--staging phase
IF OBJECT_ID('staging.RawData', 'U') IS NULL
BEGIN
    CREATE TABLE staging.RawData
    (
        RowID NVARCHAR(255),
        OrderID NVARCHAR(255),
    OrderDate NVARCHAR(255),
    ShipDate NVARCHAR(255),
    ShipMode NVARCHAR(255),
    CustomerID NVARCHAR(255),
    CustomerName NVARCHAR(255),
    Segment NVARCHAR(255),
    Country NVARCHAR(255),
    City NVARCHAR(255),
    State NVARCHAR(255),
    PostalCode NVARCHAR(255),
    Region NVARCHAR(255),
    ProductID NVARCHAR(255),
    Category NVARCHAR(255),
    SubCategory NVARCHAR(255),
    ProductName NVARCHAR(255),
    Sales NVARCHAR(255),
    Quantity NVARCHAR(255),
    Discount NVARCHAR(255),
    Profit NVARCHAR(255)
);
select * from staging.RawData;


truncate table staging.RawData;

bulk insert staging.RawData
from 'D:\Data Analysis\sql\MINI PROJECT\Central_Superstore.csv'
WITH (
 FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    MAXERRORS = 0,
    ERRORFILE = 'D:\Data Analysis\sql\MINI PROJECT\RawDataLogs.log'
);

select * from staging.RawData;

--bronze phase
IF OBJECT_ID('bronze.RawData', 'U') IS NULL
BEGIN

 CREATE  TABLE bronze.RawData
(
    BronzeID INT IDENTITY(1,1) PRIMARY KEY,
    RowID NVARCHAR(255),
    OrderID NVARCHAR(255),
    OrderDate NVARCHAR(255),
    ShipDate NVARCHAR(255),
    ShipMode NVARCHAR(255),
    CustomerID NVARCHAR(255),
    CustomerName NVARCHAR(255),
    Segment NVARCHAR(255),
    Country NVARCHAR(255),
    City NVARCHAR(255),
    State NVARCHAR(255),
    PostalCode NVARCHAR(255),
    Region NVARCHAR(255),
    ProductID NVARCHAR(255),
    Category NVARCHAR(255),
    SubCategory NVARCHAR(255),
    ProductName NVARCHAR(255),
    Sales NVARCHAR(255),
    Quantity NVARCHAR(255),
    Discount NVARCHAR(255),
    Profit NVARCHAR(255)
)
END;
INSERT INTO bronze.RawData
(
    RowID,
    OrderID,
    OrderDate,
    ShipDate,
    ShipMode,
    CustomerID,
    CustomerName,
    Segment,
    Country,
    City,
    State,
    PostalCode,
    Region,
    ProductID,
    Category,
    SubCategory,
    ProductName,
    Sales,
    Quantity,
    Discount,
    Profit
)
SELECT
    RowID,
    OrderID,
    OrderDate,
    ShipDate,
    ShipMode,
    CustomerID,
    CustomerName,
    Segment,
    Country,
    City,
    State,
    PostalCode,
    Region,
    ProductID,
    Category,
    SubCategory,
    ProductName,
    Sales,
    Quantity,
    Discount,
    Profit
FROM staging.RawData

EXCEPT

SELECT
    RowID,
    OrderID,
    OrderDate,
    ShipDate,
    ShipMode,
    CustomerID,
    CustomerName,
    Segment,
    Country,
    City,
    State,
    PostalCode,
    Region,
    ProductID,
    Category,
    SubCategory,
    ProductName,
    Sales,
    Quantity,
    Discount,
    Profit
FROM bronze.RawData;

select * from bronze.RawData;

IF OBJECT_ID('silver.RawData', 'U') IS NULL
BEGIN
CREATE TABLE silver.RawData
(
    RowID           NVARCHAR(255),
    OrderID         NVARCHAR(50),
    OrderDate       DATE,
    ShipDate        DATE,
    ShipMode        NVARCHAR(50),
    CustomerID      NVARCHAR(50),
    CustomerName    NVARCHAR(50),
    Segment         NVARCHAR(50),
    Country         NVARCHAR(50),
    City            NVARCHAR(50),
    State           NVARCHAR(50),
    PostalCode      NVARCHAR(10),
    Region          NVARCHAR(50),
    ProductID       NVARCHAR(50),
    Category        NVARCHAR(50),
    SubCategory     NVARCHAR(50),
    ProductName     NVARCHAR(255),   
    Sales           DECIMAL(18, 2),  
    Quantity        INT,
    Discount        DECIMAL(18, 2),
    Profit          DECIMAL(18, 2),   
    HasMissingValue BIT NOT NULL DEFAULT 0,
    HasInvalidValue BIT NOT NULL DEFAULT 0,
    HasOutlierValue BIT NOT NULL DEFAULT 0,
    CONSTRAINT PK_silver_RawData PRIMARY KEY (RowID)
)
END;
with BronzeLatest as (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY RowID ORDER BY BronzeID DESC) AS rn
    FROM bronze.RawData
),cleaned AS (
    SELECT
        LTRIM(RTRIM(RowID)) AS RowID,

        NULLIF(LTRIM(RTRIM(OrderID)), '') AS OrderID,

        TRY_CAST(NULLIF(LTRIM(RTRIM(OrderDate)), '') AS DATE) AS OrderDate,
        NULLIF(LTRIM(RTRIM(OrderDate)), '') AS raw_OrderDate,

        TRY_CAST(NULLIF(LTRIM(RTRIM(ShipDate)), '') AS DATE) AS ShipDate,
        NULLIF(LTRIM(RTRIM(ShipDate)), '') AS raw_ShipDate,

        NULLIF(LTRIM(RTRIM(ShipMode)), '') AS ShipMode,

        NULLIF(LTRIM(RTRIM(CustomerID)), '') AS CustomerID,

        NULLIF(LTRIM(RTRIM(CustomerName)), '') AS CustomerName,

        NULLIF(LTRIM(RTRIM(Segment)), '') AS Segment,

        NULLIF(LTRIM(RTRIM(Country)), '') AS Country,

        NULLIF(LTRIM(RTRIM(City)), '') AS City,

        NULLIF(LTRIM(RTRIM(State)), '') AS State,

        NULLIF(LTRIM(RTRIM(PostalCode)), '') AS PostalCode,

        NULLIF(LTRIM(RTRIM(Region)), '') AS Region,

        NULLIF(LTRIM(RTRIM(ProductID)), '') AS ProductID,

        NULLIF(LTRIM(RTRIM(Category)), '') AS Category,

        NULLIF(LTRIM(RTRIM(SubCategory)), '') AS SubCategory,

        NULLIF(LTRIM(RTRIM(ProductName)), '') AS ProductName,

        TRY_CAST(NULLIF(LTRIM(RTRIM(Sales)), '') AS DECIMAL(18,2)) AS Sales,
        NULLIF(LTRIM(RTRIM(Sales)), '') AS raw_Sales,

        TRY_CAST(NULLIF(LTRIM(RTRIM(Quantity)), '') AS INT) AS Quantity,
        NULLIF(LTRIM(RTRIM(Quantity)), '') AS raw_Quantity,

        TRY_CAST(NULLIF(LTRIM(RTRIM(Discount)), '') AS DECIMAL(18,2)) AS Discount,
        NULLIF(LTRIM(RTRIM(Discount)), '') AS raw_Discount,

        TRY_CAST(NULLIF(LTRIM(RTRIM(Profit)), '') AS DECIMAL(18,2)) AS Profit,
        NULLIF(LTRIM(RTRIM(Profit)), '') AS raw_Profit
    FROM BronzeLatest
    WHERE rn = 1
),IQRBounds AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Sales) OVER () AS q1_Sales,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Sales) OVER () AS q3_Sales,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Profit) OVER () AS q1_Profit,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Profit) OVER () AS q3_Profit,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Discount) OVER () AS q1_Discount,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Discount) OVER () AS q3_Discount
    FROM cleaned
),flagged AS (
    SELECT
        c.RowID,
        c.OrderID,
        c.OrderDate,
        c.ShipDate,
        c.ShipMode,
        c.CustomerID,
        c.CustomerName,
        c.Segment,
        c.Country,
        c.City,
        c.State,
        c.PostalCode,
        c.Region,
        c.ProductID,
        c.Category,
        c.SubCategory,
        c.ProductName,
        c.Sales,
        c.Quantity,
        c.Discount,
        c.Profit,
        CASE WHEN
            OrderID IS NULL
        OR OrderDate IS NULL
        OR CustomerID IS NULL
        OR ProductID IS NULL
        OR Sales IS NULL
        OR Quantity IS NULL
        THEN 1 ELSE 0 END AS HasMissingValue,
        CASE WHEN
            raw_OrderDate IS NOT NULL AND OrderDate IS NULL
        OR raw_ShipDate IS NOT NULL AND ShipDate IS NULL
        OR raw_Sales IS NOT NULL AND Sales IS NULL
        OR raw_Quantity IS NOT NULL AND Quantity IS NULL
        OR raw_Discount IS NOT NULL AND Discount IS NULL
        OR raw_Profit IS NOT NULL AND Profit IS NULL
        OR (Quantity IS NOT NULL AND Quantity <= 0)
        OR (Discount IS NOT NULL AND (Discount < 0 OR Discount > 1))
        OR (Sales IS NOT NULL AND Sales < 0)
        OR (ShipDate IS NOT NULL AND OrderDate IS NOT NULL AND ShipDate < OrderDate)
        THEN 1 ELSE 0 END AS HasInvalidValue,
        CASE WHEN
            (Sales IS NOT NULL AND (
                Sales < q1_Sales - 1.5 * (q3_Sales - q1_Sales)
                OR Sales > q3_Sales + 1.5 * (q3_Sales - q1_Sales)
            ))
        OR (Profit IS NOT NULL AND (
                Profit < q1_Profit - 1.5 * (q3_Profit - q1_Profit)
                OR Profit > q3_Profit + 1.5 * (q3_Profit - q1_Profit)
            ))
        OR (Discount IS NOT NULL AND (
                Discount < q1_Discount - 1.5 * (q3_Discount - q1_Discount)
                OR Discount > q3_Discount + 1.5 * (q3_Discount - q1_Discount)
            ))
        THEN 1 ELSE 0 END AS HasOutlierValue   
    FROM cleaned c
    CROSS JOIN IQRBounds b
)MERGE silver.RawData AS tgt
USING flagged AS src
ON tgt.RowID = src.RowID
WHEN MATCHED THEN
    UPDATE SET
        tgt.OrderID = src.OrderID,
        tgt.OrderDate = src.OrderDate,
        tgt.ShipDate = src.ShipDate,
        tgt.ShipMode = src.ShipMode,
        tgt.CustomerID = src.CustomerID,
        tgt.CustomerName = src.CustomerName,
        tgt.Segment = src.Segment,
        tgt.Country = src.Country,
        tgt.City = src.City,
        tgt.State = src.State,
        tgt.PostalCode = src.PostalCode,
        tgt.Region = src.Region,
        tgt.ProductID = src.ProductID,
        tgt.Category = src.Category,
        tgt.SubCategory = src.SubCategory,
        tgt.ProductName = src.ProductName,
        tgt.Sales = src.Sales,
        tgt.Quantity = src.Quantity,
        tgt.Discount = src.Discount,
        tgt.Profit = src.Profit,
        tgt.HasMissingValue = src.HasMissingValue,
        tgt.HasInvalidValue = src.HasInvalidValue,
        tgt.HasOutlierValue = src.HasOutlierValue
WHEN NOT MATCHED THEN
    INSERT (RowID, OrderID, OrderDate, ShipDate, ShipMode, CustomerID, CustomerName,
            Segment, Country, City, State, PostalCode, Region, ProductID, Category,
            SubCategory, ProductName, Sales, Quantity, Discount, Profit,
            HasMissingValue, HasInvalidValue, HasOutlierValue)
    VALUES (src.RowID, src.OrderID, src.OrderDate, src.ShipDate, src.ShipMode, src.CustomerID,
            src.CustomerName, src.Segment, src.Country, src.City, src.State, src.PostalCode,
            src.Region, src.ProductID, src.Category, src.SubCategory, src.ProductName,
            src.Sales, src.Quantity, src.Discount, src.Profit,
            src.HasMissingValue, src.HasInvalidValue, src.HasOutlierValue);

SELECT * FROM silver.RawData;