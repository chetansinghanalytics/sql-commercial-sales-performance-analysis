/*
Project: Commercial Sales Performance Analysis
File: 07_returns_analysis.sql
Author: Chetan Singh

Purpose:
Analyse return volumes, refund costs, return reasons, category-level
return patterns, regional differences and products with elevated return risk.
*/

USE CommercialSalesAnalysis;
GO

/* =========================================================
   1. Overall returns summary
   ========================================================= */

SELECT
    COUNT(DISTINCT r.ReturnID) AS ReturnRecords,
    COUNT(DISTINCT oi.OrderID) AS OrdersWithReturns,
    SUM(r.ReturnQuantity) AS UnitsReturned,

    CAST(
        SUM(r.RefundAmount)
        AS DECIMAL(18,2)
    ) AS TotalRefundAmount,

    CAST(
        AVG(r.RefundAmount)
        AS DECIMAL(18,2)
    ) AS AverageRefundAmount,

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
   2. Return status distribution
   ========================================================= */

SELECT
    r.ReturnStatus,

    COUNT(*) AS ReturnCount,
    SUM(r.ReturnQuantity) AS UnitsReturned,

    CAST(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER ()
        AS DECIMAL(8,2)
    ) AS ReturnSharePercentage,

    CAST(
        SUM(r.RefundAmount)
        AS DECIMAL(18,2)
    ) AS TotalRefundAmount

FROM dbo.Returns AS r

GROUP BY r.ReturnStatus

ORDER BY ReturnCount DESC;
GO

/* =========================================================
   3. Return reasons
   ========================================================= */

SELECT
    r.ReturnReason,

    COUNT(*) AS ReturnCount,
    SUM(r.ReturnQuantity) AS UnitsReturned,

    CAST(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER ()
        AS DECIMAL(8,2)
    ) AS ReturnReasonSharePercentage,

    CAST(
        SUM(r.RefundAmount)
        AS DECIMAL(18,2)
    ) AS TotalRefundAmount,

    CAST(
        AVG(r.RefundAmount)
        AS DECIMAL(18,2)
    ) AS AverageRefundAmount

FROM dbo.Returns AS r

GROUP BY r.ReturnReason

ORDER BY ReturnCount DESC;
GO

/* =========================================================
   4. Category-level return performance
   ========================================================= */

;WITH CategorySales AS
(
    SELECT
        p.Category,
        SUM(oi.Quantity) AS UnitsSold,

        SUM(
            oi.Quantity * oi.UnitSellingPrice
        ) AS GrossRevenue

    FROM dbo.OrderItems AS oi

    INNER JOIN dbo.Products AS p
        ON oi.ProductID = p.ProductID

    INNER JOIN dbo.Orders AS o
        ON oi.OrderID = o.OrderID

    WHERE o.OrderStatus <> 'Cancelled'

    GROUP BY p.Category
),
CategoryReturns AS
(
    SELECT
        p.Category,
        COUNT(*) AS ReturnRecords,
        SUM(r.ReturnQuantity) AS UnitsReturned,
        SUM(r.RefundAmount) AS RefundAmount

    FROM dbo.Returns AS r

    INNER JOIN dbo.OrderItems AS oi
        ON r.OrderItemID = oi.OrderItemID

    INNER JOIN dbo.Products AS p
        ON oi.ProductID = p.ProductID

    GROUP BY p.Category
)
SELECT
    cs.Category,
    cs.UnitsSold,
    ISNULL(cr.UnitsReturned, 0) AS UnitsReturned,

    CAST(
        ISNULL(cr.UnitsReturned, 0) * 100.0
        / NULLIF(cs.UnitsSold, 0)
        AS DECIMAL(8,2)
    ) AS UnitReturnRatePercentage,

    CAST(
        cs.GrossRevenue
        AS DECIMAL(18,2)
    ) AS GrossRevenue,

    CAST(
        ISNULL(cr.RefundAmount, 0)
        AS DECIMAL(18,2)
    ) AS RefundAmount,

    CAST(
        ISNULL(cr.RefundAmount, 0) * 100.0
        / NULLIF(cs.GrossRevenue, 0)
        AS DECIMAL(8,2)
    ) AS RefundAsPercentageOfRevenue

FROM CategorySales AS cs

LEFT JOIN CategoryReturns AS cr
    ON cs.Category = cr.Category

ORDER BY UnitReturnRatePercentage DESC;
GO

/* =========================================================
   5. Product-level return risk
   ========================================================= */

;WITH ProductSales AS
(
    SELECT
        p.ProductID,
        p.ProductName,
        p.Category,
        p.Brand,

        SUM(oi.Quantity) AS UnitsSold,

        SUM(
            oi.Quantity * oi.UnitSellingPrice
        ) AS GrossRevenue

    FROM dbo.Products AS p

    INNER JOIN dbo.OrderItems AS oi
        ON p.ProductID = oi.ProductID

    INNER JOIN dbo.Orders AS o
        ON oi.OrderID = o.OrderID

    WHERE o.OrderStatus <> 'Cancelled'

    GROUP BY
        p.ProductID,
        p.ProductName,
        p.Category,
        p.Brand
),
ProductReturns AS
(
    SELECT
        oi.ProductID,
        COUNT(*) AS ReturnRecords,
        SUM(r.ReturnQuantity) AS UnitsReturned,
        SUM(r.RefundAmount) AS RefundAmount

    FROM dbo.Returns AS r

    INNER JOIN dbo.OrderItems AS oi
        ON r.OrderItemID = oi.OrderItemID

    GROUP BY oi.ProductID
)
SELECT TOP (50)
    ps.ProductID,
    ps.ProductName,
    ps.Category,
    ps.Brand,
    ps.UnitsSold,
    ISNULL(pr.UnitsReturned, 0) AS UnitsReturned,

    CAST(
        ISNULL(pr.UnitsReturned, 0) * 100.0
        / NULLIF(ps.UnitsSold, 0)
        AS DECIMAL(8,2)
    ) AS UnitReturnRatePercentage,

    CAST(
        ps.GrossRevenue
        AS DECIMAL(18,2)
    ) AS GrossRevenue,

    CAST(
        ISNULL(pr.RefundAmount, 0)
        AS DECIMAL(18,2)
    ) AS RefundAmount

FROM ProductSales AS ps

LEFT JOIN ProductReturns AS pr
    ON ps.ProductID = pr.ProductID

ORDER BY
    UnitReturnRatePercentage DESC,
    RefundAmount DESC;
GO

/* =========================================================
   6. Regional return performance
   ========================================================= */

;WITH RegionalOrders AS
(
    SELECT
        o.Region,
        COUNT(DISTINCT o.OrderID) AS TotalOrders

    FROM dbo.Orders AS o

    WHERE o.OrderStatus <> 'Cancelled'

    GROUP BY o.Region
),
RegionalReturns AS
(
    SELECT
        o.Region,
        COUNT(DISTINCT oi.OrderID) AS OrdersWithReturns,
        COUNT(*) AS ReturnRecords,
        SUM(r.ReturnQuantity) AS UnitsReturned,
        SUM(r.RefundAmount) AS RefundAmount

    FROM dbo.Returns AS r

    INNER JOIN dbo.OrderItems AS oi
        ON r.OrderItemID = oi.OrderItemID

    INNER JOIN dbo.Orders AS o
        ON oi.OrderID = o.OrderID

    GROUP BY o.Region
)
SELECT
    ro.Region,
    ro.TotalOrders,
    ISNULL(rr.OrdersWithReturns, 0) AS OrdersWithReturns,

    CAST(
        ISNULL(rr.OrdersWithReturns, 0) * 100.0
        / NULLIF(ro.TotalOrders, 0)
        AS DECIMAL(8,2)
    ) AS OrderReturnRatePercentage,

    ISNULL(rr.ReturnRecords, 0) AS ReturnRecords,
    ISNULL(rr.UnitsReturned, 0) AS UnitsReturned,

    CAST(
        ISNULL(rr.RefundAmount, 0)
        AS DECIMAL(18,2)
    ) AS RefundAmount

FROM RegionalOrders AS ro

LEFT JOIN RegionalReturns AS rr
    ON ro.Region = rr.Region

ORDER BY OrderReturnRatePercentage DESC;
GO

/* =========================================================
   7. Monthly return trend
   ========================================================= */

SELECT
    DATEFROMPARTS(
        YEAR(r.ReturnDate),
        MONTH(r.ReturnDate),
        1
    ) AS ReturnMonth,

    COUNT(*) AS ReturnRecords,
    SUM(r.ReturnQuantity) AS UnitsReturned,

    CAST(
        SUM(r.RefundAmount)
        AS DECIMAL(18,2)
    ) AS RefundAmount

FROM dbo.Returns AS r

GROUP BY
    DATEFROMPARTS(
        YEAR(r.ReturnDate),
        MONTH(r.ReturnDate),
        1
    )

ORDER BY ReturnMonth;
GO

/* =========================================================
   8. Return reasons by category
   ========================================================= */

SELECT
    p.Category,
    r.ReturnReason,

    COUNT(*) AS ReturnCount,
    SUM(r.ReturnQuantity) AS UnitsReturned,

    CAST(
        COUNT(*) * 100.0
        /
        SUM(COUNT(*)) OVER
        (
            PARTITION BY p.Category
        )
        AS DECIMAL(8,2)
    ) AS CategoryReturnReasonSharePercentage,

    CAST(
        SUM(r.RefundAmount)
        AS DECIMAL(18,2)
    ) AS RefundAmount

FROM dbo.Returns AS r

INNER JOIN dbo.OrderItems AS oi
    ON r.OrderItemID = oi.OrderItemID

INNER JOIN dbo.Products AS p
    ON oi.ProductID = p.ProductID

GROUP BY
    p.Category,
    r.ReturnReason

ORDER BY
    p.Category,
    ReturnCount DESC;
GO