/*
Project: Commercial Sales Performance Analysis
File: 01_business_overview.sql
Author: Chetan Singh

Purpose:
Provide a high-level overview of commercial performance across revenue,
orders, customers, products, regions, channels and customer segments.
*/

USE CommercialSalesAnalysis;
GO

/* =========================================================
   1. Overall business performance
   ========================================================= */

SELECT
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    COUNT(DISTINCT o.CustomerID) AS ActiveCustomers,
    COUNT(DISTINCT oi.ProductID) AS ProductsSold,

    CAST(
        SUM(oi.Quantity * oi.UnitSellingPrice)
        AS DECIMAL(18,2)
    ) AS GrossRevenue,

    CAST(
        SUM(
            oi.Quantity
            * (oi.UnitSellingPrice - oi.UnitCost)
        )
        AS DECIMAL(18,2)
    ) AS GrossProfit,

    CAST(
        SUM(
            oi.Quantity
            * (oi.UnitSellingPrice - oi.UnitCost)
        )
        * 100.0
        /
        NULLIF(
            SUM(oi.Quantity * oi.UnitSellingPrice),
            0
        )
        AS DECIMAL(8,2)
    ) AS GrossMarginPercentage,

    CAST(
        SUM(oi.Quantity * oi.UnitSellingPrice)
        / NULLIF(COUNT(DISTINCT o.OrderID), 0)
        AS DECIMAL(18,2)
    ) AS AverageOrderValue

FROM dbo.Orders AS o

INNER JOIN dbo.OrderItems AS oi
    ON o.OrderID = oi.OrderID

WHERE o.OrderStatus <> 'Cancelled';
GO

/* =========================================================
   2. Annual performance
   ========================================================= */

SELECT
    YEAR(o.OrderDate) AS SalesYear,

    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    COUNT(DISTINCT o.CustomerID) AS ActiveCustomers,
    SUM(oi.Quantity) AS UnitsSold,

    CAST(
        SUM(oi.Quantity * oi.UnitSellingPrice)
        AS DECIMAL(18,2)
    ) AS GrossRevenue,

    CAST(
        SUM(
            oi.Quantity
            * (oi.UnitSellingPrice - oi.UnitCost)
        )
        AS DECIMAL(18,2)
    ) AS GrossProfit,

    CAST(
        SUM(
            oi.Quantity
            * (oi.UnitSellingPrice - oi.UnitCost)
        )
        * 100.0
        /
        NULLIF(
            SUM(oi.Quantity * oi.UnitSellingPrice),
            0
        )
        AS DECIMAL(8,2)
    ) AS GrossMarginPercentage

FROM dbo.Orders AS o

INNER JOIN dbo.OrderItems AS oi
    ON o.OrderID = oi.OrderID

WHERE o.OrderStatus <> 'Cancelled'

GROUP BY YEAR(o.OrderDate)

ORDER BY SalesYear;
GO

/* =========================================================
   3. Regional performance
   ========================================================= */

SELECT
    o.Region,

    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    COUNT(DISTINCT o.CustomerID) AS ActiveCustomers,
    SUM(oi.Quantity) AS UnitsSold,

    CAST(
        SUM(oi.Quantity * oi.UnitSellingPrice)
        AS DECIMAL(18,2)
    ) AS GrossRevenue,

    CAST(
        SUM(
            oi.Quantity
            * (oi.UnitSellingPrice - oi.UnitCost)
        )
        AS DECIMAL(18,2)
    ) AS GrossProfit,

    CAST(
        SUM(
            oi.Quantity
            * (oi.UnitSellingPrice - oi.UnitCost)
        )
        * 100.0
        /
        NULLIF(
            SUM(oi.Quantity * oi.UnitSellingPrice),
            0
        )
        AS DECIMAL(8,2)
    ) AS GrossMarginPercentage,

    CAST(
        SUM(oi.Quantity * oi.UnitSellingPrice)
        / NULLIF(COUNT(DISTINCT o.OrderID), 0)
        AS DECIMAL(18,2)
    ) AS AverageOrderValue

FROM dbo.Orders AS o

INNER JOIN dbo.OrderItems AS oi
    ON o.OrderID = oi.OrderID

WHERE o.OrderStatus <> 'Cancelled'

GROUP BY o.Region

ORDER BY GrossRevenue DESC;
GO

/* =========================================================
   4. Customer-segment performance
   ========================================================= */

SELECT
    c.CustomerSegment,

    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    COUNT(DISTINCT o.CustomerID) AS ActiveCustomers,
    SUM(oi.Quantity) AS UnitsSold,

    CAST(
        SUM(oi.Quantity * oi.UnitSellingPrice)
        AS DECIMAL(18,2)
    ) AS GrossRevenue,

    CAST(
        SUM(
            oi.Quantity
            * (oi.UnitSellingPrice - oi.UnitCost)
        )
        AS DECIMAL(18,2)
    ) AS GrossProfit,

    CAST(
        SUM(oi.Quantity * oi.UnitSellingPrice)
        / NULLIF(COUNT(DISTINCT o.OrderID), 0)
        AS DECIMAL(18,2)
    ) AS AverageOrderValue,

    CAST(
        AVG(oi.DiscountPercentage)
        AS DECIMAL(8,2)
    ) AS AverageDiscountPercentage

FROM dbo.Orders AS o

INNER JOIN dbo.OrderItems AS oi
    ON o.OrderID = oi.OrderID

INNER JOIN dbo.Customers AS c
    ON o.CustomerID = c.CustomerID

WHERE o.OrderStatus <> 'Cancelled'

GROUP BY c.CustomerSegment

ORDER BY GrossRevenue DESC;
GO

/* =========================================================
   5. Sales-channel performance
   ========================================================= */

SELECT
    o.SalesChannel,

    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    COUNT(DISTINCT o.CustomerID) AS ActiveCustomers,

    CAST(
        SUM(oi.Quantity * oi.UnitSellingPrice)
        AS DECIMAL(18,2)
    ) AS GrossRevenue,

    CAST(
        SUM(
            oi.Quantity
            * (oi.UnitSellingPrice - oi.UnitCost)
        )
        AS DECIMAL(18,2)
    ) AS GrossProfit,

    CAST(
        SUM(
            oi.Quantity
            * (oi.UnitSellingPrice - oi.UnitCost)
        )
        * 100.0
        /
        NULLIF(
            SUM(oi.Quantity * oi.UnitSellingPrice),
            0
        )
        AS DECIMAL(8,2)
    ) AS GrossMarginPercentage,

    CAST(
        AVG(oi.DiscountPercentage)
        AS DECIMAL(8,2)
    ) AS AverageDiscountPercentage

FROM dbo.Orders AS o

INNER JOIN dbo.OrderItems AS oi
    ON o.OrderID = oi.OrderID

WHERE o.OrderStatus <> 'Cancelled'

GROUP BY o.SalesChannel

ORDER BY GrossRevenue DESC;
GO

/* =========================================================
   6. Product-category performance
   ========================================================= */

SELECT
    p.Category,

    COUNT(DISTINCT o.OrderID) AS OrdersContainingCategory,
    SUM(oi.Quantity) AS UnitsSold,

    CAST(
        SUM(oi.Quantity * oi.UnitSellingPrice)
        AS DECIMAL(18,2)
    ) AS GrossRevenue,

    CAST(
        SUM(
            oi.Quantity
            * (oi.UnitSellingPrice - oi.UnitCost)
        )
        AS DECIMAL(18,2)
    ) AS GrossProfit,

    CAST(
        SUM(
            oi.Quantity
            * (oi.UnitSellingPrice - oi.UnitCost)
        )
        * 100.0
        /
        NULLIF(
            SUM(oi.Quantity * oi.UnitSellingPrice),
            0
        )
        AS DECIMAL(8,2)
    ) AS GrossMarginPercentage

FROM dbo.OrderItems AS oi

INNER JOIN dbo.Orders AS o
    ON oi.OrderID = o.OrderID

INNER JOIN dbo.Products AS p
    ON oi.ProductID = p.ProductID

WHERE o.OrderStatus <> 'Cancelled'

GROUP BY p.Category

ORDER BY GrossRevenue DESC;
GO