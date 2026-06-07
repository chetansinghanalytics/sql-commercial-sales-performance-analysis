/*
Project: Commercial Sales Performance Analysis
File: 09_executive_insights.sql
Author: Chetan Singh

Purpose:
Produce concise executive-level findings across sales growth,
profitability, customer concentration, regional performance,
sales representative achievement, returns and marketing ROI.
*/

USE CommercialSalesAnalysis;
GO

/* =========================================================
   1. Executive KPI summary
   ========================================================= */

SELECT
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    COUNT(DISTINCT o.CustomerID) AS ActiveCustomers,
    COUNT(DISTINCT oi.ProductID) AS ProductsSold,
    SUM(oi.Quantity) AS UnitsSold,

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
        SUM(
            oi.Quantity
            * (oi.UnitSellingPrice - oi.UnitCost)
        ) * 100.0
        /
        NULLIF(
            SUM(oi.Quantity * oi.UnitSellingPrice),
            0
        )
        AS DECIMAL(8,2)
    ) AS GrossMarginPercentage,

    CAST(
        SUM(oi.Quantity * oi.UnitSellingPrice)
        / NULLIF(COUNT(DISTINCT o.OrderID), 0)
        AS DECIMAL(18,2)
    ) AS AverageOrderValue

FROM dbo.Orders AS o

INNER JOIN dbo.OrderItems AS oi
    ON o.OrderID = oi.OrderID

WHERE o.OrderStatus <> 'Cancelled';
GO

/* =========================================================
   2. Annual growth summary
   ========================================================= */

;WITH AnnualPerformance AS
(
    SELECT
        YEAR(o.OrderDate) AS SalesYear,

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

    GROUP BY YEAR(o.OrderDate)
),
AnnualGrowth AS
(
    SELECT
        SalesYear,
        GrossRevenue,
        GrossProfit,

        LAG(GrossRevenue) OVER
        (
            ORDER BY SalesYear
        ) AS PreviousYearRevenue,

        LAG(GrossProfit) OVER
        (
            ORDER BY SalesYear
        ) AS PreviousYearGrossProfit

    FROM AnnualPerformance
)
SELECT
    SalesYear,

    CAST(
        GrossRevenue
        AS DECIMAL(18,2)
    ) AS GrossRevenue,

    CAST(
        (
            GrossRevenue - PreviousYearRevenue
        ) * 100.0
        / NULLIF(PreviousYearRevenue, 0)
        AS DECIMAL(8,2)
    ) AS RevenueGrowthPercentage,

    CAST(
        GrossProfit
        AS DECIMAL(18,2)
    ) AS GrossProfit,

    CAST(
        (
            GrossProfit - PreviousYearGrossProfit
        ) * 100.0
        / NULLIF(PreviousYearGrossProfit, 0)
        AS DECIMAL(8,2)
    ) AS GrossProfitGrowthPercentage

FROM AnnualGrowth

ORDER BY SalesYear;
GO

/* =========================================================
   3. Top and bottom performing regions
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
),
RankedRegions AS
(
    SELECT
        Region,
        GrossRevenue,
        GrossProfit,

        DENSE_RANK() OVER
        (
            ORDER BY GrossRevenue DESC
        ) AS RevenueRank,

        DENSE_RANK() OVER
        (
            ORDER BY GrossRevenue ASC
        ) AS ReverseRevenueRank

    FROM RegionalPerformance
)
SELECT
    CASE
        WHEN RevenueRank <= 3 THEN 'Top Performing Region'
        WHEN ReverseRevenueRank <= 3 THEN 'Lowest Performing Region'
        ELSE 'Middle Performing Region'
    END AS PerformanceGroup,

    Region,

    CAST(
        GrossRevenue
        AS DECIMAL(18,2)
    ) AS GrossRevenue,

    CAST(
        GrossProfit
        AS DECIMAL(18,2)
    ) AS GrossProfit,

    RevenueRank

FROM RankedRegions

WHERE RevenueRank <= 3
   OR ReverseRevenueRank <= 3

ORDER BY RevenueRank;
GO

/* =========================================================
   4. Customer revenue concentration
   ========================================================= */

;WITH CustomerRevenue AS
(
    SELECT
        o.CustomerID,

        SUM(
            oi.Quantity * oi.UnitSellingPrice
        ) AS GrossRevenue

    FROM dbo.Orders AS o

    INNER JOIN dbo.OrderItems AS oi
        ON o.OrderID = oi.OrderID

    WHERE o.OrderStatus <> 'Cancelled'

    GROUP BY o.CustomerID
),
RankedCustomers AS
(
    SELECT
        CustomerID,
        GrossRevenue,

        ROW_NUMBER() OVER
        (
            ORDER BY GrossRevenue DESC
        ) AS RevenueRank,

        COUNT(*) OVER () AS TotalCustomers,

        SUM(GrossRevenue) OVER () AS TotalRevenue

    FROM CustomerRevenue
)
SELECT
    CAST(
        SUM(
            CASE
                WHEN RevenueRank <= TotalCustomers * 0.10
                    THEN GrossRevenue
                ELSE 0
            END
        ) * 100.0
        / MAX(TotalRevenue)
        AS DECIMAL(8,2)
    ) AS RevenueShareFromTop10PercentCustomers,

    CAST(
        SUM(
            CASE
                WHEN RevenueRank <= TotalCustomers * 0.01
                    THEN GrossRevenue
                ELSE 0
            END
        ) * 100.0
        / MAX(TotalRevenue)
        AS DECIMAL(8,2)
    ) AS RevenueShareFromTop1PercentCustomers

FROM RankedCustomers;
GO

/* =========================================================
   5. Highest-value customer segment
   ========================================================= */

SELECT
    c.CustomerSegment,

    COUNT(DISTINCT c.CustomerID) AS ActiveCustomers,

    CAST(
        SUM(oi.Quantity * oi.UnitSellingPrice)
        AS DECIMAL(18,2)
    ) AS GrossRevenue,

    CAST(
        SUM(oi.Quantity * oi.UnitSellingPrice)
        / NULLIF(COUNT(DISTINCT c.CustomerID), 0)
        AS DECIMAL(18,2)
    ) AS RevenuePerCustomer,

    CAST(
        AVG(oi.DiscountPercentage)
        AS DECIMAL(8,2)
    ) AS AverageDiscountPercentage

FROM dbo.Customers AS c

INNER JOIN dbo.Orders AS o
    ON c.CustomerID = o.CustomerID

INNER JOIN dbo.OrderItems AS oi
    ON o.OrderID = oi.OrderID

WHERE o.OrderStatus <> 'Cancelled'

GROUP BY c.CustomerSegment

ORDER BY RevenuePerCustomer DESC;
GO

/* =========================================================
   6. Low-margin high-revenue products
   ========================================================= */

;WITH ProductPerformance AS
(
    SELECT
        p.ProductID,
        p.ProductName,
        p.Category,

        SUM(
            oi.Quantity * oi.UnitSellingPrice
        ) AS GrossRevenue,

        SUM(
            oi.Quantity
            * (oi.UnitSellingPrice - oi.UnitCost)
        ) AS GrossProfit

    FROM dbo.Products AS p

    INNER JOIN dbo.OrderItems AS oi
        ON p.ProductID = oi.ProductID

    INNER JOIN dbo.Orders AS o
        ON oi.OrderID = o.OrderID

    WHERE o.OrderStatus <> 'Cancelled'

    GROUP BY
        p.ProductID,
        p.ProductName,
        p.Category
),
RankedProducts AS
(
    SELECT
        ProductID,
        ProductName,
        Category,
        GrossRevenue,
        GrossProfit,

        GrossProfit * 100.0
        / NULLIF(GrossRevenue, 0)
        AS GrossMarginPercentage,

        PERCENT_RANK() OVER
        (
            ORDER BY GrossRevenue
        ) AS RevenuePercentile

    FROM ProductPerformance
)
SELECT TOP (20)
    ProductID,
    ProductName,
    Category,

    CAST(
        GrossRevenue
        AS DECIMAL(18,2)
    ) AS GrossRevenue,

    CAST(
        GrossMarginPercentage
        AS DECIMAL(8,2)
    ) AS GrossMarginPercentage

FROM RankedProducts

WHERE RevenuePercentile >= 0.75
  AND GrossMarginPercentage < 25

ORDER BY GrossRevenue DESC;
GO

/* =========================================================
   7. Sales representative target achievement
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
        ) AS ActualRevenue

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
RepAchievement AS
(
    SELECT
        st.SalesRepID,

        COUNT(*) AS TargetMonths,

        SUM(
            CASE
                WHEN ISNULL(ma.ActualRevenue, 0) >= st.RevenueTarget
                    THEN 1
                ELSE 0
            END
        ) AS MonthsTargetMet,

        SUM(st.RevenueTarget) AS TotalRevenueTarget,

        SUM(
            ISNULL(ma.ActualRevenue, 0)
        ) AS TotalActualRevenue

    FROM dbo.SalesTargets AS st

    LEFT JOIN MonthlyActuals AS ma
        ON st.SalesRepID = ma.SalesRepID
       AND st.TargetMonth = ma.SalesMonth

    GROUP BY st.SalesRepID
)
SELECT TOP (10)
    ra.SalesRepID,
    sr.SalesRepName,
    sr.Region,
    sr.Team,

    CAST(
        ra.MonthsTargetMet * 100.0
        / NULLIF(ra.TargetMonths, 0)
        AS DECIMAL(8,2)
    ) AS PercentageOfMonthsTargetMet,

    CAST(
        ra.TotalActualRevenue * 100.0
        / NULLIF(ra.TotalRevenueTarget, 0)
        AS DECIMAL(8,2)
    ) AS OverallTargetAchievementPercentage

FROM RepAchievement AS ra

INNER JOIN dbo.SalesRepresentatives AS sr
    ON ra.SalesRepID = sr.SalesRepID

ORDER BY OverallTargetAchievementPercentage DESC;
GO

/* =========================================================
   8. Return cost summary
   ========================================================= */

SELECT
    COUNT(DISTINCT oi.OrderID) AS OrdersWithReturns,
    SUM(r.ReturnQuantity) AS UnitsReturned,

    CAST(
        SUM(r.RefundAmount)
        AS DECIMAL(18,2)
    ) AS TotalRefundAmount,

    CAST(
        COUNT(DISTINCT oi.OrderID) * 100.0
        /
        NULLIF(
            (
                SELECT COUNT(DISTINCT OrderID)
                FROM dbo.Orders
                WHERE OrderStatus <> 'Cancelled'
            ),
            0
        )
        AS DECIMAL(8,2)
    ) AS OrderReturnRatePercentage

FROM dbo.Returns AS r

INNER JOIN dbo.OrderItems AS oi
    ON r.OrderItemID = oi.OrderItemID;
GO

/* =========================================================
   9. Best and worst marketing campaigns by ROI
   ========================================================= */

;WITH CampaignROI AS
(
    SELECT
        mc.CampaignID,
        mc.CampaignName,
        mc.CampaignType,
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
        mc.Budget
),
RankedCampaigns AS
(
    SELECT
        CampaignID,
        CampaignName,
        CampaignType,
        Budget,
        RevenueGenerated,

        (
            RevenueGenerated - Budget
        ) * 100.0
        / NULLIF(Budget, 0)
        AS ROIPercentage,

        DENSE_RANK() OVER
        (
            ORDER BY
                (
                    RevenueGenerated - Budget
                ) * 100.0
                / NULLIF(Budget, 0)
                DESC
        ) AS BestROIRank,

        DENSE_RANK() OVER
        (
            ORDER BY
                (
                    RevenueGenerated - Budget
                ) * 100.0
                / NULLIF(Budget, 0)
                ASC
        ) AS WorstROIRank

    FROM CampaignROI
)
SELECT
    CASE
        WHEN BestROIRank <= 3 THEN 'Top ROI Campaign'
        WHEN WorstROIRank <= 3 THEN 'Lowest ROI Campaign'
    END AS CampaignPerformanceGroup,

    CampaignID,
    CampaignName,
    CampaignType,

    CAST(
        Budget
        AS DECIMAL(18,2)
    ) AS Budget,

    CAST(
        RevenueGenerated
        AS DECIMAL(18,2)
    ) AS RevenueGenerated,

    CAST(
        ROIPercentage
        AS DECIMAL(8,2)
    ) AS ROIPercentage

FROM RankedCampaigns

WHERE BestROIRank <= 3
   OR WorstROIRank <= 3

ORDER BY ROIPercentage DESC;
GO