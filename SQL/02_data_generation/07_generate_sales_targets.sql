/*
Project: Commercial Sales Performance Analysis
File: 04_generate_sales_targets.sql
Author: Chetan Singh

Purpose:
Generate realistic monthly revenue, gross-profit and new-customer
targets for sales representatives.

Targets are calibrated against the synthetic monthly sales pattern so
that achievement rates remain commercially plausible. Most revenue
achievement rates fall between approximately 72% and 145%.

Important:
This script must run after customers, representatives, orders and
order items have been generated.
*/

USE CommercialSalesAnalysis;
GO

SET NOCOUNT ON;
GO

IF EXISTS (SELECT 1 FROM dbo.SalesTargets)
BEGIN
    PRINT 'SalesTargets already contains data. No records were inserted.';
    RETURN;
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Orders)
BEGIN
    THROW 50001,
          'Orders must be generated before sales targets.',
          1;
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.OrderItems)
BEGIN
    THROW 50002,
          'OrderItems must be generated before sales targets.',
          1;
END;
GO

/* =========================================================
   1. Calculate monthly actual performance
   ========================================================= */

;WITH MonthlyActuals AS
(
    SELECT
        o.SalesRepID,

        DATEFROMPARTS
        (
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        ) AS TargetMonth,

        SUM
        (
            oi.Quantity * oi.UnitSellingPrice
        ) AS ActualRevenue,

        SUM
        (
            oi.Quantity
            * (oi.UnitSellingPrice - oi.UnitCost)
        ) AS ActualGrossProfit,

        COUNT
        (
            DISTINCT
            CASE
                WHEN c.SignupDate >=
                     DATEFROMPARTS
                     (
                         YEAR(o.OrderDate),
                         MONTH(o.OrderDate),
                         1
                     )
                 AND c.SignupDate <
                     DATEADD
                     (
                         MONTH,
                         1,
                         DATEFROMPARTS
                         (
                             YEAR(o.OrderDate),
                             MONTH(o.OrderDate),
                             1
                         )
                     )
                    THEN c.CustomerID
            END
        ) AS ActualNewCustomers

    FROM dbo.Orders AS o

    INNER JOIN dbo.OrderItems AS oi
        ON o.OrderID = oi.OrderID

    INNER JOIN dbo.Customers AS c
        ON o.CustomerID = c.CustomerID

    WHERE o.OrderStatus <> 'Cancelled'

    GROUP BY
        o.SalesRepID,
        DATEFROMPARTS
        (
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        )
),
TargetDesign AS
(
    SELECT
        ma.SalesRepID,
        ma.TargetMonth,
        ma.ActualRevenue,
        ma.ActualGrossProfit,
        ma.ActualNewCustomers,
        sr.Team,

        /* Intended revenue achievement: 72% to 144% */
        CAST
        (
            72
            +
            (
                (
                    ma.SalesRepID * 13
                    + MONTH(ma.TargetMonth) * 7
                    + YEAR(ma.TargetMonth)
                ) % 73
            )
            AS DECIMAL(8,2)
        ) AS IntendedRevenueAchievementPercentage,

        /* Intended gross-profit achievement: 75% to 139% */
        CAST
        (
            75
            +
            (
                (
                    ma.SalesRepID * 17
                    + MONTH(ma.TargetMonth) * 11
                    + YEAR(ma.TargetMonth)
                ) % 65
            )
            AS DECIMAL(8,2)
        ) AS IntendedGrossProfitAchievementPercentage,

        /* Intended new-customer achievement: 80% to 125% */
        CAST
        (
            80
            +
            (
                (
                    ma.SalesRepID * 19
                    + MONTH(ma.TargetMonth) * 5
                    + YEAR(ma.TargetMonth)
                ) % 46
            )
            AS DECIMAL(8,2)
        ) AS IntendedNewCustomerAchievementPercentage

    FROM MonthlyActuals AS ma

    INNER JOIN dbo.SalesRepresentatives AS sr
        ON ma.SalesRepID = sr.SalesRepID

    WHERE ma.TargetMonth >=
          DATEFROMPARTS
          (
              YEAR(sr.HireDate),
              MONTH(sr.HireDate),
              1
          )
)
INSERT INTO dbo.SalesTargets
(
    SalesRepID,
    TargetMonth,
    RevenueTarget,
    GrossProfitTarget,
    NewCustomerTarget
)
SELECT
    SalesRepID,
    TargetMonth,

    CAST
    (
        ActualRevenue
        /
        (
            IntendedRevenueAchievementPercentage / 100.0
        )
        AS DECIMAL(12,2)
    ) AS RevenueTarget,

    CAST
    (
        ActualGrossProfit
        /
        (
            IntendedGrossProfitAchievementPercentage / 100.0
        )
        AS DECIMAL(12,2)
    ) AS GrossProfitTarget,

    CASE
        WHEN ActualNewCustomers = 0 THEN
            CASE Team
                WHEN 'Enterprise Accounts' THEN 2
                WHEN 'Mid-Market' THEN 5
                WHEN 'Small Business' THEN 10
                WHEN 'Channel Partnerships' THEN 3
            END

        ELSE
            CASE
                WHEN CAST
                     (
                         ActualNewCustomers
                         /
                         (
                             IntendedNewCustomerAchievementPercentage
                             / 100.0
                         )
                         AS INT
                     ) < 1
                    THEN 1

                ELSE CAST
                     (
                         ActualNewCustomers
                         /
                         (
                             IntendedNewCustomerAchievementPercentage
                             / 100.0
                         )
                         AS INT
                     )
            END
    END AS NewCustomerTarget

FROM TargetDesign;
GO

SET NOCOUNT OFF;
GO

/* =========================================================
   2. Validate generated target records
   ========================================================= */

SELECT
    COUNT(*) AS SalesTargetCount,
    MIN(TargetMonth) AS FirstTargetMonth,
    MAX(TargetMonth) AS LastTargetMonth
FROM dbo.SalesTargets;
GO

/* =========================================================
   3. Validate revenue achievement distribution
   ========================================================= */

;WITH MonthlyActuals AS
(
    SELECT
        o.SalesRepID,

        DATEFROMPARTS
        (
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        ) AS SalesMonth,

        SUM
        (
            oi.Quantity * oi.UnitSellingPrice
        ) AS ActualRevenue

    FROM dbo.Orders AS o

    INNER JOIN dbo.OrderItems AS oi
        ON o.OrderID = oi.OrderID

    WHERE o.OrderStatus <> 'Cancelled'

    GROUP BY
        o.SalesRepID,
        DATEFROMPARTS
        (
            YEAR(o.OrderDate),
            MONTH(o.OrderDate),
            1
        )
),
Achievement AS
(
    SELECT
        st.SalesRepID,
        st.TargetMonth,

        ISNULL(ma.ActualRevenue, 0) * 100.0
        / NULLIF(st.RevenueTarget, 0)
        AS AchievementPercentage

    FROM dbo.SalesTargets AS st

    LEFT JOIN MonthlyActuals AS ma
        ON st.SalesRepID = ma.SalesRepID
       AND st.TargetMonth = ma.SalesMonth
)
SELECT
    CAST
    (
        MIN(AchievementPercentage)
        AS DECIMAL(10,2)
    ) AS MinimumAchievement,

    CAST
    (
        AVG(AchievementPercentage)
        AS DECIMAL(10,2)
    ) AS AverageAchievement,

    CAST
    (
        MAX(AchievementPercentage)
        AS DECIMAL(10,2)
    ) AS MaximumAchievement,

    SUM
    (
        CASE
            WHEN AchievementPercentage < 70 THEN 1
            ELSE 0
        END
    ) AS MonthsBelow70Percent,

    SUM
    (
        CASE
            WHEN AchievementPercentage BETWEEN 70 AND 100
                THEN 1
            ELSE 0
        END
    ) AS MonthsBetween70And100Percent,

    SUM
    (
        CASE
            WHEN AchievementPercentage > 100
             AND AchievementPercentage <= 145
                THEN 1
            ELSE 0
        END
    ) AS MonthsBetween100And145Percent,

    SUM
    (
        CASE
            WHEN AchievementPercentage > 145 THEN 1
            ELSE 0
        END
    ) AS MonthsAbove145Percent

FROM Achievement;
GO