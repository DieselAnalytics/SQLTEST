IF EXISTS(SELECT * FROM sys.objects WHERE [type] = 'u' AND name = 'Orders' ) DROP TABLE Orders 
CREATE TABLE Orders (
ID int,
CustName varchar(200),
CustAddress varchar(500),
OrderDate Datetime,
)

IF EXISTS(SELECT * FROM sys.objects WHERE [type] = 'u' AND name = 'Products' ) DROP TABLE Products 
CREATE TABLE Products (
ID int,
[Name] varchar(200),
Price decimal(6,2)
)

IF EXISTS(SELECT * FROM sys.objects WHERE [type] = 'u' AND name = 'OrderLines' ) DROP TABLE OrderLines 
CREATE TABLE OrderLines (
ID int,
OrderID int,
ProductID int,
Quantity int
)

IF EXISTS(SELECT * FROM sys.objects WHERE [type] = 'u' AND name = 'Products_Staging' ) DROP TABLE Products_Staging 
CREATE TABLE Products_Staging (
[Name] varchar(200),
Price decimal(6,2)
)
