USE AdventureWorks2008R2;

-- 3-1

 /* Modify the following query to add a column that identifies the
 performance of salespersons and contains the following feedback
 based on the number of orders processed by a salesperson:
 'Need to Work Hard' for the order count range 1-100
 'Fine' for the order count range of 101-300
 'Strong Performer' for the order count greater than 300
Give the new column an alias to make the report more readable.
*/

 SELECT SalesPersonID, p.LastName, p.FirstName,
 COUNT(o.SalesOrderid) [Total Orders],
 CASE 
    WHEN COUNT(o.SalesOrderid) BETWEEN 1 AND 100
    THEN  'Need to Work Hard'
    WHEN COUNT(o.SalesOrderid) BETWEEN 101 AND 300
    THEN  'Fine'
    WHEN COUNT(o.SalesOrderid) > 300
    THEN  'Strong Performer'
 END AS [Performance Review]
 FROM Sales.SalesOrderHeader o
    JOIN Person.Person p
    ON o.SalesPersonID = p.BusinessEntityID
 GROUP BY o.SalesPersonID, p.LastName, p.FirstName
 
 -- 3-2

/* Modify the following query to add a rank without gaps in the
 ranking based on total orders in the descending order. Also
 partition by territory.*/

 SELECT 
 DENSE_RANK() OVER (PARTITION BY o.TerritoryID ORDER BY COUNT(o.SalesOrderid) DESC) AS Rank,
 o.TerritoryID, s.Name, year(o.OrderDate) Year,
 COUNT(o.SalesOrderid) [Total Orders]
 FROM Sales.SalesTerritory s
    JOIN Sales.SalesOrderHeader o
    ON s.TerritoryID = o.TerritoryID
 GROUP BY o.TerritoryID, s.Name, year(o.OrderDate)
 ORDER BY o.TerritoryID;
 
 -- 3-3

/* Write a query that returns the male salesperson(s) who received
 the lowest bonus amount in Europe. Include the salesperson's
 id and bonus amount in the returned data. Your solution must
 retrieve the tie if there is a tie. */

SELECT  SalesPersonID AS [Salesperson's ID], Bonus AS [Bonus Amount]
FROM
    (SELECT DENSE_RANK() OVER (ORDER BY Bonus) AS Rank, 
    SOH.SalesPersonID, SP.Bonus, EMP.Gender, ST.[Group]
    FROM   Sales.SalesOrderHeader SOH 
        INNER JOIN Sales.SalesPerson SP ON SOH.SalesPersonID = sp.BusinessEntityID 
        INNER JOIN Sales.SalesTerritory ST ON SP.TerritoryID = ST.TerritoryID 
        INNER JOIN HumanResources.Employee EMP ON EMP.BusinessEntityID = SP.BusinessEntityID 
    WHERE ST.[GROUP] = 'EUROPE' AND EMP.Gender = 'M' 
    GROUP BY SOH.SalesPersonID, SP.Bonus, EMP.Gender, ST.[GROUP]
) TEMP
WHERE TEMP.Rank = 1 

-- 3-4

/* Write a query to retrieve the most valuable customer of each year.
The most valuable customer of a year is the customer who has
made the most purchase for the year. Use the yearly sum of the
TotalDue column in SalesOrderHeader as a customer's total purchase
for a year. If there is a tie for the most valuable customer,
your solution should retrieve it.
 Include the customer's id, total purchase, and total order count
 for the year. Display the total purchase in two decimal places.
 Sort the returned data by the year. */

SELECT [Year], CustomerID, [Total Purchase], [Total Order Count]
FROM    (SELECT   DENSE_RANK() OVER (PARTITION BY YEAR(OrderDate) ORDER BY SUM(TotalDue) DESC) AS Rank,
        YEAR(OrderDate) AS Year, CustomerID, CAST(ROUND(SUM(TotalDue),2) AS DECIMAL(10,2)) AS [Total Purchase], 
        COUNT(SalesOrderID)AS [Total Order Count]
        FROM  Sales.SalesOrderHeader  
        GROUP BY YEAR(OrderDate), CustomerID
        ) TEMP1
WHERE TEMP1.Rank = 1
ORDER BY [Year]

-- 3-5

/* Write a query to retrieve the dates in which there was
 at least one product sold but no product in red
 was sold.
 Return the "date" and "total product quantity sold
 for the date" columns. The order quantity can be found in
 SalesOrderDetail. Display only the date for a date.
 Sort the returned data by the
 "total product quantity sold for the date" column in desc. */

SELECT CAST(SOH.OrderDate AS DATE) AS [Order Date], SUM(SOD.OrderQty) AS [Total Products Sold]
FROM Sales.SalesOrderHeader  SOH 
    INNER JOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
WHERE SOH.OrderDate NOT IN (
    SELECT CAST(SOH.OrderDate AS DATE) FROM Sales.SalesOrderHeader  SOH 
    INNER JOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
    WHERE SOD.ProductID IN (SELECT ProductID FROM Production.Product WHERE Color = 'RED')) 
GROUP BY CAST(SOH.OrderDate AS DATE)
HAVING SUM(SOD.OrderQty) > 0 
ORDER BY SUM(SOD.OrderQty) DESC
