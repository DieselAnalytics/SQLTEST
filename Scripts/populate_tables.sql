TRUNCATE TABLE Orders 
BULK
 INSERT Orders
FROM '<your root path>\Orders.csv'
WITH
(
FIELDTERMINATOR = ',',
ROWTERMINATOR = '\n',
FIRSTROW = 2
)

TRUNCATE TABLE  OrderLines
BULK
 INSERT OrderLines
FROM '<your root path>\OrderLines.csv'
WITH
(
FIELDTERMINATOR = ',',
ROWTERMINATOR = '\n',
FIRSTROW = 2
)

TRUNCATE TABLE Products
BULK
 INSERT Products
FROM '<your root path>\Products.csv'
WITH
(
FIELDTERMINATOR = ',',
ROWTERMINATOR = '\n',
FIRSTROW = 2
)

TRUNCATE TABLE Products_Staging
BULK
 INSERT Products_Staging
FROM '<your root path>\Product_Staging.csv'
WITH
(
FIELDTERMINATOR = ',',
ROWTERMINATOR = '\n',
FIRSTROW = 2
)
