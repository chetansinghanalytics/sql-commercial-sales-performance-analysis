/*
Project: Commercial Sales Performance Analysis
File: 08_marketing_campaign_analysis.sql
Author: Chetan Singh

Purpose:
Evaluate marketing campaign performance across engagement, conversions,
revenue, ROI, campaign type, customer segment and target-segment fit.
*/

USE CommercialSalesAnalysis;
GO

/* =========================================================
   1. Overall campaign performance
   ========================================================= */

SELECT
    mc.CampaignID,
    mc.CampaignName,
    mc.CampaignType,
    mc.TargetSegment,
    mc.StartDate,
    mc.EndDate,
    mc.Budget,
    mc.CampaignStatus,

    COUNT(ccr.ResponseID) AS TotalResponses,

    SUM(
        CASE
            WHEN ccr.ResponseType <> 'No Response' THEN 1
            ELSE 0
        END
    ) AS EngagedCustomers,

    SUM(
        CASE
            WHEN ccr.ConvertedFlag = 1 THEN 1
            ELSE 0
        END
    ) AS Conversions,

    CAST(
        SUM(
            CASE
                WHEN ccr.ResponseType <> 'No Response' THEN 1
                ELSE 0
            END
        ) * 100.0
        / NULLIF(COUNT(ccr.ResponseID), 0)
        AS DECIMAL(8,2)
    ) AS EngagementRatePercentage,

    CAST(
        SUM(
            CASE
                WHEN ccr.ConvertedFlag = 1 THEN 1
                ELSE 0
            END
        ) * 100.0
        / NULLIF(COUNT(ccr.ResponseID), 0)
        AS DECIMAL(8,2)
    ) AS ConversionRatePercentage,

    CAST(
        SUM(
            ISNULL(ccr.RevenueGenerated, 0)
        )
        AS DECIMAL(18,2)
    ) AS RevenueGenerated,

    CAST(
        SUM(
            ISNULL(ccr.RevenueGenerated, 0)
        ) - mc.Budget
        AS DECIMAL(18,2)
    ) AS CampaignProfit,

    CAST(
        (
            SUM(
                ISNULL(ccr.RevenueGenerated, 0)
            ) - mc.Budget
        ) * 100.0
        / NULLIF(mc.Budget, 0)
        AS DECIMAL(8,2)
    ) AS ReturnOnInvestmentPercentage

FROM dbo.MarketingCampaigns AS mc

LEFT JOIN dbo.CustomerCampaignResponses AS ccr
    ON mc.CampaignID = ccr.CampaignID

GROUP BY
    mc.CampaignID,
    mc.CampaignName,
    mc.CampaignType,
    mc.TargetSegment,
    mc.StartDate,
    mc.EndDate,
    mc.Budget,
    mc.CampaignStatus

ORDER BY ReturnOnInvestmentPercentage DESC;
GO

/* =========================================================
   2. Campaign type performance
   ========================================================= */

SELECT
    mc.CampaignType,

    COUNT(DISTINCT mc.CampaignID) AS CampaignCount,
    COUNT(ccr.ResponseID) AS TotalResponses,

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
        / NULLIF(COUNT(ccr.ResponseID), 0)
        AS DECIMAL(8,2)
    ) AS ConversionRatePercentage,

    CAST(
        SUM(mc.Budget)
        / NULLIF(COUNT(DISTINCT mc.CampaignID), 0)
        AS DECIMAL(18,2)
    ) AS AverageCampaignBudget,

    CAST(
        SUM(
            ISNULL(ccr.RevenueGenerated, 0)
        )
        AS DECIMAL(18,2)
    ) AS RevenueGenerated

FROM dbo.MarketingCampaigns AS mc

LEFT JOIN dbo.CustomerCampaignResponses AS ccr
    ON mc.CampaignID = ccr.CampaignID

GROUP BY mc.CampaignType

ORDER BY ConversionRatePercentage DESC;
GO

/* =========================================================
   3. Response type distribution
   ========================================================= */

SELECT
    ccr.ResponseType,

    COUNT(*) AS ResponseCount,

    CAST(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER ()
        AS DECIMAL(8,2)
    ) AS ResponseSharePercentage,

    CAST(
        SUM(
            ISNULL(ccr.RevenueGenerated, 0)
        )
        AS DECIMAL(18,2)
    ) AS RevenueGenerated

FROM dbo.CustomerCampaignResponses AS ccr

GROUP BY ccr.ResponseType

ORDER BY ResponseCount DESC;
GO

/* =========================================================
   4. Performance by customer segment
   ========================================================= */

SELECT
    c.CustomerSegment,

    COUNT(ccr.ResponseID) AS TotalResponses,

    SUM(
        CASE
            WHEN ccr.ResponseType <> 'No Response' THEN 1
            ELSE 0
        END
    ) AS EngagedCustomers,

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
        / NULLIF(COUNT(ccr.ResponseID), 0)
        AS DECIMAL(8,2)
    ) AS ConversionRatePercentage,

    CAST(
        SUM(
            ISNULL(ccr.RevenueGenerated, 0)
        )
        AS DECIMAL(18,2)
    ) AS RevenueGenerated,

    CAST(
        SUM(
            ISNULL(ccr.RevenueGenerated, 0)
        )
        / NULLIF(
            SUM(
                CASE
                    WHEN ccr.ConvertedFlag = 1 THEN 1
                    ELSE 0
                END
            ),
            0
        )
        AS DECIMAL(18,2)
    ) AS RevenuePerConversion

FROM dbo.CustomerCampaignResponses AS ccr

INNER JOIN dbo.Customers AS c
    ON ccr.CustomerID = c.CustomerID

GROUP BY c.CustomerSegment

ORDER BY RevenueGenerated DESC;
GO

/* =========================================================
   5. Target-segment match analysis
   ========================================================= */

SELECT
    CASE
        WHEN mc.TargetSegment = 'All Customers'
            THEN 'All Customers Campaign'

        WHEN mc.TargetSegment = c.CustomerSegment
            THEN 'Target Segment Match'

        ELSE 'Target Segment Mismatch'
    END AS SegmentAlignment,

    COUNT(*) AS TotalResponses,

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
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(8,2)
    ) AS ConversionRatePercentage,

    CAST(
        SUM(
            ISNULL(ccr.RevenueGenerated, 0)
        )
        AS DECIMAL(18,2)
    ) AS RevenueGenerated

FROM dbo.CustomerCampaignResponses AS ccr

INNER JOIN dbo.MarketingCampaigns AS mc
    ON ccr.CampaignID = mc.CampaignID

INNER JOIN dbo.Customers AS c
    ON ccr.CustomerID = c.CustomerID

GROUP BY
    CASE
        WHEN mc.TargetSegment = 'All Customers'
            THEN 'All Customers Campaign'

        WHEN mc.TargetSegment = c.CustomerSegment
            THEN 'Target Segment Match'

        ELSE 'Target Segment Mismatch'
    END

ORDER BY ConversionRatePercentage DESC;
GO

/* =========================================================
   6. Cost per conversion
   ========================================================= */

;WITH CampaignConversions AS
(
    SELECT
        mc.CampaignID,
        mc.CampaignName,
        mc.CampaignType,
        mc.Budget,

        SUM(
            CASE
                WHEN ccr.ConvertedFlag = 1 THEN 1
                ELSE 0
            END
        ) AS Conversions

    FROM dbo.MarketingCampaigns AS mc

    LEFT JOIN dbo.CustomerCampaignResponses AS ccr
        ON mc.CampaignID = ccr.CampaignID

    GROUP BY
        mc.CampaignID,
        mc.CampaignName,
        mc.CampaignType,
        mc.Budget
)
SELECT
    CampaignID,
    CampaignName,
    CampaignType,
    Budget,
    Conversions,

    CAST(
        Budget
        / NULLIF(Conversions, 0)
        AS DECIMAL(18,2)
    ) AS CostPerConversion

FROM CampaignConversions

ORDER BY CostPerConversion ASC;
GO

/* =========================================================
   7. Campaign ranking by ROI
   ========================================================= */

;WITH CampaignROI AS
(
    SELECT
        mc.CampaignID,
        mc.CampaignName,
        mc.CampaignType,
        mc.TargetSegment,
        mc.Budget,

        SUM(
            ISNULL(ccr.RevenueGenerated, 0)
        ) AS RevenueGenerated

    FROM dbo.MarketingCampaigns AS mc

    LEFT JOIN dbo.CustomerCampaignResponses AS ccr
        ON mc.CampaignID = ccr.CampaignID

    GROUP BY
        mc.CampaignID,
        mc.CampaignName,
        mc.CampaignType,
        mc.TargetSegment,
        mc.Budget
)
SELECT
    CampaignID,
    CampaignName,
    CampaignType,
    TargetSegment,

    CAST(
        Budget
        AS DECIMAL(18,2)
    ) AS Budget,

    CAST(
        RevenueGenerated
        AS DECIMAL(18,2)
    ) AS RevenueGenerated,

    CAST(
        RevenueGenerated - Budget
        AS DECIMAL(18,2)
    ) AS CampaignProfit,

    CAST(
        (
            RevenueGenerated - Budget
        ) * 100.0
        / NULLIF(Budget, 0)
        AS DECIMAL(8,2)
    ) AS ReturnOnInvestmentPercentage,

    DENSE_RANK() OVER
    (
        ORDER BY
            (
                RevenueGenerated - Budget
            ) * 100.0
            / NULLIF(Budget, 0)
            DESC
    ) AS ROIRank

FROM CampaignROI

ORDER BY ROIRank;
GO

/* =========================================================
   8. Monthly campaign response trend
   ========================================================= */

SELECT
    DATEFROMPARTS(
        YEAR(ccr.ResponseDate),
        MONTH(ccr.ResponseDate),
        1
    ) AS ResponseMonth,

    COUNT(*) AS TotalResponses,

    SUM(
        CASE
            WHEN ccr.ResponseType <> 'No Response' THEN 1
            ELSE 0
        END
    ) AS EngagedResponses,

    SUM(
        CASE
            WHEN ccr.ConvertedFlag = 1 THEN 1
            ELSE 0
        END
    ) AS Conversions,

    CAST(
        SUM(
            ISNULL(ccr.RevenueGenerated, 0)
        )
        AS DECIMAL(18,2)
    ) AS RevenueGenerated

FROM dbo.CustomerCampaignResponses AS ccr

GROUP BY
    DATEFROMPARTS(
        YEAR(ccr.ResponseDate),
        MONTH(ccr.ResponseDate),
        1
    )

ORDER BY ResponseMonth;
GO