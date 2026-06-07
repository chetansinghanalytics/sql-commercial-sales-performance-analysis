/*
Project: Commercial Sales Performance Analysis
File: 01_create_power_bi_views.sql
Author: Chetan Singh

Purpose:
Create Power BI-ready views for sales, customers, products, returns,
sales representatives and marketing campaign analysis.
*/

USE CommercialSalesAnalysis;
GO

/* =========================================================
   1. Sales fact view
   ========================================================= */

CREATE OR ALTER VIEW dbo.vw_PowerBI_Sales
AS
SELECT
    o.OrderID,
    o.OrderDate,
    YEAR(o.OrderDate) AS SalesYear,
    MONTH(o.OrderDate) AS SalesMonthNumber,
    DATENAME(MONTH, o.OrderDate) AS SalesMonthName,
    DATEFROMPARTS
    (
        YEAR(o.OrderDate),
        MONTH(o.OrderDate),
        1
    ) AS SalesMonth,

    o.CustomerID,
    c.CustomerName,
    c.CustomerSegment,
    c.Industry,
    c.AcquisitionChannel,

    o.SalesRepID,
    sr.SalesRepName,
    sr.Team,
    sr.ManagerName,

    o.Region,
    c.City,
    o.SalesChannel,
    o.PaymentMethod,
    o.OrderStatus,
    o.ShippingCost,
    o.DeliveryDays,

    oi.OrderItemID,
    oi.ProductID,
    p.ProductName,
    p.Category,
    p.Subcategory,
    p.Brand,
    p.DiscontinuedFlag,

    oi.Quantity,
    oi.UnitSellingPrice,
    oi.UnitCost,
    oi.DiscountPercentage,

    CAST
    (
        oi.Quantity * oi.UnitSellingPrice
        AS DECIMAL(18,2)
    ) AS GrossRevenue,

    CAST
    (
        oi.Quantity * oi.UnitCost
        AS DECIMAL(18,2)
    ) AS TotalCost,

    CAST
    (
        oi.Quantity
        * (oi.UnitSellingPrice - oi.UnitCost)
        AS DECIMAL(18,2)
    ) AS GrossProfit,

    CAST
    (
        (
            oi.UnitSellingPrice - oi.UnitCost
        ) * 100.0
        / NULLIF(oi.UnitSellingPrice, 0)
        AS DECIMAL(8,2)
    ) AS GrossMarginPercentage

FROM dbo.Orders AS o

INNER JOIN dbo.OrderItems AS oi
    ON o.OrderID = oi.OrderID

INNER JOIN dbo.Customers AS c
    ON o.CustomerID = c.CustomerID

INNER JOIN dbo.Products AS p
    ON oi.ProductID = p.ProductID

INNER JOIN dbo.SalesRepresentatives AS sr
    ON o.SalesRepID = sr.SalesRepID;
GO

/* =========================================================
   2. Sales target view
   ========================================================= */

CREATE OR ALTER VIEW dbo.vw_PowerBI_SalesTargets
AS
WITH MonthlyActuals AS
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
        ) AS ActualRevenue,

        SUM
        (
            oi.Quantity
            * (oi.UnitSellingPrice - oi.UnitCost)
        ) AS ActualGrossProfit

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
)
SELECT
    st.TargetID,
    st.SalesRepID,
    sr.SalesRepName,
    sr.Region,
    sr.Team,
    sr.ManagerName,
    st.TargetMonth,

    st.RevenueTarget,
    ISNULL(ma.ActualRevenue, 0) AS ActualRevenue,

    CAST
    (
        ISNULL(ma.ActualRevenue, 0)
        - st.RevenueTarget
        AS DECIMAL(18,2)
    ) AS RevenueVariance,

    CAST
    (
        ISNULL(ma.ActualRevenue, 0) * 100.0
        / NULLIF(st.RevenueTarget, 0)
        AS DECIMAL(8,2)
    ) AS RevenueTargetAchievementPercentage,

    st.GrossProfitTarget,
    ISNULL(ma.ActualGrossProfit, 0) AS ActualGrossProfit,

    CAST
    (
        ISNULL(ma.ActualGrossProfit, 0)
        - st.GrossProfitTarget
        AS DECIMAL(18,2)
    ) AS GrossProfitVariance,

    CAST
    (
        ISNULL(ma.ActualGrossProfit, 0) * 100.0
        / NULLIF(st.GrossProfitTarget, 0)
        AS DECIMAL(8,2)
    ) AS GrossProfitTargetAchievementPercentage,

    st.NewCustomerTarget

FROM dbo.SalesTargets AS st

INNER JOIN dbo.SalesRepresentatives AS sr
    ON st.SalesRepID = sr.SalesRepID

LEFT JOIN MonthlyActuals AS ma
    ON st.SalesRepID = ma.SalesRepID
   AND st.TargetMonth = ma.SalesMonth;
GO

/* =========================================================
   3. Returns view
   ========================================================= */

CREATE OR ALTER VIEW dbo.vw_PowerBI_Returns
AS
SELECT
    r.ReturnID,
    r.ReturnDate,
    YEAR(r.ReturnDate) AS ReturnYear,
    MONTH(r.ReturnDate) AS ReturnMonthNumber,
    DATENAME(MONTH, r.ReturnDate) AS ReturnMonthName,

    oi.OrderItemID,
    oi.OrderID,
    o.OrderDate,
    o.CustomerID,
    c.CustomerName,
    c.CustomerSegment,
    o.Region,

    oi.ProductID,
    p.ProductName,
    p.Category,
    p.Subcategory,
    p.Brand,

    oi.Quantity AS PurchasedQuantity,
    r.ReturnQuantity,
    r.ReturnReason,
    r.ReturnStatus,
    r.RefundAmount,

    CAST
    (
        r.ReturnQuantity * 100.0
        / NULLIF(oi.Quantity, 0)
        AS DECIMAL(8,2)
    ) AS ReturnedQuantityPercentage

FROM dbo.Returns AS r

INNER JOIN dbo.OrderItems AS oi
    ON r.OrderItemID = oi.OrderItemID

INNER JOIN dbo.Orders AS o
    ON oi.OrderID = o.OrderID

INNER JOIN dbo.Customers AS c
    ON o.CustomerID = c.CustomerID

INNER JOIN dbo.Products AS p
    ON oi.ProductID = p.ProductID;
GO

/* =========================================================
   4. Marketing campaign view
   ========================================================= */

CREATE OR ALTER VIEW dbo.vw_PowerBI_MarketingCampaigns
AS
SELECT
    mc.CampaignID,
    mc.CampaignName,
    mc.CampaignType,
    mc.TargetSegment,
    mc.StartDate,
    mc.EndDate,
    mc.Budget,
    mc.CampaignStatus,

    ccr.ResponseID,
    ccr.CustomerID,
    c.CustomerName,
    c.CustomerSegment,
    ccr.ResponseDate,
    ccr.ResponseType,
    ccr.ConvertedFlag,
    ccr.RevenueGenerated,

    CASE
        WHEN mc.TargetSegment = 'All Customers'
            THEN 'All Customers Campaign'

        WHEN mc.TargetSegment = c.CustomerSegment
            THEN 'Target Segment Match'

        ELSE 'Target Segment Mismatch'
    END AS SegmentAlignment

FROM dbo.MarketingCampaigns AS mc

LEFT JOIN dbo.CustomerCampaignResponses AS ccr
    ON mc.CampaignID = ccr.CampaignID

LEFT JOIN dbo.Customers AS c
    ON ccr.CustomerID = c.CustomerID;
GO

/* =========================================================
   5. Customer summary view
   ========================================================= */

CREATE OR ALTER VIEW dbo.vw_PowerBI_Customers
AS
SELECT
    c.CustomerID,
    c.CustomerName,
    c.CustomerSegment,
    c.Industry,
    c.Region,
    c.City,
    c.SignupDate,
    c.AcquisitionChannel,
    c.AccountStatus,
    c.CreditLimit,

    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    MIN(o.OrderDate) AS FirstOrderDate,
    MAX(o.OrderDate) AS LastOrderDate,

    SUM
    (
        CASE
            WHEN o.OrderStatus <> 'Cancelled'
                THEN oi.Quantity * oi.UnitSellingPrice
            ELSE 0
        END
    ) AS GrossRevenue,

    SUM
    (
        CASE
            WHEN o.OrderStatus <> 'Cancelled'
                THEN oi.Quantity
                     * (oi.UnitSellingPrice - oi.UnitCost)
            ELSE 0
        END
    ) AS GrossProfit

FROM dbo.Customers AS c

LEFT JOIN dbo.Orders AS o
    ON c.CustomerID = o.CustomerID

LEFT JOIN dbo.OrderItems AS oi
    ON o.OrderID = oi.OrderID

GROUP BY
    c.CustomerID,
    c.CustomerName,
    c.CustomerSegment,
    c.Industry,
    c.Region,
    c.City,
    c.SignupDate,
    c.AcquisitionChannel,
    c.AccountStatus,
    c.CreditLimit;
GO

/* =========================================================
   Validation
   ========================================================= */

SELECT
    'vw_PowerBI_Sales' AS ViewName,
    COUNT_BIG(*) AS RecordCount
FROM dbo.vw_PowerBI_Sales

UNION ALL

SELECT
    'vw_PowerBI_SalesTargets',
    COUNT_BIG(*)
FROM dbo.vw_PowerBI_SalesTargets

UNION ALL

SELECT
    'vw_PowerBI_Returns',
    COUNT_BIG(*)
FROM dbo.vw_PowerBI_Returns

UNION ALL

SELECT
    'vw_PowerBI_MarketingCampaigns',
    COUNT_BIG(*)
FROM dbo.vw_PowerBI_MarketingCampaigns

UNION ALL

SELECT
    'vw_PowerBI_Customers',
    COUNT_BIG(*)
FROM dbo.vw_PowerBI_Customers;
GO