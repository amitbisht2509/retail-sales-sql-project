--Problem Statement:
--“Management needs a centralized SQL-based system to analyze sales performance,
--identify top customers/products, and track revenue trends. Without these insights, 
--decision-making remains guesswork, affecting growth and profitability.”

--Data Analysis

--1. Total Revenue-
SELECT Round (SUM(od.Quantity * p.Price),2) AS TotalRevenue
FROM order_details od
JOIN Products p ON od.ProductID = p.ProductID;

--2. Revenue by Category 
SELECT p.Category, round(SUM(od.Quantity * p.Price),2) AS Revenue
FROM order_details od
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY p.Category
ORDER BY Revenue DESC;

--3. Top 10 Customers by Spend 
SELECT TOP 10 c.CustomerID, c.FirstName, c.LastName,
       round(SUM(od.Quantity * p.Price),2) AS TotalSpent
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN order_details od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY TotalSpent DESC;

--4. Monthly Sales Trend 
SELECT FORMAT(o.OrderDate, 'yyyy-MM') AS Month,
       Round(SUM(od.Quantity * p.Price),2) AS Revenue
FROM Orders o
JOIN order_details od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY FORMAT(o.OrderDate, 'yyyy-MM')
ORDER BY Month;

--5. Average Order Value 
SELECT Round(AVG(OrderTotal),2) AS AvgOrderValue
FROM (
    SELECT o.OrderID, SUM(od.Quantity * p.Price) AS OrderTotal
    FROM Orders o
    JOIN order_details od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY o.OrderID
) t;

--6. Repeat Customers 
SELECT c.CustomerID, c.FirstName, c.LastName, COUNT(o.OrderID) AS OrdersCount
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName
HAVING COUNT(o.OrderID) > 1
ORDER BY OrdersCount DESC;

--7. Top 5 Products in Each Category 
SELECT Category, ProductName, TotalRevenue
FROM (
    SELECT p.Category, p.ProductName,
           Round(SUM(od.Quantity * p.Price),2) AS TotalRevenue,
           RANK() OVER (PARTITION BY p.Category ORDER BY SUM(od.Quantity * p.Price) DESC) AS rnk
    FROM order_details od
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY p.Category, p.ProductName
) t
WHERE rnk <= 5;

--8. Customer Segmentation 
SELECT c.CustomerID, c.FirstName, c.LastName,
       SUM(od.Quantity * p.Price) AS TotalSpent,
       CASE 
           WHEN SUM(od.Quantity * p.Price) > 5000 THEN 'Platinum'
           WHEN SUM(od.Quantity * p.Price) BETWEEN 2000 AND 5000 THEN 'Gold'
           WHEN SUM(od.Quantity * p.Price) BETWEEN 1000 AND 2000 THEN 'Silver'
           ELSE 'Bronze'
       END AS CustomerSegment
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN order_details od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY TotalSpent DESC;

--9. Year-over-Year Revenue Growth 
SELECT Year, round(Revenue, 2) as total_revenue,
       round(LAG(Revenue) OVER (ORDER BY Year),2) AS PrevYearRevenue,
       round((Revenue - LAG(Revenue) OVER (ORDER BY Year)) * 100.0 / LAG(Revenue) OVER (ORDER BY Year),2) AS YoY_Growth_Percent
FROM (
    SELECT YEAR(o.OrderDate) AS Year, 
           SUM(od.Quantity * p.Price) AS Revenue
    FROM Orders o
    JOIN order_details od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY YEAR(o.OrderDate)
) t;

--10. Best City-Country Combo 
with most_revenue as (SELECT Country, City, round(SUM(od.Quantity * p.Price),2) AS Revenue,
       RANK() OVER (PARTITION BY Country ORDER BY SUM(od.Quantity * p.Price) DESC) AS CityRank
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN order_details od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY Country, City
)

select * from most_revenue
where CityRank = 1
order by CityRank;
