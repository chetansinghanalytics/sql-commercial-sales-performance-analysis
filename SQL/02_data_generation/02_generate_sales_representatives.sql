/*
Project: Commercial Sales Performance Analysis
File: 02_generate_sales_representatives.sql
Author: Chetan Singh

Purpose:
Generate 120 synthetic sales representatives across 12 UK regions,
with realistic teams, hire dates, managers, employment status and salary.
*/

USE CommercialSalesAnalysis;
GO

IF EXISTS (SELECT 1 FROM dbo.SalesRepresentatives)
BEGIN
    PRINT 'SalesRepresentatives already contains data. No records were inserted.';
    RETURN;
END;
GO

;WITH Numbers AS
(
    SELECT TOP (120)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects AS a
    CROSS JOIN sys.all_objects AS b
),
RepBase AS
(
    SELECT
        n,
        ((n - 1) / 10) + 1 AS RegionCode,
        ((n - 1) % 10) + 1 AS RepWithinRegion
    FROM Numbers
)
INSERT INTO dbo.SalesRepresentatives
(
    SalesRepName,
    Region,
    Team,
    HireDate,
    ManagerName,
    EmploymentStatus,
    AnnualSalary
)
SELECT
    CONCAT(
        CASE ((n - 1) % 20) + 1
            WHEN 1 THEN 'Oliver'
            WHEN 2 THEN 'Amelia'
            WHEN 3 THEN 'George'
            WHEN 4 THEN 'Isla'
            WHEN 5 THEN 'Harry'
            WHEN 6 THEN 'Ava'
            WHEN 7 THEN 'Jack'
            WHEN 8 THEN 'Mia'
            WHEN 9 THEN 'Charlie'
            WHEN 10 THEN 'Sophia'
            WHEN 11 THEN 'Thomas'
            WHEN 12 THEN 'Grace'
            WHEN 13 THEN 'James'
            WHEN 14 THEN 'Lily'
            WHEN 15 THEN 'William'
            WHEN 16 THEN 'Freya'
            WHEN 17 THEN 'Noah'
            WHEN 18 THEN 'Emily'
            WHEN 19 THEN 'Leo'
            WHEN 20 THEN 'Evie'
        END,
        ' ',
        CASE ((n * 7 - 1) % 20) + 1
            WHEN 1 THEN 'Smith'
            WHEN 2 THEN 'Jones'
            WHEN 3 THEN 'Taylor'
            WHEN 4 THEN 'Brown'
            WHEN 5 THEN 'Williams'
            WHEN 6 THEN 'Wilson'
            WHEN 7 THEN 'Johnson'
            WHEN 8 THEN 'Davies'
            WHEN 9 THEN 'Patel'
            WHEN 10 THEN 'Robinson'
            WHEN 11 THEN 'Wright'
            WHEN 12 THEN 'Thompson'
            WHEN 13 THEN 'Evans'
            WHEN 14 THEN 'Walker'
            WHEN 15 THEN 'White'
            WHEN 16 THEN 'Khan'
            WHEN 17 THEN 'Green'
            WHEN 18 THEN 'Hall'
            WHEN 19 THEN 'Clarke'
            WHEN 20 THEN 'Ali'
        END,
        ' ',
        RIGHT('000' + CAST(n AS VARCHAR(3)), 3)
    ) AS SalesRepName,

    CASE RegionCode
        WHEN 1 THEN 'London'
        WHEN 2 THEN 'South East'
        WHEN 3 THEN 'South West'
        WHEN 4 THEN 'East of England'
        WHEN 5 THEN 'West Midlands'
        WHEN 6 THEN 'East Midlands'
        WHEN 7 THEN 'North West'
        WHEN 8 THEN 'North East'
        WHEN 9 THEN 'Yorkshire and the Humber'
        WHEN 10 THEN 'Wales'
        WHEN 11 THEN 'Scotland'
        WHEN 12 THEN 'Northern Ireland'
    END AS Region,

    CASE
        WHEN RepWithinRegion IN (1, 2, 3)
            THEN 'Enterprise Accounts'
        WHEN RepWithinRegion IN (4, 5, 6)
            THEN 'Mid-Market'
        WHEN RepWithinRegion IN (7, 8)
            THEN 'Small Business'
        ELSE 'Channel Partnerships'
    END AS Team,

    DATEADD(
        DAY,
        -((n * 41) % 3650),
        CAST('2025-12-31' AS DATE)
    ) AS HireDate,

    CASE RegionCode
        WHEN 1 THEN 'Daniel Morgan'
        WHEN 2 THEN 'Sarah Bennett'
        WHEN 3 THEN 'Michael Reed'
        WHEN 4 THEN 'Emma Collins'
        WHEN 5 THEN 'David Hughes'
        WHEN 6 THEN 'Laura Foster'
        WHEN 7 THEN 'Andrew Scott'
        WHEN 8 THEN 'Rachel Ward'
        WHEN 9 THEN 'Christopher Wood'
        WHEN 10 THEN 'Hannah Price'
        WHEN 11 THEN 'Robert Murray'
        WHEN 12 THEN 'Claire Campbell'
    END AS ManagerName,

    CASE
        WHEN n % 40 = 0 THEN 'Resigned'
        WHEN n % 55 = 0 THEN 'On Leave'
        ELSE 'Active'
    END AS EmploymentStatus,

    CAST(
        CASE
            WHEN RepWithinRegion IN (1, 2, 3)
                THEN 42000 + ((n * 317) % 18000)
            WHEN RepWithinRegion IN (4, 5, 6)
                THEN 36000 + ((n * 271) % 14000)
            WHEN RepWithinRegion IN (7, 8)
                THEN 30000 + ((n * 233) % 11000)
            ELSE 38000 + ((n * 289) % 15000)
        END
        AS DECIMAL(10,2)
    ) AS AnnualSalary

FROM RepBase;
GO

SELECT
    COUNT(*) AS SalesRepCount
FROM dbo.SalesRepresentatives;
GO

SELECT
    Region,
    COUNT(*) AS RepresentativeCount,
    SUM(
        CASE
            WHEN EmploymentStatus = 'Active' THEN 1
            ELSE 0
        END
    ) AS ActiveRepresentatives,
    CAST(
        AVG(AnnualSalary)
        AS DECIMAL(10,2)
    ) AS AverageSalary
FROM dbo.SalesRepresentatives
GROUP BY Region
ORDER BY Region;
GO