/*
Project: Commercial Sales Performance Analysis
File: 05_product_profitability.sql
Author: Chetan Singh

Purpose:
Analyse product, category and brand performance, including revenue,
gross profit, margin, discounting, product rankings and low-margin risks.
*/

USE CommercialSalesAnalysis;
GO

/* =========================================================
   1. Product-level profitability
   ========================================================= */

;WITH ProductPerformance AS
(
    SELECT
        p.ProductID,
        p.ProductName,
        p.Category,
        p.Subcategory,
        p.Brand,
        p.DiscontinuedFlag,

        COUNT(DISTINCT o.OrderID) AS OrdersContainingProduct,
        SUM(oi.Quantity) AS UnitsSold,

        SUM(
            oi.Quantity * oi.UnitSellingPrice
        ) AS GrossRevenue,

        SUM(
            oi.Quantity * oi.UnitCost
        ) AS TotalCost,

        SUM(
            oi.Quantity
            * (oi.UnitSellingPrice - oi.UnitCost)
        ) AS GrossProfit,

        AVG(
            oi.DiscountPercentage
        ) AS AverageDiscountPercentage

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
        p.Subcategory,
        p.Brand,
        p.DiscontinuedFlag
)
SELECT
    ProductID,
    ProductName,
    Category,
    Subcategory,
    Brand,
    DiscontinuedFlag,
    OrdersContainingProduct,
    UnitsSold,

    CAST(
        GrossRevenue
        AS DECIMAL(18,2)
    ) AS GrossRevenue,

    CAST(
        TotalCost
        AS DECIMAL(18,2)
    ) AS TotalCost,

    CAST(
        GrossProfit
        AS DECIMAL(18,2)
    ) AS GrossProfit,

    CAST(
        GrossProfit * 100.0
        / NULLIF(GrossRevenue, 0)
        AS DECIMAL(8,2)
    ) AS GrossMarginPercentage,

    CAST(
        AverageDiscountPercentage
        AS DECIMAL(8,2)
    ) AS AverageDiscountPercentage

FROM ProductPerformance

ORDER BY GrossRevenue DESC;
GO

/* =========================================================
   2. Category performance
   ========================================================= */

SELECT
    p.Category,

    COUNT(DISTINCT p.ProductID) AS ProductsSold,
    COUNT(DISTINCT o.OrderID) AS OrdersContainingCategory,
    SUM(oi.Quantity) AS UnitsSold,

    CAST(
        SUM(oi.Quantity * oi.UnitSellingPrice)
        AS DECIMAL(18,2)
    ) AS GrossRevenue,

    CAST(
        SUM(oi.Quantity * oi.UnitCost)
        AS DECIMAL(18,2)
    ) AS TotalCost,

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
        )
        * 100.0
        /
        NULLIF(
            SUM(oi.Quantity * oi.UnitSellingPrice),
            0
        )
        AS DECIMAL(8,2)
    ) AS GrossMarginPercentage,

    CAST(
        AVG(oi.DiscountPercentage)
        AS DECIMAL(8,2)
    ) AS AverageDiscountPercentage

FROM dbo.Products AS p

INNER JOIN dbo.OrderItems AS oi
    ON p.ProductID = oi.ProductID

INNER JOIN dbo.Orders AS o
    ON oi.OrderID = o.OrderID

WHERE o.OrderStatus <> 'Cancelled'

GROUP BY p.Category

ORDER BY GrossRevenue DESC;
GO

/* =========================================================
   3. Brand performance
   ========================================================= */

SELECT
    p.Brand,

    COUNT(DISTINCT p.ProductID) AS ProductsSold,
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
        )
        * 100.0
        /
        NULLIF(
            SUM(oi.Quantity * oi.UnitSellingPrice),
            0
        )
        AS DECIMAL(8,2)
    ) AS GrossMarginPercentage

FROM dbo.Products AS p

INNER JOIN dbo.OrderItems AS oi
    ON p.ProductID = oi.ProductID

INNER JOIN dbo.Orders AS o
    ON oi.OrderID = o.OrderID

WHERE o.OrderStatus <> 'Cancelled'

GROUP BY p.Brand

ORDER BY GrossRevenue DESC;
GO

/* =========================================================
   4. Top 10 products by revenue within each category
   ========================================================= */

;WITH ProductRevenue AS
(
    SELECT
        p.Category,
        p.ProductID,
        p.ProductName,
        p.Brand,

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
        p.Category,
        p.ProductID,
        p.ProductName,
        p.Brand
),
RankedProducts AS
(
    SELECT
        Category,
        ProductID,
        ProductName,
        Brand,
        GrossRevenue,
        GrossProfit,

        DENSE_RANK() OVER
        (
            PARTITION BY Category
            ORDER BY GrossRevenue DESC
        ) AS RevenueRankWithinCategory

    FROM ProductRevenue
)
SELECT
    Category,
    RevenueRankWithinCategory,
    ProductID,
    ProductName,
    Brand,

    CAST(
        GrossRevenue
        AS DECIMAL(18,2)
    ) AS GrossRevenue,

    CAST(
        GrossProfit
        AS DECIMAL(18,2)
    ) AS GrossProfit

FROM RankedProducts

WHERE RevenueRankWithinCategory <= 10

ORDER BY
    Category,
    RevenueRankWithinCategory;
GO

/* =========================================================
   5. Low-margin high-revenue products
   ========================================================= */

;WITH ProductPerformance AS
(
    SELECT
        p.ProductID,
        p.ProductName,
        p.Category,
        p.Brand,

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
        p.Category,
        p.Brand
),
ProductMetrics AS
(
    SELECT
        ProductID,
        ProductName,
        Category,
        Brand,
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
SELECT
    ProductID,
    ProductName,
    Category,
    Brand,

    CAST(
        GrossRevenue
        AS DECIMAL(18,2)
    ) AS GrossRevenue,

    CAST(
        GrossProfit
        AS DECIMAL(18,2)
    ) AS GrossProfit,

    CAST(
        GrossMarginPercentage
        AS DECIMAL(8,2)
    ) AS GrossMarginPercentage

FROM ProductMetrics

WHERE RevenuePercentile >= 0.75
  AND GrossMarginPercentage < 25

ORDER BY GrossRevenue DESC;
GO

/* =========================================================
   6. Discount impact on profitability
   ========================================================= */

SELECT
    CASE
        WHEN oi.DiscountPercentage = 0
            THEN 'No Discount'

        WHEN oi.DiscountPercentage <= 5
            THEN '0.01% - 5%'

        WHEN oi.DiscountPercentage <= 10
            THEN '5.01% - 10%'

        WHEN oi.DiscountPercentage <= 15
            THEN '10.01% - 15%'

        WHEN oi.DiscountPercentage <= 20
            THEN '15.01% - 20%'

        ELSE 'Above 20%'
    END AS DiscountBand,

    COUNT(*) AS OrderItemCount,
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
        )
        * 100.0
        /
        NULLIF(
            SUM(oi.Quantity * oi.UnitSellingPrice),
            0
        )
        AS DECIMAL(8,2)
    ) AS GrossMarginPercentage

FROM dbo.OrderItems AS oi

INNER JOIN dbo.Orders AS o
    ON oi.OrderID = o.OrderID

WHERE o.OrderStatus <> 'Cancelled'

GROUP BY
    CASE
        WHEN oi.DiscountPercentage = 0
            THEN 'No Discount'

        WHEN oi.DiscountPercentage <= 5
            THEN '0.01% - 5%'

        WHEN oi.DiscountPercentage <= 10
            THEN '5.01% - 10%'

        WHEN oi.DiscountPercentage <= 15
            THEN '10.01% - 15%'

        WHEN oi.DiscountPercentage <= 20
            THEN '15.01% - 20%'

        ELSE 'Above 20%'
    END

ORDER BY MIN(oi.DiscountPercentage);
GO

/* =========================================================
   7. Discontinued product performance
   ========================================================= */

SELECT
    CASE
        WHEN p.DiscontinuedFlag = 1
            THEN 'Discontinued'
        ELSE 'Active Product'
    END AS ProductStatus,

    COUNT(DISTINCT p.ProductID) AS ProductCount,
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
    ) AS GrossProfit

FROM dbo.Products AS p

INNER JOIN dbo.OrderItems AS oi
    ON p.ProductID = oi.ProductID

INNER JOIN dbo.Orders AS o
    ON oi.OrderID = o.OrderID

WHERE o.OrderStatus <> 'Cancelled'

GROUP BY
    CASE
        WHEN p.DiscontinuedFlag = 1
            THEN 'Discontinued'
        ELSE 'Active Product'
    END

ORDER BY GrossRevenue DESC;
GO