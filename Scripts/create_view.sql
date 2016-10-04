IF EXISTS(SELECT * FROM sys.objects WHERE [type] = 'v' AND name = 'CompleteOrderInfo' ) DROP VIEW CompleteOrderInfo 
go
CREATE VIEW CompleteOrderInfo
AS
SELECT ol.OrderID, o.OrderDate, ol.ProductID, ol.Quantity, o.CustName, o.CustAddress
From OrderLines ol
INNER JOIN Orders o
ON ol.OrderID = o.ID
