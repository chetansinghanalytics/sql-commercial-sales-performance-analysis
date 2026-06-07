/*
Project: Commercial Sales Performance Analysis
File: 04_generate_sales_targets.sql
Author: Chetan Singh

Purpose:
Generate monthly revenue, gross-profit and new-customer targets for
sales representatives from January 2023 to December 2025.
*/

USE CommercialSalesAnalysis;
GO

IF EXISTS (SELECT 1 FROM dbo.SalesTargets)
BEGIN
    PRINT 'SalesTargets already contains data. No records were inserted.';
    RETURN;
END;
GO

;WITH Months AS
(
    SELECT
        0 AS MonthNumber,
        CAST('2023-01-01' AS DATE) AS TargetMonth

    UNION ALL

    SELECT
        MonthNumber + 1,
        DATEADD(MONTH, 1, TargetMonth)
    FROM Months
    WHERE MonthNumber < 35
),
RepMonths AS
(
    SELECT
        sr.SalesRepID,
        sr.Region,
        sr.Team,
        sr.HireDate,
        sr.EmploymentStatus,
        m.TargetMonth,
        MONTH(m.TargetMonth) AS MonthOfYear,
        YEAR(m.TargetMonth) AS TargetYear
    FROM dbo.SalesRepresentatives AS sr
    CROSS JOIN Months AS m
    WHERE m.TargetMonth >= DATEFROMPARTS(
        YEAR(sr.HireDate),
        MONTH(sr.HireDate),
        1
    )
),
TargetBase AS
(
    SELECT
        SalesRepID,
        Region,
        Team,
        TargetMonth,
        MonthOfYear,
        TargetYear,

        CASE Team
            WHEN 'Enterprise Accounts' THEN 115000
            WHEN 'Mid-Market' THEN 80000
            WHEN 'Small Business' THEN 50000
            WHEN 'Channel Partnerships' THEN 90000
        END AS BaseRevenueTarget,

        CASE Region
            WHEN 'London' THEN 1.20
            WHEN 'South East' THEN 1.12
            WHEN 'North West' THEN 1.07
            WHEN 'West Midlands' THEN 1.05
            WHEN 'Yorkshire and the Humber' THEN 1.03
            WHEN 'Scotland' THEN 1.02
            WHEN 'East of England' THEN 1.00
            WHEN 'East Midlands' THEN 0.98
            WHEN 'South West' THEN 0.97
            WHEN 'Wales' THEN 0.94
            WHEN 'North East' THEN 0.92
            WHEN 'Northern Ireland' THEN 0.90
        END AS RegionMultiplier,

        CASE
            WHEN MonthOfYear IN (11, 12) THEN 1.18
            WHEN MonthOfYear IN (9, 10) THEN 1.10
            WHEN MonthOfYear IN (1, 2) THEN 0.88
            WHEN MonthOfYear IN (7, 8) THEN 0.94
            ELSE 1.00
        END AS SeasonalMultiplier,

        CASE TargetYear
            WHEN 2023 THEN 1.00
            WHEN 2024 THEN 1.06
            WHEN 2025 THEN 1.12
        END AS YearMultiplier
    FROM RepMonths
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

    CAST(
        BaseRevenueTarget
        * RegionMultiplier
        * SeasonalMultiplier
        * YearMultiplier
        * (
            0.94
            + ((SalesRepID * 17 + MonthOfYear * 7) % 13) / 100.0
        )
        AS DECIMAL(12,2)
    ) AS RevenueTarget,

    CAST(
        BaseRevenueTarget
        * RegionMultiplier
        * SeasonalMultiplier
        * YearMultiplier
        * (
            0.94
            + ((SalesRepID * 17 + MonthOfYear * 7) % 13) / 100.0
        )
        *
        CASE Team
            WHEN 'Enterprise Accounts' THEN 0.29
            WHEN 'Mid-Market' THEN 0.31
            WHEN 'Small Business' THEN 0.34
            WHEN 'Channel Partnerships' THEN 0.27
        END
        AS DECIMAL(12,2)
    ) AS GrossProfitTarget,

    CASE Team
        WHEN 'Enterprise Accounts'
            THEN 2 + ((SalesRepID + MonthOfYear) % 4)
        WHEN 'Mid-Market'
            THEN 5 + ((SalesRepID + MonthOfYear) % 6)
        WHEN 'Small Business'
            THEN 10 + ((SalesRepID + MonthOfYear) % 9)
        WHEN 'Channel Partnerships'
            THEN 3 + ((SalesRepID + MonthOfYear) % 5)
    END AS NewCustomerTarget

FROM TargetBase
OPTION (MAXRECURSION 100);
GO

SELECT
    COUNT(*) AS SalesTargetCount,
    MIN(TargetMonth) AS FirstTargetMonth,
    MAX(TargetMonth) AS LastTargetMonth
FROM dbo.SalesTargets;
GO

SELECT
    YEAR(TargetMonth) AS TargetYear,
    COUNT(*) AS TargetRecords,
    CAST(AVG(RevenueTarget) AS DECIMAL(12,2)) AS AverageRevenueTarget,
    CAST(AVG(GrossProfitTarget) AS DECIMAL(12,2)) AS AverageGrossProfitTarget,
    CAST(AVG(NewCustomerTarget * 1.0) AS DECIMAL(10,2)) AS AverageNewCustomerTarget
FROM dbo.SalesTargets
GROUP BY YEAR(TargetMonth)
ORDER BY TargetYear;
GO