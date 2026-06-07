/*
Project: Commercial Sales Performance Analysis
File: 05_generate_marketing_campaigns.sql
Author: Chetan Singh

Purpose:
Generate 30 synthetic marketing campaigns across six campaign types,
with realistic dates, budgets, target segments and campaign statuses.
*/

USE CommercialSalesAnalysis;
GO

IF EXISTS (SELECT 1 FROM dbo.MarketingCampaigns)
BEGIN
    PRINT 'MarketingCampaigns already contains data. No records were inserted.';
    RETURN;
END;
GO

;WITH Numbers AS
(
    SELECT TOP (30)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects
),
CampaignBase AS
(
    SELECT
        n,
        ((n - 1) % 6) + 1 AS CampaignTypeCode,
        ((n - 1) % 4) + 1 AS SegmentCode,
        DATEADD(
            DAY,
            ((n - 1) * 36) % 1050,
            CAST('2023-01-10' AS DATE)
        ) AS GeneratedStartDate
    FROM Numbers
)
INSERT INTO dbo.MarketingCampaigns
(
    CampaignName,
    CampaignType,
    StartDate,
    EndDate,
    Budget,
    TargetSegment,
    CampaignStatus
)
SELECT
    CONCAT(
        CASE CampaignTypeCode
            WHEN 1 THEN 'Email Growth Campaign'
            WHEN 2 THEN 'Paid Search Acquisition'
            WHEN 3 THEN 'Social Engagement Campaign'
            WHEN 4 THEN 'Industry Trade Show'
            WHEN 5 THEN 'Partner Growth Promotion'
            WHEN 6 THEN 'Direct Mail Retention'
        END,
        ' ',
        RIGHT('00' + CAST(n AS VARCHAR(2)), 2)
    ) AS CampaignName,

    CASE CampaignTypeCode
        WHEN 1 THEN 'Email'
        WHEN 2 THEN 'Paid Search'
        WHEN 3 THEN 'Social Media'
        WHEN 4 THEN 'Trade Show'
        WHEN 5 THEN 'Partner Promotion'
        WHEN 6 THEN 'Direct Mail'
    END AS CampaignType,

    GeneratedStartDate,

    DATEADD(
        DAY,
        CASE CampaignTypeCode
            WHEN 1 THEN 28
            WHEN 2 THEN 45
            WHEN 3 THEN 35
            WHEN 4 THEN 7
            WHEN 5 THEN 60
            WHEN 6 THEN 30
        END,
        GeneratedStartDate
    ) AS EndDate,

    CAST(
        CASE CampaignTypeCode
            WHEN 1 THEN 8000 + ((n * 491) % 7000)
            WHEN 2 THEN 18000 + ((n * 733) % 17000)
            WHEN 3 THEN 12000 + ((n * 613) % 13000)
            WHEN 4 THEN 30000 + ((n * 977) % 25000)
            WHEN 5 THEN 22000 + ((n * 829) % 18000)
            WHEN 6 THEN 10000 + ((n * 547) % 9000)
        END
        AS DECIMAL(12,2)
    ) AS Budget,

    CASE SegmentCode
        WHEN 1 THEN 'Small Business'
        WHEN 2 THEN 'Mid-Market'
        WHEN 3 THEN 'Enterprise'
        WHEN 4 THEN 'All Customers'
    END AS TargetSegment,

    CASE
        WHEN GeneratedStartDate > '2025-12-31'
            THEN 'Planned'

        WHEN DATEADD(
            DAY,
            CASE CampaignTypeCode
                WHEN 1 THEN 28
                WHEN 2 THEN 45
                WHEN 3 THEN 35
                WHEN 4 THEN 7
                WHEN 5 THEN 60
                WHEN 6 THEN 30
            END,
            GeneratedStartDate
        ) <= '2025-12-31'
            THEN 'Completed'

        ELSE 'Active'
    END AS CampaignStatus

FROM CampaignBase;
GO

SELECT
    COUNT(*) AS CampaignCount
FROM dbo.MarketingCampaigns;
GO

SELECT
    CampaignID,
    CampaignName,
    CampaignType,
    StartDate,
    EndDate,
    Budget,
    TargetSegment,
    CampaignStatus
FROM dbo.MarketingCampaigns
ORDER BY StartDate;
GO

SELECT
    CampaignType,
    COUNT(*) AS CampaignCount,
    CAST(
        AVG(Budget)
        AS DECIMAL(12,2)
    ) AS AverageBudget,
    CAST(
        SUM(Budget)
        AS DECIMAL(18,2)
    ) AS TotalBudget
FROM dbo.MarketingCampaigns
GROUP BY CampaignType
ORDER BY CampaignType;
GO