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