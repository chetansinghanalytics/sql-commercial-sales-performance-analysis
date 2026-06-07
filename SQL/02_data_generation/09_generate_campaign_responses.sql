/*
Project: Commercial Sales Performance Analysis
File: 09_generate_campaign_responses.sql
Author: Chetan Singh

Purpose:
Generate 100,000 synthetic customer campaign responses efficiently
using indexed temporary tables and 10,000-row processing batches.

The data includes realistic target-segment matching, engagement,
conversion and campaign-attributed revenue. An independent response
score prevents campaign-assignment cycles from producing campaigns
with no conversions.
*/

USE CommercialSalesAnalysis;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* Prevent accidental duplicate insertion */
IF EXISTS
(
    SELECT 1
    FROM dbo.CustomerCampaignResponses
)
BEGIN
    PRINT 'CustomerCampaignResponses already contains data. No records were inserted.';
    SET NOEXEC ON;
END;
GO

/* =========================================================
   1. Create an indexed customer pool
   ========================================================= */

DROP TABLE IF EXISTS #CustomerPool;

SELECT
    c.CustomerID,
    c.CustomerSegment,

    ROW_NUMBER() OVER
    (
        PARTITION BY c.CustomerSegment
        ORDER BY c.CustomerID
    ) AS SegmentCustomerNumber,

    COUNT(*) OVER
    (
        PARTITION BY c.CustomerSegment
    ) AS SegmentCustomerCount

INTO #CustomerPool

FROM dbo.Customers AS c;
GO

CREATE UNIQUE CLUSTERED INDEX IX_TempCustomerPool
ON #CustomerPool
(
    CustomerSegment,
    SegmentCustomerNumber
);
GO

/* =========================================================
   2. Store campaign details
   ========================================================= */

DROP TABLE IF EXISTS #Campaigns;

SELECT
    CampaignID,
    CampaignName,
    CampaignType,
    TargetSegment,
    StartDate,
    EndDate,
    Budget

INTO #Campaigns

FROM dbo.MarketingCampaigns;
GO

CREATE UNIQUE CLUSTERED INDEX IX_TempCampaigns
ON #Campaigns(CampaignID);
GO

/* =========================================================
   3. Create temporary response staging table
   ========================================================= */

DROP TABLE IF EXISTS #GeneratedResponses;

CREATE TABLE #GeneratedResponses
(
    SequenceNumber INT NOT NULL,
    CampaignID INT NOT NULL,
    CustomerID INT NOT NULL,
    CustomerSegment VARCHAR(30) NOT NULL,
    ResponseDate DATE NOT NULL,
    ResponseType VARCHAR(30) NOT NULL,
    ConvertedFlag BIT NOT NULL
);
GO

/* =========================================================
   4. Generate responses in batches of 10,000
   ========================================================= */

DECLARE @BatchStart INT = 1;
DECLARE @BatchSize INT = 10000;
DECLARE @TotalRows INT = 100000;

WHILE @BatchStart <= @TotalRows
BEGIN
    ;WITH BatchNumbers AS
    (
        SELECT TOP (@BatchSize)
            @BatchStart
            + ROW_NUMBER() OVER
              (
                  ORDER BY
                      a.object_id,
                      b.object_id
              )
            - 1 AS n

        FROM sys.all_objects AS a
        CROSS JOIN sys.all_objects AS b
    ),
    CampaignAssignment AS
    (
        SELECT
            bn.n,
            ((bn.n - 1) % 30) + 1 AS CampaignID

        FROM BatchNumbers AS bn

        WHERE bn.n <= @TotalRows
    ),
    SegmentAssignment AS
    (
        SELECT
            ca.n,
            ca.CampaignID,
            camp.CampaignType,
            camp.TargetSegment,
            camp.StartDate,
            camp.EndDate,

            CASE
                /* All-customer campaigns receive a balanced segment mix */
                WHEN camp.TargetSegment = 'All Customers' THEN
                    CASE ca.n % 3
                        WHEN 0 THEN 'Small Business'
                        WHEN 1 THEN 'Mid-Market'
                        ELSE 'Enterprise'
                    END

                /* Approximately 85% target-segment matches */
                WHEN ca.n % 100 < 85
                    THEN camp.TargetSegment

                /* Remaining responses represent broader targeting */
                WHEN camp.TargetSegment = 'Small Business' THEN
                    CASE ca.n % 2
                        WHEN 0 THEN 'Mid-Market'
                        ELSE 'Enterprise'
                    END

                WHEN camp.TargetSegment = 'Mid-Market' THEN
                    CASE ca.n % 2
                        WHEN 0 THEN 'Small Business'
                        ELSE 'Enterprise'
                    END

                WHEN camp.TargetSegment = 'Enterprise' THEN
                    CASE ca.n % 2
                        WHEN 0 THEN 'Small Business'
                        ELSE 'Mid-Market'
                    END
            END AS AssignedCustomerSegment

        FROM CampaignAssignment AS ca

        INNER JOIN #Campaigns AS camp
            ON ca.CampaignID = camp.CampaignID
    ),
    AssignedCustomers AS
    (
        SELECT
            sa.n,
            sa.CampaignID,
            sa.CampaignType,
            sa.TargetSegment,
            sa.StartDate,
            sa.EndDate,
            cp.CustomerID,
            cp.CustomerSegment,

            CASE
                WHEN sa.TargetSegment = 'All Customers'
                    THEN 1

                WHEN sa.TargetSegment = cp.CustomerSegment
                    THEN 1

                ELSE 0
            END AS SegmentMatchFlag

        FROM SegmentAssignment AS sa

        INNER JOIN #CustomerPool AS cp
            ON cp.CustomerSegment = sa.AssignedCustomerSegment

           AND cp.SegmentCustomerNumber =
               (
                   (
                       CONVERT(BIGINT, sa.n) * 7919
                       + sa.CampaignID * 131
                       - 1
                   )
                   % cp.SegmentCustomerCount
               ) + 1
    ),
    ScoredCustomers AS
    (
        SELECT
            ac.n,
            ac.CampaignID,
            ac.CustomerID,
            ac.CustomerSegment,
            ac.CampaignType,
            ac.TargetSegment,
            ac.StartDate,
            ac.EndDate,
            ac.SegmentMatchFlag,

            /*
            Independent response score avoids a repeating-cycle
            relationship between campaign allocation and response type.
            */
            CAST
            (
                ABS
                (
                    CONVERT
                    (
                        BIGINT,
                        CHECKSUM
                        (
                            ac.n,
                            ac.CampaignID,
                            ac.CustomerID,
                            YEAR(ac.StartDate),
                            MONTH(ac.StartDate)
                        )
                    )
                ) % 100
                AS INT
            ) AS ResponseScore

        FROM AssignedCustomers AS ac
    ),
    ResponseDesign AS
    (
        SELECT
            sc.n,
            sc.CampaignID,
            sc.CustomerID,
            sc.CustomerSegment,

            DATEADD
            (
                DAY,

                (
                    CONVERT(BIGINT, sc.n) * 13
                )
                %
                (
                    DATEDIFF
                    (
                        DAY,
                        sc.StartDate,
                        sc.EndDate
                    ) + 1
                ),

                sc.StartDate
            ) AS ResponseDate,

            CASE
                /* Lower engagement for target-segment mismatches */
                WHEN sc.SegmentMatchFlag = 0 THEN
                    CASE
                        WHEN sc.ResponseScore < 4 THEN 'Opened'
                        WHEN sc.ResponseScore < 7 THEN 'Clicked'
                        WHEN sc.ResponseScore < 9 THEN 'Enquired'
                        WHEN sc.ResponseScore < 10 THEN 'Registered'
                        WHEN sc.ResponseScore < 11 THEN 'Purchased'
                        ELSE 'No Response'
                    END

                WHEN sc.CampaignType = 'Email' THEN
                    CASE
                        WHEN sc.ResponseScore < 36 THEN 'Opened'
                        WHEN sc.ResponseScore < 53 THEN 'Clicked'
                        WHEN sc.ResponseScore < 62 THEN 'Enquired'
                        WHEN sc.ResponseScore < 68 THEN 'Registered'
                        WHEN sc.ResponseScore < 74 THEN 'Purchased'
                        ELSE 'No Response'
                    END

                WHEN sc.CampaignType = 'Paid Search' THEN
                    CASE
                        WHEN sc.ResponseScore < 22 THEN 'Clicked'
                        WHEN sc.ResponseScore < 38 THEN 'Enquired'
                        WHEN sc.ResponseScore < 48 THEN 'Registered'
                        WHEN sc.ResponseScore < 59 THEN 'Purchased'
                        ELSE 'No Response'
                    END

                WHEN sc.CampaignType = 'Social Media' THEN
                    CASE
                        WHEN sc.ResponseScore < 31 THEN 'Opened'
                        WHEN sc.ResponseScore < 47 THEN 'Clicked'
                        WHEN sc.ResponseScore < 56 THEN 'Enquired'
                        WHEN sc.ResponseScore < 62 THEN 'Registered'
                        WHEN sc.ResponseScore < 69 THEN 'Purchased'
                        ELSE 'No Response'
                    END

                WHEN sc.CampaignType = 'Trade Show' THEN
                    CASE
                        WHEN sc.ResponseScore < 24 THEN 'Enquired'
                        WHEN sc.ResponseScore < 43 THEN 'Registered'
                        WHEN sc.ResponseScore < 61 THEN 'Purchased'
                        ELSE 'No Response'
                    END

                WHEN sc.CampaignType = 'Partner Promotion' THEN
                    CASE
                        WHEN sc.ResponseScore < 24 THEN 'Clicked'
                        WHEN sc.ResponseScore < 40 THEN 'Enquired'
                        WHEN sc.ResponseScore < 52 THEN 'Registered'
                        WHEN sc.ResponseScore < 67 THEN 'Purchased'
                        ELSE 'No Response'
                    END

                WHEN sc.CampaignType = 'Direct Mail' THEN
                    CASE
                        WHEN sc.ResponseScore < 17 THEN 'Opened'
                        WHEN sc.ResponseScore < 28 THEN 'Enquired'
                        WHEN sc.ResponseScore < 35 THEN 'Registered'
                        WHEN sc.ResponseScore < 42 THEN 'Purchased'
                        ELSE 'No Response'
                    END
            END AS ResponseType

        FROM ScoredCustomers AS sc
    )
    INSERT INTO #GeneratedResponses
    (
        SequenceNumber,
        CampaignID,
        CustomerID,
        CustomerSegment,
        ResponseDate,
        ResponseType,
        ConvertedFlag
    )
    SELECT
        rd.n,
        rd.CampaignID,
        rd.CustomerID,
        rd.CustomerSegment,
        rd.ResponseDate,
        rd.ResponseType,

        CASE
            WHEN rd.ResponseType = 'Purchased'
                THEN 1
            ELSE 0
        END AS ConvertedFlag

    FROM ResponseDesign AS rd;

    SET @BatchStart = @BatchStart + @BatchSize;
END;
GO

CREATE CLUSTERED INDEX IX_TempResponses_Campaign
ON #GeneratedResponses
(
    CampaignID,
    SequenceNumber
);
GO

/* =========================================================
   5. Calculate conversion totals by campaign
   ========================================================= */

DROP TABLE IF EXISTS #ConversionCounts;

SELECT
    CampaignID,

    SUM
    (
        CASE
            WHEN ConvertedFlag = 1 THEN 1
            ELSE 0
        END
    ) AS ConversionCount

INTO #ConversionCounts

FROM #GeneratedResponses

GROUP BY CampaignID;
GO

CREATE UNIQUE CLUSTERED INDEX IX_TempConversionCounts
ON #ConversionCounts(CampaignID);
GO

/* =========================================================
   6. Define realistic campaign revenue targets
   ========================================================= */

DROP TABLE IF EXISTS #CampaignRevenueTargets;

SELECT
    c.CampaignID,

    CAST
    (
        c.Budget
        *
        (
            CASE c.CampaignType
                WHEN 'Email' THEN 1.12
                WHEN 'Paid Search' THEN 1.35
                WHEN 'Social Media' THEN 1.08
                WHEN 'Trade Show' THEN 1.55
                WHEN 'Partner Promotion' THEN 1.70
                WHEN 'Direct Mail' THEN 0.92
            END

            + ((c.CampaignID * 7) % 21) / 100.0
        )
        AS DECIMAL(18,2)
    ) AS TargetCampaignRevenue

INTO #CampaignRevenueTargets

FROM #Campaigns AS c;
GO

CREATE UNIQUE CLUSTERED INDEX IX_TempCampaignRevenueTargets
ON #CampaignRevenueTargets(CampaignID);
GO

/* =========================================================
   7. Insert final campaign responses
   ========================================================= */

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
    gr.CampaignID,
    gr.CustomerID,
    gr.ResponseDate,
    gr.ResponseType,
    gr.ConvertedFlag,

    CASE
        WHEN gr.ConvertedFlag = 0
            THEN NULL

        ELSE CAST
        (
            crt.TargetCampaignRevenue
            /
            NULLIF(cc.ConversionCount, 0)
            *
            (
                0.90
                + ((gr.SequenceNumber - 1) % 21) / 100.0
            )
            AS DECIMAL(12,2)
        )
    END AS RevenueGenerated

FROM #GeneratedResponses AS gr

INNER JOIN #ConversionCounts AS cc
    ON gr.CampaignID = cc.CampaignID

INNER JOIN #CampaignRevenueTargets AS crt
    ON gr.CampaignID = crt.CampaignID;
GO

/* =========================================================
   8. Validate total response count and dates
   ========================================================= */

SELECT
    COUNT(*) AS CampaignResponseCount,
    MIN(ResponseDate) AS FirstResponseDate,
    MAX(ResponseDate) AS LastResponseDate

FROM dbo.CustomerCampaignResponses;
GO

/* =========================================================
   9. Validate campaign conversion distribution
   ========================================================= */

SELECT
    MIN(Conversions) AS MinimumCampaignConversions,

    CAST
    (
        AVG(Conversions * 1.0)
        AS DECIMAL(10,2)
    ) AS AverageCampaignConversions,

    MAX(Conversions) AS MaximumCampaignConversions

FROM
(
    SELECT
        mc.CampaignID,

        SUM
        (
            CASE
                WHEN ccr.ConvertedFlag = 1 THEN 1
                ELSE 0
            END
        ) AS Conversions

    FROM dbo.MarketingCampaigns AS mc

    LEFT JOIN dbo.CustomerCampaignResponses AS ccr
        ON mc.CampaignID = ccr.CampaignID

    GROUP BY mc.CampaignID
) AS CampaignConversions;
GO

/* =========================================================
   10. Validate ROI distribution
   ========================================================= */

;WITH CampaignPerformance AS
(
    SELECT
        mc.CampaignID,
        mc.Budget,

        SUM
        (
            ISNULL(ccr.RevenueGenerated, 0)
        ) AS RevenueGenerated

    FROM dbo.MarketingCampaigns AS mc

    LEFT JOIN dbo.CustomerCampaignResponses AS ccr
        ON mc.CampaignID = ccr.CampaignID

    GROUP BY
        mc.CampaignID,
        mc.Budget
)
SELECT
    CAST
    (
        MIN
        (
            (RevenueGenerated - Budget) * 100.0
            / NULLIF(Budget, 0)
        )
        AS DECIMAL(10,2)
    ) AS MinimumROI,

    CAST
    (
        AVG
        (
            (RevenueGenerated - Budget) * 100.0
            / NULLIF(Budget, 0)
        )
        AS DECIMAL(10,2)
    ) AS AverageROI,

    CAST
    (
        MAX
        (
            (RevenueGenerated - Budget) * 100.0
            / NULLIF(Budget, 0)
        )
        AS DECIMAL(10,2)
    ) AS MaximumROI

FROM CampaignPerformance;
GO

/* =========================================================
   11. Validate campaign response dates
   ========================================================= */

SELECT
    COUNT(*) AS InvalidResponseDateCount

FROM dbo.CustomerCampaignResponses AS ccr

INNER JOIN dbo.MarketingCampaigns AS mc
    ON ccr.CampaignID = mc.CampaignID

WHERE ccr.ResponseDate < mc.StartDate
   OR ccr.ResponseDate > mc.EndDate;
GO

/* =========================================================
   12. Validate conversion and revenue consistency
   ========================================================= */

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

/* =========================================================
   13. Remove temporary tables
   ========================================================= */

DROP TABLE IF EXISTS #CampaignRevenueTargets;
DROP TABLE IF EXISTS #ConversionCounts;
DROP TABLE IF EXISTS #GeneratedResponses;
DROP TABLE IF EXISTS #Campaigns;
DROP TABLE IF EXISTS #CustomerPool;
GO

SET NOCOUNT OFF;
GO

SET NOEXEC OFF;
GO