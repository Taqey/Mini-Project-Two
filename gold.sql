USE CentralSuperStoreDB;

-- =========================================================
-- DIM CUSTOMER
-- =========================================================
IF OBJECT_ID('gold.DIMCustomer', 'U') IS NULL
BEGIN
    CREATE TABLE gold.DIMCustomer
    (
        CustomerKey  INT IDENTITY(1,1) PRIMARY KEY,
        CustomerID   NVARCHAR(50),
        CustomerName NVARCHAR(50),
        Segment      NVARCHAR(50)
    )
END;
GO

CREATE OR ALTER VIEW gold.vw_DIMCustomerStaging AS
SELECT DISTINCT s.CustomerID, s.CustomerName, s.Segment
FROM silver.RawData s
WHERE NOT EXISTS (
    SELECT 1 FROM gold.DIMCustomer d WHERE d.CustomerID = s.CustomerID
);
GO

INSERT INTO gold.DIMCustomer (CustomerID, CustomerName, Segment)
SELECT CustomerID, CustomerName, Segment
FROM gold.vw_DIMCustomerStaging;
GO


-- =========================================================
-- DIM PRODUCT
-- =========================================================
IF OBJECT_ID('gold.DIMProduct', 'U') IS NULL
BEGIN
    CREATE TABLE gold.DIMProduct
    (
        ProductKey  INT IDENTITY(1,1) PRIMARY KEY,
        ProductID   NVARCHAR(50),
        ProductName NVARCHAR(255),
        Category    NVARCHAR(50),
        SubCategory NVARCHAR(50)
    )
END;
GO

CREATE OR ALTER VIEW gold.vw_DIMProductStaging AS
SELECT DISTINCT s.ProductID, s.ProductName, s.Category, s.SubCategory
FROM silver.RawData s
WHERE NOT EXISTS (
    SELECT 1 FROM gold.DIMProduct d WHERE d.ProductID = s.ProductID
);
GO

INSERT INTO gold.DIMProduct (ProductID, ProductName, Category, SubCategory)
SELECT ProductID, ProductName, Category, SubCategory
FROM gold.vw_DIMProductStaging;
GO


-- =========================================================
-- DIM GEOGRAPHY
-- =========================================================
IF OBJECT_ID('gold.DIMGeography', 'U') IS NULL
BEGIN
    CREATE TABLE gold.DIMGeography
    (
        GeographyKey INT IDENTITY(1,1) PRIMARY KEY,
        Country      NVARCHAR(50),
        City         NVARCHAR(50),
        State        NVARCHAR(50),
        PostalCode   NVARCHAR(10),
        Region       NVARCHAR(50)
    )
END;
GO

CREATE OR ALTER VIEW gold.vw_DIMGeographyStaging AS
SELECT DISTINCT s.Country, s.City, s.State, s.PostalCode, s.Region
FROM silver.RawData s
WHERE NOT EXISTS (
    SELECT 1 FROM gold.DIMGeography d
    WHERE  d.Country    = s.Country
    AND    d.City       = s.City
    AND    d.State      = s.State
    AND    d.PostalCode = s.PostalCode
    AND    d.Region     = s.Region
);
GO

INSERT INTO gold.DIMGeography (Country, City, State, PostalCode, Region)
SELECT Country, City, State, PostalCode, Region
FROM gold.vw_DIMGeographyStaging;
GO


-- =========================================================
-- DIM SHIPPING
-- =========================================================
IF OBJECT_ID('gold.DIMShipping', 'U') IS NULL
BEGIN
    CREATE TABLE gold.DIMShipping
    (
        ShippingKey INT IDENTITY(1,1) PRIMARY KEY,
        ShipMode    NVARCHAR(50)
    )
END;
GO

CREATE OR ALTER VIEW gold.vw_DIMShippingStaging AS
SELECT DISTINCT s.ShipMode
FROM silver.RawData s
WHERE NOT EXISTS (
    SELECT 1 FROM gold.DIMShipping d WHERE d.ShipMode = s.ShipMode
);
GO

INSERT INTO gold.DIMShipping (ShipMode)
SELECT ShipMode
FROM gold.vw_DIMShippingStaging;
GO


-- =========================================================
-- DIM DATE
-- =========================================================
IF OBJECT_ID('gold.DIMDate', 'U') IS NULL
BEGIN
    CREATE TABLE gold.DIMDate
    (
        DateKey INT PRIMARY KEY,   -- صيغة YYYYMMDD كـ surrogate key
        [Date]  DATE,
        [Year]  INT,
        Quarter INT,
        [Month] INT,
        [Day]   INT
    )
END;
GO

CREATE OR ALTER VIEW gold.vw_DIMDateStaging AS
SELECT
    CONVERT(INT, FORMAT(d.[Date], 'yyyyMMdd')) AS DateKey,
    d.[Date],
    YEAR(d.[Date])              AS [Year],
    DATEPART(QUARTER, d.[Date]) AS Quarter,
    MONTH(d.[Date])             AS [Month],
    DAY(d.[Date])               AS [Day]
FROM
(
    SELECT DISTINCT OrderDate AS [Date] FROM silver.RawData WHERE OrderDate IS NOT NULL
    UNION
    SELECT DISTINCT ShipDate AS [Date] FROM silver.RawData WHERE ShipDate IS NOT NULL
) d
WHERE NOT EXISTS (
    SELECT 1 FROM gold.DIMDate g WHERE g.DateKey = CONVERT(INT, FORMAT(d.[Date], 'yyyyMMdd'))
);
GO

INSERT INTO gold.DIMDate (DateKey, [Date], [Year], Quarter, [Month], [Day])
SELECT DateKey, [Date], [Year], Quarter, [Month], [Day]
FROM gold.vw_DIMDateStaging;
GO


-- =========================================================
-- FACT SALES
-- =========================================================
IF OBJECT_ID('gold.FactSales', 'U') IS NULL
BEGIN
    CREATE TABLE gold.FactSales
    (
        SalesKey     INT IDENTITY(1,1) PRIMARY KEY,
        RowID        NVARCHAR(255),
        OrderID      NVARCHAR(50),
        CustomerKey  INT,
        ProductKey   INT,
        GeographyKey INT,
        ShippingKey  INT,
        OrderDateKey INT,
        ShipDateKey  INT,
        Sales        DECIMAL(18,2),
        Quantity     INT,
        Discount     DECIMAL(18,2),
        Profit       DECIMAL(18,2),
        CONSTRAINT FK_FactSales_Customer  FOREIGN KEY (CustomerKey)  REFERENCES gold.DIMCustomer(CustomerKey),
        CONSTRAINT FK_FactSales_Product   FOREIGN KEY (ProductKey)   REFERENCES gold.DIMProduct(ProductKey),
        CONSTRAINT FK_FactSales_Geography FOREIGN KEY (GeographyKey) REFERENCES gold.DIMGeography(GeographyKey),
        CONSTRAINT FK_FactSales_Shipping  FOREIGN KEY (ShippingKey)  REFERENCES gold.DIMShipping(ShippingKey),
        CONSTRAINT FK_FactSales_OrderDate FOREIGN KEY (OrderDateKey) REFERENCES gold.DIMDate(DateKey),
        CONSTRAINT FK_FactSales_ShipDate  FOREIGN KEY (ShipDateKey)  REFERENCES gold.DIMDate(DateKey)
    )
END;
GO

CREATE OR ALTER VIEW gold.vw_FactSalesStaging AS
SELECT
    s.RowID,
    s.OrderID,
    c.CustomerKey,
    p.ProductKey,
    g.GeographyKey,
    sh.ShippingKey,
    CONVERT(INT, FORMAT(s.OrderDate, 'yyyyMMdd')) AS OrderDateKey,
    CONVERT(INT, FORMAT(s.ShipDate, 'yyyyMMdd'))  AS ShipDateKey,
    s.Sales,
    s.Quantity,
    s.Discount,
    s.Profit
FROM silver.RawData s
LEFT JOIN gold.DIMCustomer c
    ON s.CustomerID = c.CustomerID
LEFT JOIN gold.DIMProduct p
    ON s.ProductID = p.ProductID
LEFT JOIN gold.DIMGeography g
    ON  s.Country    = g.Country
    AND s.City       = g.City
    AND s.State      = g.State
    AND s.PostalCode = g.PostalCode
    AND s.Region     = g.Region
LEFT JOIN gold.DIMShipping sh
    ON s.ShipMode = sh.ShipMode
WHERE s.HasMissingValue = 0
  AND s.HasInvalidValue = 0;
GO

INSERT INTO gold.FactSales
(
    RowID, OrderID, CustomerKey, ProductKey, GeographyKey, ShippingKey,
    OrderDateKey, ShipDateKey, Sales, Quantity, Discount, Profit
)
SELECT
    v.RowID, v.OrderID, v.CustomerKey, v.ProductKey, v.GeographyKey, v.ShippingKey,
    v.OrderDateKey, v.ShipDateKey, v.Sales, v.Quantity, v.Discount, v.Profit
FROM gold.vw_FactSalesStaging v
WHERE NOT EXISTS (
    SELECT 1 FROM gold.FactSales f WHERE f.RowID = v.RowID
);
GO

SELECT * FROM gold.FactSales;