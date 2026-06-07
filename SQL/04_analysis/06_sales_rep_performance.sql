/*
Project: Commercial Sales Performance Analysis
File: 06_sales_rep_performance.sql
Author: Chetan Singh

Purpose:
Evaluate sales representative performance against monthly targets,
including revenue, gross profit, target achievement, ranking and
consistency across time.
*/

USE CommercialSalesAnalysis;
GO

/* =========================================================
   1. Overall sales representative performance
   ========================================================= */

;WITH SalesRepPerformance AS
(
    SELECT
        sr.SalesRepID,
        sr.SalesRepName,
        sr.Region,
        sr.Team,
        sr.ManagerName,
        sr.EmploymentStatus,

        COUNT(DISTINCT o.OrderID) AS TotalOrders,
        COUNT(DISTINCT o.CustomerID) AS ActiveCustomers,

        SUM(
            oi.Quantity * oi.UnitSellingPrice
        ) AS GrossRevenue,

        SUM(
            oi.Quantity
            * (oi.UnitSellingPrice - oi.UnitCost)
        ) AS GrossProfit

    FROM dbo.SalesRepresentatives AS sr

    LEFT JOIN dbo.Orders AS o
        ON sr.SalesRepID = o.SalesRepID
       AND o.OrderStatus <> 'Cancelled'

    LEFT JOIN dbo.OrderItems AS oi
        ON o.OrderID = oi.OrderID

    GROUP BY
        sr.SalesRepID,
        sr.SalesRepName,
        sr.Region,
        sr.Team,
        sr.ManagerName,
        sr.EmploymentStatus
)
SELECT
    SalesRepID,
    SalesRepName,
    Region,
    Team,
    ManagerName,
    EmploymentStatus,
    TotalOrders,
    ActiveCustomers,

    CAST(
        ISNULL(GrossRevenue, 0)
        AS DECIMAL(18,2)
    ) AS GrossRevenue,

    CAST(
        ISNULL(GrossProfit, 0)
        AS DECIMAL(18,2)
    ) AS GrossProfit,

    CAST(
        ISNULL(GrossRevenue, 0)
        / NULLIF(TotalOrders, 0)
        AS DECIMAL(18,2)
    ) AS AverageOrderValue,

    CAST(
        ISNULL(GrossProfit, 0) * 100.0
        / NULLIF(GrossRevenue, 0)
        AS DECIMAL(8,2)
    ) AS GrossMarginPercentage

FROM SalesRepPerformance

ORDER BY GrossRevenue DESC;
GO

/* =========================================================
   2. Monthly target achievement
   ========================================================= */

;WITH MonthlyActuals AS
(
    SELECT
        o.SalesRepID,

        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        ) AS SalesMonth,

        SUM(
            oi.Quantity * oi.UnitSellingPrice
        ) AS ActualRevenue,

        SUM(
            oi.Quantity
            * (oi.UnitSellingPrice - oi.UnitCost)
        ) AS ActualGrossProfit

    FROM dbo.Orders AS o

    INNER JOIN dbo.OrderItems AS oi
        ON o.OrderID = oi.OrderID

    WHERE o.OrderStatus <> 'Cancelled'

    GROUP BY
        o.SalesRepID,
        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        )
)
SELECT
    st.SalesRepID,
    sr.SalesRepName,
    sr.Region,
    sr.Team,
    st.TargetMonth,

    CAST(
        st.RevenueTarget
        AS DECIMAL(18,2)
    ) AS RevenueTarget,

    CAST(
        ISNULL(ma.ActualRevenue, 0)
        AS DECIMAL(18,2)
    ) AS ActualRevenue,

    CAST(
        ISNULL(ma.ActualRevenue, 0)
        - st.RevenueTarget
        AS DECIMAL(18,2)
    ) AS RevenueVariance,

    CAST(
        ISNULL(ma.ActualRevenue, 0) * 100.0
        / NULLIF(st.RevenueTarget, 0)
        AS DECIMAL(8,2)
    ) AS RevenueTargetAchievementPercentage,

    CAST(
        st.GrossProfitTarget
        AS DECIMAL(18,2)
    ) AS GrossProfitTarget,

    CAST(
        ISNULL(ma.ActualGrossProfit, 0)
        AS DECIMAL(18,2)
    ) AS ActualGrossProfit,

    CAST(
        ISNULL(ma.ActualGrossProfit, 0) * 100.0
        / NULLIF(st.GrossProfitTarget, 0)
        AS DECIMAL(8,2)
    ) AS GrossProfitTargetAchievementPercentage

FROM dbo.SalesTargets AS st

INNER JOIN dbo.SalesRepresentatives AS sr
    ON st.SalesRepID = sr.SalesRepID

LEFT JOIN MonthlyActuals AS ma
    ON st.SalesRepID = ma.SalesRepID
   AND st.TargetMonth = ma.SalesMonth

ORDER BY
    st.TargetMonth,
    sr.Region,
    sr.SalesRepName;
GO

/* =========================================================
   3. Overall target achievement by sales representative
   ========================================================= */

;WITH MonthlyActuals AS
(
    SELECT
        o.SalesRepID,

        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        ) AS SalesMonth,

        SUM(
            oi.Quantity * oi.UnitSellingPrice
        ) AS ActualRevenue,

        SUM(
            oi.Quantity
            * (oi.UnitSellingPrice - oi.UnitCost)
        ) AS ActualGrossProfit

    FROM dbo.Orders AS o

    INNER JOIN dbo.OrderItems AS oi
        ON o.OrderID = oi.OrderID

    WHERE o.OrderStatus <> 'Cancelled'

    GROUP BY
        o.SalesRepID,
        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        )
),
RepTargetSummary AS
(
    SELECT
        st.SalesRepID,

        SUM(st.RevenueTarget) AS TotalRevenueTarget,
        SUM(
            ISNULL(ma.ActualRevenue, 0)
        ) AS TotalActualRevenue,

        SUM(st.GrossProfitTarget) AS TotalGrossProfitTarget,
        SUM(
            ISNULL(ma.ActualGrossProfit, 0)
        ) AS TotalActualGrossProfit,

        COUNT(*) AS TargetMonths,

        SUM(
            CASE
                WHEN ISNULL(ma.ActualRevenue, 0) >= st.RevenueTarget
                    THEN 1
                ELSE 0
            END
        ) AS MonthsRevenueTargetMet

    FROM dbo.SalesTargets AS st

    LEFT JOIN MonthlyActuals AS ma
        ON st.SalesRepID = ma.SalesRepID
       AND st.TargetMonth = ma.SalesMonth

    GROUP BY st.SalesRepID
)
SELECT
    rts.SalesRepID,
    sr.SalesRepName,
    sr.Region,
    sr.Team,

    rts.TargetMonths,
    rts.MonthsRevenueTargetMet,

    CAST(
        rts.MonthsRevenueTargetMet * 100.0
        / NULLIF(rts.TargetMonths, 0)
        AS DECIMAL(8,2)
    ) AS PercentageOfMonthsTargetMet,

    CAST(
        rts.TotalRevenueTarget
        AS DECIMAL(18,2)
    ) AS TotalRevenueTarget,

    CAST(
        rts.TotalActualRevenue
        AS DECIMAL(18,2)
    ) AS TotalActualRevenue,

    CAST(
        rts.TotalActualRevenue * 100.0
        / NULLIF(rts.TotalRevenueTarget, 0)
        AS DECIMAL(8,2)
    ) AS OverallRevenueTargetAchievementPercentage,

    CAST(
        rts.TotalActualGrossProfit * 100.0
        / NULLIF(rts.TotalGrossProfitTarget, 0)
        AS DECIMAL(8,2)
    ) AS OverallGrossProfitTargetAchievementPercentage

FROM RepTargetSummary AS rts

INNER JOIN dbo.SalesRepresentatives AS sr
    ON rts.SalesRepID = sr.SalesRepID

ORDER BY OverallRevenueTargetAchievementPercentage DESC;
GO

/* =========================================================
   4. Sales representative ranking within region
   ========================================================= */

;WITH RepRevenue AS
(
    SELECT
        sr.SalesRepID,
        sr.SalesRepName,
        sr.Region,
        sr.Team,

        SUM(
            oi.Quantity * oi.UnitSellingPrice
        ) AS GrossRevenue

    FROM dbo.SalesRepresentatives AS sr

    INNER JOIN dbo.Orders AS o
        ON sr.SalesRepID = o.SalesRepID

    INNER JOIN dbo.OrderItems AS oi
        ON o.OrderID = oi.OrderID

    WHERE o.OrderStatus <> 'Cancelled'

    GROUP BY
        sr.SalesRepID,
        sr.SalesRepName,
        sr.Region,
        sr.Team
)
SELECT
    Region,
    SalesRepID,
    SalesRepName,
    Team,

    CAST(
        GrossRevenue
        AS DECIMAL(18,2)
    ) AS GrossRevenue,

    DENSE_RANK() OVER
    (
        PARTITION BY Region
        ORDER BY GrossRevenue DESC
    ) AS RevenueRankWithinRegion

FROM RepRevenue

ORDER BY
    Region,
    RevenueRankWithinRegion;
GO

/* =========================================================
   5. Team performance
   ========================================================= */

SELECT
    sr.Team,

    COUNT(DISTINCT sr.SalesRepID) AS SalesRepresentativeCount,
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
        SUM(oi.Quantity * oi.UnitSellingPrice)
        / NULLIF(COUNT(DISTINCT sr.SalesRepID), 0)
        AS DECIMAL(18,2)
    ) AS RevenuePerSalesRepresentative

FROM dbo.SalesRepresentatives AS sr

INNER JOIN dbo.Orders AS o
    ON sr.SalesRepID = o.SalesRepID

INNER JOIN dbo.OrderItems AS oi
    ON o.OrderID = oi.OrderID

WHERE o.OrderStatus <> 'Cancelled'

GROUP BY sr.Team

ORDER BY GrossRevenue DESC;
GO

/* =========================================================
   6. Performance consistency by sales representative
   ========================================================= */

;WITH MonthlyRevenue AS
(
    SELECT
        o.SalesRepID,

        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        ) AS SalesMonth,

        SUM(
            oi.Quantity * oi.UnitSellingPrice
        ) AS MonthlyRevenue

    FROM dbo.Orders AS o

    INNER JOIN dbo.OrderItems AS oi
        ON o.OrderID = oi.OrderID

    WHERE o.OrderStatus <> 'Cancelled'

    GROUP BY
        o.SalesRepID,
        DATEFROMPARTS(
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        )
)
SELECT
    mr.SalesRepID,
    sr.SalesRepName,
    sr.Region,
    sr.Team,

    COUNT(*) AS ActiveSalesMonths,

    CAST(
        AVG(mr.MonthlyRevenue)
        AS DECIMAL(18,2)
    ) AS AverageMonthlyRevenue,

    CAST(
        STDEV(mr.MonthlyRevenue)
        AS DECIMAL(18,2)
    ) AS MonthlyRevenueStandardDeviation,

    CAST(
        STDEV(mr.MonthlyRevenue) * 100.0
        / NULLIF(AVG(mr.MonthlyRevenue), 0)
        AS DECIMAL(8,2)
    ) AS RevenueCoefficientOfVariation

FROM MonthlyRevenue AS mr

INNER JOIN dbo.SalesRepresentatives AS sr
    ON mr.SalesRepID = sr.SalesRepID

GROUP BY
    mr.SalesRepID,
    sr.SalesRepName,
    sr.Region,
    sr.Team

ORDER BY RevenueCoefficientOfVariation ASC;
GO