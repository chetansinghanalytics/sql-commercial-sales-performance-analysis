/*
Project: Commercial Sales Performance Analysis
File: 09_generate_campaign_responses.sql
Author: Chetan Singh

Purpose:
Generate 100,000 synthetic customer campaign responses with realistic
variation in engagement, conversion and revenue by campaign type and
customer segment.
*/

USE CommercialSalesAnalysis;
GO

SET NOCOUNT ON;
GO

IF EXISTS (SELECT 1 FROM dbo.CustomerCampaignResponses)
BEGIN
    PRINT 'CustomerCampaignResponses already contains data. No records were inserted.';
    RETURN;
END;
GO

;WITH Numbers AS
(
    SELECT TOP (100000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects AS a
    CROSS JOIN sys.all_objects AS b
),
ResponseBase AS
(
    SELECT
        n,
        ((n * 17 - 1) % 30) + 1 AS CampaignID,
        ((n * 7919 - 1) % 20000) + 1 AS CustomerID
    FROM Numbers
),
CampaignCustomerBase AS
(
    SELECT
        rb.n,
        rb.CampaignID,
        rb.CustomerID,
        mc.CampaignType,
        mc.StartDate,
        mc.EndDate,
        mc.TargetSegment,
        c.CustomerSegment,

        CASE
            WHEN mc.TargetSegment = 'All Customers' THEN 1
            WHEN mc.TargetSegment = c.CustomerSegment THEN 1
            ELSE 0
        END AS SegmentMatchFlag

    FROM ResponseBase AS rb

    INNER JOIN dbo.MarketingCampaigns AS mc
        ON rb.CampaignID = mc.CampaignID

    INNER JOIN dbo.Customers AS c
        ON rb.CustomerID = c.CustomerID
),
ResponseLogic AS
(
    SELECT
        n,
        CampaignID,
        CustomerID,
        CampaignType,
        StartDate,
        EndDate,
        TargetSegment,
        CustomerSegment,
        SegmentMatchFlag,

        CASE
            WHEN SegmentMatchFlag = 0 THEN
                CASE
                    WHEN n % 100 = 0 THEN 'Opened'
                    WHEN n % 100 = 1 THEN 'Clicked'
                    ELSE 'No Response'
                END

            WHEN CampaignType = 'Email' THEN
                CASE
                    WHEN n % 100 < 38 THEN 'Opened'
                    WHEN n % 100 < 55 THEN 'Clicked'
                    WHEN n % 100 < 64 THEN 'Enquired'
                    WHEN n % 100 < 69 THEN 'Registered'
                    WHEN n % 100 < 74 THEN 'Purchased'
                    ELSE 'No Response'
                END

            WHEN CampaignType = 'Paid Search' THEN
                CASE
                    WHEN n % 100 < 18 THEN 'Clicked'
                    WHEN n % 100 < 33 THEN 'Enquired'
                    WHEN n % 100 < 43 THEN 'Registered'
                    WHEN n % 100 < 54 THEN 'Purchased'
                    ELSE 'No Response'
                END

            WHEN CampaignType = 'Social Media' THEN
                CASE
                    WHEN n % 100 < 32 THEN 'Opened'
                    WHEN n % 100 < 48 THEN 'Clicked'
                    WHEN n % 100 < 56 THEN 'Enquired'
                    WHEN n % 100 < 62 THEN 'Registered'
                    WHEN n % 100 < 68 THEN 'Purchased'
                    ELSE 'No Response'
                END

            WHEN CampaignType = 'Trade Show' THEN
                CASE
                    WHEN n % 100 < 22 THEN 'Enquired'
                    WHEN n % 100 < 41 THEN 'Registered'
                    WHEN n % 100 < 59 THEN 'Purchased'
                    ELSE 'No Response'
                END

            WHEN CampaignType = 'Partner Promotion' THEN
                CASE
                    WHEN n % 100 < 24 THEN 'Clicked'
                    WHEN n % 100 < 39 THEN 'Enquired'
                    WHEN n % 100 < 51 THEN 'Registered'
                    WHEN n % 100 < 66 THEN 'Purchased'
                    ELSE 'No Response'
                END

            WHEN CampaignType = 'Direct Mail' THEN
                CASE
                    WHEN n % 100 < 17 THEN 'Opened'
                    WHEN n % 100 < 27 THEN 'Enquired'
                    WHEN n % 100 < 34 THEN 'Registered'
                    WHEN n % 100 < 42 THEN 'Purchased'
                    ELSE 'No Response'
                END
        END AS ResponseType

    FROM CampaignCustomerBase
),
FinalResponses AS
(
    SELECT
        n,
        CampaignID,
        CustomerID,
        CampaignType,
        CustomerSegment,
        ResponseType,

        DATEADD(
            DAY,
            CAST(
                (n * 13)
                %
                (
                    DATEDIFF(DAY, StartDate, EndDate) + 1
                )
                AS INT
            ),
            StartDate
        ) AS ResponseDate,

        CASE
            WHEN ResponseType = 'Purchased' THEN 1
            ELSE 0
        END AS ConvertedFlag

    FROM ResponseLogic
)
INSERT INTO dbo.CustomerCampaignResponses
(
    CampaignID,
    CustomerID,
    ResponseDate,
    ResponseType,
    ConvertedFlag,
    RevenueGenerated
)
SELECT
    CampaignID,
    CustomerID,
    ResponseDate,
    ResponseType,
    ConvertedFlag,

    CASE
        WHEN ConvertedFlag = 0 THEN NULL

        WHEN CustomerSegment = 'Enterprise' THEN
            CAST(
                2500 + ((n * 911) % 22500)
                AS DECIMAL(12,2)
            )

        WHEN CustomerSegment = 'Mid-Market' THEN
            CAST(
                700 + ((n * 577) % 7300)
                AS DECIMAL(12,2)
            )

        WHEN CustomerSegment = 'Small Business' THEN
            CAST(
                100 + ((n * 293) % 1900)
                AS DECIMAL(12,2)
            )
    END AS RevenueGenerated

FROM FinalResponses;
GO

SET NOCOUNT OFF;
GO

SELECT
    COUNT(*) AS CampaignResponseCount,
    MIN(ResponseDate) AS FirstResponseDate,
    MAX(ResponseDate) AS LastResponseDate
FROM dbo.CustomerCampaignResponses;
GO

SELECT
    ResponseType,
    COUNT(*) AS ResponseCount,

    CAST(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER ()
        AS DECIMAL(5,2)
    ) AS ResponsePercentage

FROM dbo.CustomerCampaignResponses
GROUP BY ResponseType
ORDER BY ResponseCount DESC;
GO

SELECT
    mc.CampaignType,
    COUNT(*) AS Responses,

    SUM(
        CASE
            WHEN ccr.ConvertedFlag = 1 THEN 1
            ELSE 0
        END
    ) AS Conversions,

    CAST(
        SUM(
            CASE
                WHEN ccr.ConvertedFlag = 1 THEN 1
                ELSE 0
            END
        ) * 100.0
        / COUNT(*)
        AS DECIMAL(6,2)
    ) AS ConversionRate,

    CAST(
        SUM(
            ISNULL(ccr.RevenueGenerated, 0)
        )
        AS DECIMAL(18,2)
    ) AS RevenueGenerated

FROM dbo.CustomerCampaignResponses AS ccr

INNER JOIN dbo.MarketingCampaigns AS mc
    ON ccr.CampaignID = mc.CampaignID

GROUP BY mc.CampaignType
ORDER BY ConversionRate DESC;
GO

SELECT
    COUNT(*) AS InvalidResponseDateCount

FROM dbo.CustomerCampaignResponses AS ccr

INNER JOIN dbo.MarketingCampaigns AS mc
    ON ccr.CampaignID = mc.CampaignID

WHERE ccr.ResponseDate < mc.StartDate
   OR ccr.ResponseDate > mc.EndDate;
GO

SELECT
    COUNT(*) AS InvalidConversionRevenueCount

FROM dbo.CustomerCampaignResponses

WHERE
    (
        ConvertedFlag = 0
        AND RevenueGenerated IS NOT NULL
    )
    OR
    (
        ConvertedFlag = 1
        AND RevenueGenerated IS NULL
    );
GO