--***************************************************************************************************************************
--***************************************************************************************************************************
--1. List all Products with “Juice” in the name and the total Quantity ever ordered (even if it’s zero). 
--Done

				SELECT p.[Name], Total_Quantity = SUM(COALESCE(o.Quantity,0))
				FROM Products p
				LEFT OUTER JOIN OrderLines o 
				ON p.ID = o.ProductID
				WHERE p.Name LIKE '%Juice%' 
				GROUP BY p.[Name]

--***************************************************************************************************************************
--***************************************************************************************************************************
--2. Delete the 5 highest priced Products that have not appeared on an Order in the last 24 months. 
--fixed data to accomodate this
--Need to redo data
				DECLARE @DataEndDate as DATE = '20151231' --I am assuming that this is the last date that we have data for.
				DECLARE @Prev24MonthDate as DATE = DATEADD(MONTH,-24,@DataEndDate)

				;WITH HighestPricedNonSellingItems AS (
				SELECT TOP 5 * 
				FROM Products p
				WHERE NOT EXISTS
					(SELECT * 
					FROM CompleteOrderInfo coi
					WHERE coi.ProductID = p.ID AND coi.OrderDate > @Prev24MonthDate
					)
				ORDER BY p.Price DESC
				)

				DELETE p
				FROM Products p
				INNER JOIN HighestPricedNonSellingItems hpnsi
				ON p.ID = hpnsi.ID

				--Deleted items 2,6,4,9,10


--***************************************************************************************************************************
--***************************************************************************************************************************
--3. Generate a username for each unique Customer according to: “first 6 characters of last name” + “first initial” + “last 2 digits of their first Order ID” 

				-- I did as told but I don't think it is a good idea to base a key off of a name.
 
				;WITH FirstOrderID AS (
				SELECT o.CustName, FirstID = o.ID, OrderNumber = ROW_NUMBER() OVER (PARTITION BY CustName ORDER BY o.OrderDate)
				From Orders o
				)

				SELECT DISTINCT 
					fo.FirstID
				   ,UserName = LEFT(RIGHT(o.CustName, CHARINDEX(' ', REVERSE(o.CustName))-1),6) + LEFT(o.CustName,1) + RIGHT(CAST('0' as CHAR(1)) + CAST(fo.FirstID AS VARCHAR(4)),2)
				FROM Orders o
				INNER JOIN FirstOrderID fo
				ON o.CustName = fo.CustName
				WHERE OrderNumber = 1

--***************************************************************************************************************************
--***************************************************************************************************************************
--Question 4
--4. For each of the past 6 months, list the Product with the highest Quantity sold and what percentage of that month’s total dollar amount came from that Product. 
--DONE
				DECLARE @DataEndDate as DATE = '20151231' --I am assuming that this is the last date that we have data for.
				DECLARE @Prev6MonthDate as DATE = DATEADD(MONTH,-6,@DataEndDate)

				;WITH CalcHighestQuantitySold_A AS (
				SELECT 
					 ol.ProductID
					,[Month] = FORMAT(o.OrderDate,'yyyyMM')
					,TotalQuantity = SUM(ol.Quantity)
				FROM OrderLines ol
				INNER JOIN Orders o
				ON ol.OrderID = o.ID
				WHERE o.OrderDate > @Prev6MonthDate
				GROUP BY 
					 ol.ProductID
					,FORMAT(o.OrderDate,'yyyyMM')
				),

				CalcHighestQuantitySold_B AS (
				SELECT
					 hqs.[Month]
					,hqs.ProductID
					,ProductRank = RANK() OVER(PARTITION BY hqs.[Month] ORDER BY hqs.TotalQuantity DESC)
					,hqs.TotalQuantity
					,PercentMonthQuantity = (hqs.TotalQuantity * 1.0) / (SUM(hqs.TotalQuantity) OVER(PARTITION BY hqs.[Month])) 
				FROM CalcHighestQuantitySold_A hqs
				)

				SELECT 
					 chqs.[Month]
					,chqs.ProductID
					,ProductName = p.[Name]
					,chqs.ProductRank
					,chqs.TotalQuantity
					,chqs.PercentMonthQuantity
				FROM CalcHighestQuantitySold_B chqs
				INNER JOIN Products p
				ON chqs.ProductID = p.ID
				WHERE chqs.ProductRank = 1

--***************************************************************************************************************************
--***************************************************************************************************************************
--5. Describe how to load a CSV file of Product Names and Prices into into the Products_Staging table. 

			--1. Create the table structure in SQL Server
			--2. Run the following SQL Statement (you may need to make minor modification based on the csv file)

			--		BULK INSERT Product_Staging
			--		FROM '<full file path of csv file>'
			--		WITH (FIELDTERMINATOR = ',', ROWTERMINATOR = '\n')
			--
			--   I could also develop a SSIS package to do this but it will be over kill for a ETL task this simple

--***************************************************************************************************************************
--***************************************************************************************************************************
--6. Assume that new data has been loaded into Product_Staging. Update the Products table with any new items or changed prices from Product_Staging. Then remove the staging table. 

			MERGE INTO Products tgt
			USING Products_Staging src
			ON tgt.[Name] = src.[Name]
			WHEN MATCHED THEN
				UPDATE SET
					tgt.Price = src.Price
			WHEN NOT MATCHED THEN
				INSERT ([Name], Price)
				VALUES (src.[Name], src.Price);

			DROP TABLE Products_Staging

--***************************************************************************************************************************
--***************************************************************************************************************************
--7. In some Orders, a Product will be referenced on multiple OrderLines. Combine these lines together so each Order has at most one OrderLine per Product. 

			-- I will accomplish this by using a CTE to combine the data at the order & product level then create a new table with that data
			-- using the "INSERT INTO" method. If the data in the new table is correct I would drop the original table and rename the temp table 
			-- that I created
			IF EXISTS(SELECT * FROM sys.objects WHERE [type] = 'u' AND name = 'OrderLines_temp' )
				DROP TABLE OrderLines_temp 

			;WITH DistinctOrderLine AS (
			SELECT  
				 OrderID
				,ProductID
				,Quantity = SUM(ol.Quantity)
			FROM OrderLines ol
			GROUP BY 
				 OrderID
				,ProductID
			)

			SELECT
				 ID = ROW_NUMBER() OVER(ORDER BY (SELECT NULL))
				,dol.OrderID
				,dol.ProductID
				,dol.Quantity
			INTO OrderLines_temp
			FROM DistinctOrderLine dol
 
            GO

			DROP TABLE OrderLines

			GO

			EXEC sp_rename 'OrderLines_temp', 'OrderLines';

--***************************************************************************************************************************
--***************************************************************************************************************************
--8. What change could we make to the database to prevent the scenario in task #7? 

			-- I would add a constraint to the table based on the OrdersID and ProductID using code like the following:
			--
			--
			ALTER TABLE OrderLines ADD CONSTRAINT uq_OrderLines_OrderID_ProductID UNIQUE(OrderID, ProductID);

--***************************************************************************************************************************
--***************************************************************************************************************************
--9. Refactor Orders to move the Customer information to a new (normalized) Customers table. Show how to migrate the customer data from Orders to Customers. 
--DONE

			IF EXISTS(SELECT * FROM sys.objects WHERE [type] = 'u' AND name = 'Customers' )
				DROP TABLE Customers 

			;WITH DistinctCustomers AS (
			SELECT DISTINCT CustName, CustAddress
			FROM Orders
			)

			SELECT 
				 ID = ROW_NUMBER()OVER(ORDER BY (SELECT NULL))
				,ds.CustName
				,ds.CustAddress
			INTO Customers
			FROM DistinctCustomers ds

--***************************************************************************************************************************
--***************************************************************************************************************************
--10. A user complains that one of their Orders reports has started running very slowly. How would you diagnose and fix the issue? 
--
--		Determine what fields are being used the most in the joins and which joins are being used the most in the calculations. Then I 
--      would come up with an indexing strategy to accomodate the usage. If I was using SQL 2016 I would use the "Query Store" to help 
--      me diagnose the problem.

 
