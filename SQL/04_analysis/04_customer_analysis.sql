/*
Project: Commercial Sales Performance Analysis
File: 04_customer_analysis.sql
Author: Chetan Singh

Purpose:
Analyse customer value, purchasing behaviour, concentration risk,
segment performance, acquisition channels and customer inactivity.
*/

USE CommercialSalesAnalysis;
GO

/* =========================================================
   1. Customer lifetime value overview
   ========================================================= */

;WITH CustomerValue AS
(
    SELECT
        c.CustomerID,
        c.CustomerName,
        c.CustomerSegment,
        c.Region,
        c.Industry,
        c.AcquisitionChannel,
        c.AccountStatus,

        COUNT(DISTINCT o.OrderID) AS TotalOrders,

        MIN(o.OrderDate) AS FirstOrderDate,
        MAX(o.OrderDate) AS LastOrderDate,

        SUM(
            oi.Quantity * oi.UnitSellingPrice
        ) AS GrossRevenue,

        SUM(
            oi.Quantity
            * (oi.UnitSellingPrice - oi.UnitCost)
        ) AS GrossProfit

    FROM dbo.Customers AS c

    INNER JOIN dbo.Orders AS o
        ON c.CustomerID = o.CustomerID

    INNER JOIN dbo.OrderItems AS oi
        ON o.OrderID = oi.OrderID

    WHERE o.OrderStatus <> 'Cancelled'

    GROUP BY
        c.CustomerID,
        c.CustomerName,
        c.CustomerSegment,
        c.Region,
        c.Industry,
        c.AcquisitionChannel,
        c.AccountStatus
)
SELECT TOP (100)
    CustomerID,
    CustomerName,
    CustomerSegment,
    Region,
    Industry,
    AcquisitionChannel,
    AccountStatus,
    TotalOrders,
    FirstOrderDate,
    LastOrderDate,

    CAST(
        GrossRevenue
        AS DECIMAL(18,2)
    ) AS GrossRevenue,

    CAST(
        GrossProfit
        AS DECIMAL(18,2)
    ) AS GrossProfit,

    CAST(
        GrossRevenue
        / NULLIF(TotalOrders, 0)
        AS DECIMAL(18,2)
    ) AS AverageOrderValue

FROM CustomerValue

ORDER BY GrossRevenue DESC;
GO

/* =========================================================
   2. Revenue concentration by customer
   ========================================================= */

;WITH CustomerRevenue AS
(
    SELECT
        o.CustomerID,

        SUM(
            oi.Quantity * oi.UnitSellingPrice
        ) AS GrossRevenue

    FROM dbo.Orders AS o

    INNER JOIN dbo.OrderItems AS oi
        ON o.OrderID = oi.OrderID

    WHERE o.OrderStatus <> 'Cancelled'

    GROUP BY o.CustomerID
),
RankedCustomers AS
(
    SELECT
        CustomerID,
        GrossRevenue,

        ROW_NUMBER() OVER
        (
            ORDER BY GrossRevenue DESC
        ) AS RevenueRank,

        COUNT(*) OVER () AS TotalCustomers,

        SUM(GrossRevenue) OVER () AS TotalBusinessRevenue

    FROM CustomerRevenue
)
SELECT
    CASE
        WHEN RevenueRank <= TotalCustomers * 0.01
            THEN 'Top 1%'
        WHEN RevenueRank <= TotalCustomers * 0.10
            THEN 'Top 10%'
        WHEN RevenueRank <= TotalCustomers * 0.25
            THEN 'Top 25%'
        ELSE 'Remaining 75%'
    END AS CustomerGroup,

    COUNT(*) AS CustomerCount,

    CAST(
        SUM(GrossRevenue)
        AS DECIMAL(18,2)
    ) AS GroupRevenue,

    CAST(
        SUM(GrossRevenue)
        * 100.0
        / MAX(TotalBusinessRevenue)
        AS DECIMAL(8,2)
    ) AS RevenueSharePercentage

FROM RankedCustomers

GROUP BY
    CASE
        WHEN RevenueRank <= TotalCustomers * 0.01
            THEN 'Top 1%'
        WHEN RevenueRank <= TotalCustomers * 0.10
            THEN 'Top 10%'
        WHEN RevenueRank <= TotalCustomers * 0.25
            THEN 'Top 25%'
        ELSE 'Remaining 75%'
    END

ORDER BY RevenueSharePercentage DESC;
GO

/* =========================================================
   3. Customer segment performance
   ========================================================= */

SELECT
    c.CustomerSegment,

    COUNT(DISTINCT c.CustomerID) AS ActiveCustomers,
    COUNT(DISTINCT o.OrderID) AS TotalOrders,

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
        / NULLIF(COUNT(DISTINCT c.CustomerID), 0)
        AS DECIMAL(18,2)
    ) AS RevenuePerCustomer,

    CAST(
        SUM(oi.Quantity * oi.UnitSellingPrice)
        / NULLIF(COUNT(DISTINCT o.OrderID), 0)
        AS DECIMAL(18,2)
    ) AS AverageOrderValue,

    CAST(
        AVG(oi.DiscountPercentage)
        AS DECIMAL(8,2)
    ) AS AverageDiscountPercentage

FROM dbo.Customers AS c

INNER JOIN dbo.Orders AS o
    ON c.CustomerID = o.CustomerID

INNER JOIN dbo.OrderItems AS oi
    ON o.OrderID = oi.OrderID

WHERE o.OrderStatus <> 'Cancelled'

GROUP BY c.CustomerSegment

ORDER BY GrossRevenue DESC;
GO

/* =========================================================
   4. Acquisition channel performance
   ========================================================= */

SELECT
    c.AcquisitionChannel,

    COUNT(DISTINCT c.CustomerID) AS CustomersAcquired,
    COUNT(DISTINCT o.OrderID) AS TotalOrders,

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
        / NULLIF(COUNT(DISTINCT c.CustomerID), 0)
        AS DECIMAL(18,2)
    ) AS RevenuePerCustomer

FROM dbo.Customers AS c

INNER JOIN dbo.Orders AS o
    ON c.CustomerID = o.CustomerID

INNER JOIN dbo.OrderItems AS oi
    ON o.OrderID = oi.OrderID

WHERE o.OrderStatus <> 'Cancelled'

GROUP BY c.AcquisitionChannel

ORDER BY RevenuePerCustomer DESC;
GO

/* =========================================================
   5. Industry performance
   ========================================================= */

SELECT
    c.Industry,

    COUNT(DISTINCT c.CustomerID) AS ActiveCustomers,
    COUNT(DISTINCT o.OrderID) AS TotalOrders,

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
        / NULLIF(COUNT(DISTINCT c.CustomerID), 0)
        AS DECIMAL(18,2)
    ) AS RevenuePerCustomer

FROM dbo.Customers AS c

INNER JOIN dbo.Orders AS o
    ON c.CustomerID = o.CustomerID

INNER JOIN dbo.OrderItems AS oi
    ON o.OrderID = oi.OrderID

WHERE o.OrderStatus <> 'Cancelled'

GROUP BY c.Industry

ORDER BY GrossRevenue DESC;
GO

/* =========================================================
   6. Customer inactivity analysis
   ========================================================= */

;WITH CustomerLastOrder AS
(
    SELECT
        c.CustomerID,
        c.CustomerName,
        c.CustomerSegment,
        c.Region,
        c.AccountStatus,

        MAX(o.OrderDate) AS LastOrderDate,

        DATEDIFF(
            DAY,
            MAX(o.OrderDate),
            CAST('2025-12-31' AS DATE)
        ) AS DaysSinceLastOrder

    FROM dbo.Customers AS c

    LEFT JOIN dbo.Orders AS o
        ON c.CustomerID = o.CustomerID
       AND o.OrderStatus <> 'Cancelled'

    GROUP BY
        c.CustomerID,
        c.CustomerName,
        c.CustomerSegment,
        c.Region,
        c.AccountStatus
)
SELECT
    CASE
        WHEN LastOrderDate IS NULL
            THEN 'Never Purchased'
        WHEN DaysSinceLastOrder <= 90
            THEN 'Active: 0-90 Days'
        WHEN DaysSinceLastOrder <= 180
            THEN 'At Risk: 91-180 Days'
        WHEN DaysSinceLastOrder <= 365
            THEN 'Inactive: 181-365 Days'
        ELSE 'Dormant: Over 365 Days'
    END AS ActivityStatus,

    COUNT(*) AS CustomerCount

FROM CustomerLastOrder

GROUP BY
    CASE
        WHEN LastOrderDate IS NULL
            THEN 'Never Purchased'
        WHEN DaysSinceLastOrder <= 90
            THEN 'Active: 0-90 Days'
        WHEN DaysSinceLastOrder <= 180
            THEN 'At Risk: 91-180 Days'
        WHEN DaysSinceLastOrder <= 365
            THEN 'Inactive: 181-365 Days'
        ELSE 'Dormant: Over 365 Days'
    END

ORDER BY CustomerCount DESC;
GO

/* =========================================================
   7. Top customers by region
   ========================================================= */

;WITH RegionalCustomerRevenue AS
(
    SELECT
        o.Region,
        c.CustomerID,
        c.CustomerName,

        SUM(
            oi.Quantity * oi.UnitSellingPrice
        ) AS GrossRevenue

    FROM dbo.Orders AS o

    INNER JOIN dbo.Customers AS c
        ON o.CustomerID = c.CustomerID

    INNER JOIN dbo.OrderItems AS oi
        ON o.OrderID = oi.OrderID

    WHERE o.OrderStatus <> 'Cancelled'

    GROUP BY
        o.Region,
        c.CustomerID,
        c.CustomerName
),
RankedRegionalCustomers AS
(
    SELECT
        Region,
        CustomerID,
        CustomerName,
        GrossRevenue,

        DENSE_RANK() OVER
        (
            PARTITION BY Region
            ORDER BY GrossRevenue DESC
        ) AS RegionalCustomerRank

    FROM RegionalCustomerRevenue
)
SELECT
    Region,
    RegionalCustomerRank,
    CustomerID,
    CustomerName,

    CAST(
        GrossRevenue
        AS DECIMAL(18,2)
    ) AS GrossRevenue

FROM RankedRegionalCustomers

WHERE RegionalCustomerRank <= 5

ORDER BY
    Region,
    RegionalCustomerRank;
GO