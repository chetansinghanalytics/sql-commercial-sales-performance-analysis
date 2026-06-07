/*
Project: Commercial Sales Performance Analysis
File: 02_monthly_sales_trends.sql
Author: Chetan Singh

Purpose:
Analyse monthly revenue, gross profit, order volume, active customers,
average order value, month-on-month growth and year-on-year growth.
*/

USE CommercialSalesAnalysis;
GO

/* =========================================================
   1. Monthly sales performance
   ========================================================= */

;WITH MonthlySales AS
(
    SELECT
        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        ) AS SalesMonth,

        COUNT(DISTINCT o.OrderID) AS TotalOrders,
        COUNT(DISTINCT o.CustomerID) AS ActiveCustomers,
        SUM(oi.Quantity) AS UnitsSold,

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

    GROUP BY
        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        )
)
SELECT
    SalesMonth,
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
    ) AS AverageOrderValue

FROM MonthlySales
ORDER BY SalesMonth;
GO

/* =========================================================
   2. Month-on-month revenue growth
   ========================================================= */

;WITH MonthlySales AS
(
    SELECT
        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        ) AS SalesMonth,

        SUM(
            oi.Quantity * oi.UnitSellingPrice
        ) AS GrossRevenue

    FROM dbo.Orders AS o

    INNER JOIN dbo.OrderItems AS oi
        ON o.OrderID = oi.OrderID

    WHERE o.OrderStatus <> 'Cancelled'

    GROUP BY
        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        )
),
GrowthAnalysis AS
(
    SELECT
        SalesMonth,
        GrossRevenue,

        LAG(GrossRevenue) OVER
        (
            ORDER BY SalesMonth
        ) AS PreviousMonthRevenue

    FROM MonthlySales
)
SELECT
    SalesMonth,

    CAST(
        GrossRevenue
        AS DECIMAL(18,2)
    ) AS GrossRevenue,

    CAST(
        PreviousMonthRevenue
        AS DECIMAL(18,2)
    ) AS PreviousMonthRevenue,

    CAST(
        (
            GrossRevenue - PreviousMonthRevenue
        )
        * 100.0
        / NULLIF(PreviousMonthRevenue, 0)
        AS DECIMAL(8,2)
    ) AS MonthOnMonthGrowthPercentage

FROM GrowthAnalysis
ORDER BY SalesMonth;
GO

/* =========================================================
   3. Year-on-year monthly revenue growth
   ========================================================= */

;WITH MonthlySales AS
(
    SELECT
        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        ) AS SalesMonth,

        YEAR(o.OrderDate) AS SalesYear,
        MONTH(o.OrderDate) AS SalesMonthNumber,

        SUM(
            oi.Quantity * oi.UnitSellingPrice
        ) AS GrossRevenue

    FROM dbo.Orders AS o

    INNER JOIN dbo.OrderItems AS oi
        ON o.OrderID = oi.OrderID

    WHERE o.OrderStatus <> 'Cancelled'

    GROUP BY
        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        ),
        YEAR(o.OrderDate),
        MONTH(o.OrderDate)
),
YearlyComparison AS
(
    SELECT
        SalesMonth,
        SalesYear,
        SalesMonthNumber,
        GrossRevenue,

        LAG(GrossRevenue, 12) OVER
        (
            ORDER BY SalesMonth
        ) AS PreviousYearRevenue

    FROM MonthlySales
)
SELECT
    SalesMonth,
    SalesYear,
    SalesMonthNumber,

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

FROM YearlyComparison
ORDER BY SalesMonth;
GO

/* =========================================================
   4. Monthly cumulative revenue
   ========================================================= */

;WITH MonthlySales AS
(
    SELECT
        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        ) AS SalesMonth,

        SUM(
            oi.Quantity * oi.UnitSellingPrice
        ) AS GrossRevenue

    FROM dbo.Orders AS o

    INNER JOIN dbo.OrderItems AS oi
        ON o.OrderID = oi.OrderID

    WHERE o.OrderStatus <> 'Cancelled'

    GROUP BY
        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        )
)
SELECT
    SalesMonth,

    CAST(
        GrossRevenue
        AS DECIMAL(18,2)
    ) AS MonthlyRevenue,

    CAST(
        SUM(GrossRevenue) OVER
        (
            PARTITION BY YEAR(SalesMonth)
            ORDER BY SalesMonth
            ROWS BETWEEN UNBOUNDED PRECEDING
                     AND CURRENT ROW
        )
        AS DECIMAL(18,2)
    ) AS YearToDateRevenue

FROM MonthlySales
ORDER BY SalesMonth;
GO

/* =========================================================
   5. Seasonal monthly pattern
   ========================================================= */

SELECT
    MONTH(o.OrderDate) AS MonthNumber,
    DATENAME(MONTH, o.OrderDate) AS MonthName,

    COUNT(DISTINCT o.OrderID) AS TotalOrders,

    CAST(
        SUM(oi.Quantity * oi.UnitSellingPrice)
        AS DECIMAL(18,2)
    ) AS GrossRevenue,

    CAST(
        AVG(
            oi.Quantity * oi.UnitSellingPrice
        )
        AS DECIMAL(18,2)
    ) AS AverageLineRevenue

FROM dbo.Orders AS o

INNER JOIN dbo.OrderItems AS oi
    ON o.OrderID = oi.OrderID

WHERE o.OrderStatus <> 'Cancelled'

GROUP BY
    MONTH(o.OrderDate),
    DATENAME(MONTH, o.OrderDate)

ORDER BY MonthNumber;
GO