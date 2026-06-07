/*
Project: Commercial Sales Performance Analysis
File: 03_regional_performance.sql
Author: Chetan Singh

Purpose:
Analyse regional sales performance, profitability, customer activity,
average order value, delivery efficiency and regional ranking.
*/

USE CommercialSalesAnalysis;
GO

/* =========================================================
   1. Regional commercial performance
   ========================================================= */

;WITH RegionalPerformance AS
(
    SELECT
        o.Region,

        COUNT(DISTINCT o.OrderID) AS TotalOrders,
        COUNT(DISTINCT o.CustomerID) AS ActiveCustomers,
        SUM(oi.Quantity) AS UnitsSold,

        SUM(
            oi.Quantity * oi.UnitSellingPrice
        ) AS GrossRevenue,

        SUM(
            oi.Quantity
            * (oi.UnitSellingPrice - oi.UnitCost)
        ) AS GrossProfit,

        AVG(
            CAST(o.DeliveryDays AS DECIMAL(10,2))
        ) AS AverageDeliveryDays

    FROM dbo.Orders AS o

    INNER JOIN dbo.OrderItems AS oi
        ON o.OrderID = oi.OrderID

    WHERE o.OrderStatus <> 'Cancelled'

    GROUP BY o.Region
)
SELECT
    Region,
    TotalOrders,
    ActiveCustomers,
    UnitsSold,

    CAST(
        GrossRevenue
        AS DECIMAL(18,2)
    ) AS GrossRevenue,

    CAST(
        GrossProfit
        AS DECIMAL(18,2)
    ) AS GrossProfit,

    CAST(
        GrossProfit * 100.0
        / NULLIF(GrossRevenue, 0)
        AS DECIMAL(8,2)
    ) AS GrossMarginPercentage,

    CAST(
        GrossRevenue
        / NULLIF(TotalOrders, 0)
        AS DECIMAL(18,2)
    ) AS AverageOrderValue,

    CAST(
        AverageDeliveryDays
        AS DECIMAL(10,2)
    ) AS AverageDeliveryDays

FROM RegionalPerformance

ORDER BY GrossRevenue DESC;
GO

/* =========================================================
   2. Regional ranking by revenue and profit
   ========================================================= */

;WITH RegionalPerformance AS
(
    SELECT
        o.Region,

        SUM(
            oi.Quantity * oi.UnitSellingPrice
        ) AS GrossRevenue,

        SUM(
            oi.Quantity
            * (oi.UnitSellingPrice - oi.UnitCost)
        ) AS GrossProfit

    FROM dbo.Orders AS o

    INNER JOIN dbo.OrderItems AS oi
        ON o.OrderID = oi.OrderID

    WHERE o.OrderStatus <> 'Cancelled'

    GROUP BY o.Region
)
SELECT
    Region,

    CAST(
        GrossRevenue
        AS DECIMAL(18,2)
    ) AS GrossRevenue,

    DENSE_RANK() OVER
    (
        ORDER BY GrossRevenue DESC
    ) AS RevenueRank,

    CAST(
        GrossProfit
        AS DECIMAL(18,2)
    ) AS GrossProfit,

    DENSE_RANK() OVER
    (
        ORDER BY GrossProfit DESC
    ) AS ProfitRank

FROM RegionalPerformance

ORDER BY RevenueRank;
GO

/* =========================================================
   3. Regional year-on-year revenue comparison
   ========================================================= */

;WITH RegionalYearlySales AS
(
    SELECT
        o.Region,
        YEAR(o.OrderDate) AS SalesYear,

        SUM(
            oi.Quantity * oi.UnitSellingPrice
        ) AS GrossRevenue

    FROM dbo.Orders AS o

    INNER JOIN dbo.OrderItems AS oi
        ON o.OrderID = oi.OrderID

    WHERE o.OrderStatus <> 'Cancelled'

    GROUP BY
        o.Region,
        YEAR(o.OrderDate)
),
RegionalGrowth AS
(
    SELECT
        Region,
        SalesYear,
        GrossRevenue,

        LAG(GrossRevenue) OVER
        (
            PARTITION BY Region
            ORDER BY SalesYear
        ) AS PreviousYearRevenue

    FROM RegionalYearlySales
)
SELECT
    Region,
    SalesYear,

    CAST(
        GrossRevenue
        AS DECIMAL(18,2)
    ) AS GrossRevenue,

    CAST(
        PreviousYearRevenue
        AS DECIMAL(18,2)
    ) AS PreviousYearRevenue,

    CAST(
        (
            GrossRevenue - PreviousYearRevenue
        )
        * 100.0
        / NULLIF(PreviousYearRevenue, 0)
        AS DECIMAL(8,2)
    ) AS YearOnYearGrowthPercentage

FROM RegionalGrowth

ORDER BY
    Region,
    SalesYear;
GO

/* =========================================================
   4. Regional channel mix
   ========================================================= */

SELECT
    o.Region,
    o.SalesChannel,

    COUNT(DISTINCT o.OrderID) AS TotalOrders,

    CAST(
        SUM(oi.Quantity * oi.UnitSellingPrice)
        AS DECIMAL(18,2)
    ) AS GrossRevenue,

    CAST(
        SUM(oi.Quantity * oi.UnitSellingPrice)
        * 100.0
        /
        SUM(
            SUM(oi.Quantity * oi.UnitSellingPrice)
        ) OVER
        (
            PARTITION BY o.Region
        )
        AS DECIMAL(8,2)
    ) AS RegionalRevenueSharePercentage

FROM dbo.Orders AS o

INNER JOIN dbo.OrderItems AS oi
    ON o.OrderID = oi.OrderID

WHERE o.OrderStatus <> 'Cancelled'

GROUP BY
    o.Region,
    o.SalesChannel

ORDER BY
    o.Region,
    GrossRevenue DESC;
GO

/* =========================================================
   5. Regional customer value
   ========================================================= */

;WITH CustomerRegionalValue AS
(
    SELECT
        o.Region,
        o.CustomerID,

        SUM(
            oi.Quantity * oi.UnitSellingPrice
        ) AS CustomerRevenue

    FROM dbo.Orders AS o

    INNER JOIN dbo.OrderItems AS oi
        ON o.OrderID = oi.OrderID

    WHERE o.OrderStatus <> 'Cancelled'

    GROUP BY
        o.Region,
        o.CustomerID
)
SELECT
    Region,

    COUNT(*) AS ActiveCustomers,

    CAST(
        AVG(CustomerRevenue)
        AS DECIMAL(18,2)
    ) AS AverageRevenuePerCustomer,

    CAST(
        MAX(CustomerRevenue)
        AS DECIMAL(18,2)
    ) AS HighestCustomerRevenue,

    CAST(
        MIN(CustomerRevenue)
        AS DECIMAL(18,2)
    ) AS LowestCustomerRevenue

FROM CustomerRegionalValue

GROUP BY Region

ORDER BY AverageRevenuePerCustomer DESC;
GO