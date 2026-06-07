USE CommercialSalesAnalysis;
GO

/* 1. Final row counts */
SELECT 'Customers' AS TableName, COUNT_BIG(*) AS RecordCount
FROM dbo.Customers

UNION ALL
SELECT 'Products', COUNT_BIG(*) FROM dbo.Products

UNION ALL
SELECT 'SalesRepresentatives', COUNT_BIG(*) FROM dbo.SalesRepresentatives

UNION ALL
SELECT 'SalesTargets', COUNT_BIG(*) FROM dbo.SalesTargets

UNION ALL
SELECT 'Orders', COUNT_BIG(*) FROM dbo.Orders

UNION ALL
SELECT 'OrderItems', COUNT_BIG(*) FROM dbo.OrderItems

UNION ALL
SELECT 'Returns', COUNT_BIG(*) FROM dbo.Returns

UNION ALL
SELECT 'MarketingCampaigns', COUNT_BIG(*) FROM dbo.MarketingCampaigns

UNION ALL
SELECT 'CustomerCampaignResponses', COUNT_BIG(*)
FROM dbo.CustomerCampaignResponses;
GO

/* 2. Orders before customer signup */
SELECT COUNT(*) AS OrdersBeforeSignup
FROM dbo.Orders AS o
INNER JOIN dbo.Customers AS c
    ON o.CustomerID = c.CustomerID
WHERE o.OrderDate < c.SignupDate;
GO

/* 3. Orders assigned to sales representatives in another region */
SELECT COUNT(*) AS SalesRepRegionMismatches
FROM dbo.Orders AS o
INNER JOIN dbo.SalesRepresentatives AS sr
    ON o.SalesRepID = sr.SalesRepID
WHERE o.Region <> sr.Region;
GO

/* 4. Orders without order items */
SELECT COUNT(*) AS OrdersWithoutItems
FROM dbo.Orders AS o
LEFT JOIN dbo.OrderItems AS oi
    ON o.OrderID = oi.OrderID
WHERE oi.OrderID IS NULL;
GO

/* 5. Invalid prices, quantities or discounts */
SELECT COUNT(*) AS InvalidOrderItemRecords
FROM dbo.OrderItems
WHERE Quantity <= 0
   OR UnitSellingPrice <= 0
   OR UnitCost <= 0
   OR DiscountPercentage < 0
   OR DiscountPercentage > 60;
GO

/* 6. Invalid return quantities */
SELECT COUNT(*) AS InvalidReturnQuantities
FROM dbo.Returns AS r
INNER JOIN dbo.OrderItems AS oi
    ON r.OrderItemID = oi.OrderItemID
WHERE r.ReturnQuantity > oi.Quantity
   OR r.ReturnQuantity <= 0;
GO

/* 7. Returns dated before their orders */
SELECT COUNT(*) AS InvalidReturnDates
FROM dbo.Returns AS r
INNER JOIN dbo.OrderItems AS oi
    ON r.OrderItemID = oi.OrderItemID
INNER JOIN dbo.Orders AS o
    ON oi.OrderID = o.OrderID
WHERE r.ReturnDate < o.OrderDate;
GO

/* 8. Invalid campaign response dates */
SELECT COUNT(*) AS InvalidCampaignResponseDates
FROM dbo.CustomerCampaignResponses AS ccr
INNER JOIN dbo.MarketingCampaigns AS mc
    ON ccr.CampaignID = mc.CampaignID
WHERE ccr.ResponseDate < mc.StartDate
   OR ccr.ResponseDate > mc.EndDate;
GO

/* 9. Invalid conversion and revenue combinations */
SELECT COUNT(*) AS InvalidConversionRevenueRecords
FROM dbo.CustomerCampaignResponses
WHERE
    (ConvertedFlag = 0 AND RevenueGenerated IS NOT NULL)
    OR
    (ConvertedFlag = 1 AND RevenueGenerated IS NULL);
GO

/* 10. Duplicate monthly sales targets */
SELECT
    SalesRepID,
    TargetMonth,
    COUNT(*) AS DuplicateCount
FROM dbo.SalesTargets
GROUP BY
    SalesRepID,
    TargetMonth
HAVING COUNT(*) > 1;
GO