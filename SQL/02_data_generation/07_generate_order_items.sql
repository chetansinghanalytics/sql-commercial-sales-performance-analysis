/*
Project: Commercial Sales Performance Analysis
File: 07_generate_order_items.sql
Author: Chetan Singh

Purpose:
Generate product-level order-item records for all orders, including
quantities, historical unit costs, selling prices and discounts.
*/

USE CommercialSalesAnalysis;
GO

SET NOCOUNT ON;
GO

IF EXISTS (SELECT 1 FROM dbo.OrderItems)
BEGIN
    PRINT 'OrderItems already contains data. No records were inserted.';
    RETURN;
END;
GO

;WITH ItemNumbers AS
(
    SELECT ItemNumber
    FROM
    (
        VALUES
            (1),
            (2),
            (3),
            (4),
            (5)
    ) AS x(ItemNumber)
),
OrderLinePlan AS
(
    SELECT
        o.OrderID,
        o.CustomerID,
        o.SalesChannel,
        c.CustomerSegment,
        i.ItemNumber,

        CASE c.CustomerSegment
            WHEN 'Small Business'
                THEN 2 + CAST(o.OrderID % 2 AS INT)

            WHEN 'Mid-Market'
                THEN 3 + CAST(o.OrderID % 2 AS INT)

            WHEN 'Enterprise'
                THEN 4 + CAST(o.OrderID % 2 AS INT)
        END AS PlannedItemCount,

        CAST(
            (
                (
                    o.OrderID * 37
                    + i.ItemNumber * 101
                    + o.CustomerID * 13
                    - 1
                ) % 500
            ) + 1
            AS INT
        ) AS ProductID

    FROM dbo.Orders AS o

    INNER JOIN dbo.Customers AS c
        ON o.CustomerID = c.CustomerID

    CROSS JOIN ItemNumbers AS i
),
ValidOrderLines AS
(
    SELECT
        OrderID,
        CustomerID,
        SalesChannel,
        CustomerSegment,
        ItemNumber,
        ProductID

    FROM OrderLinePlan

    WHERE ItemNumber <= PlannedItemCount
),
OrderLineDetails AS
(
    SELECT
        vol.OrderID,
        vol.ProductID,
        vol.CustomerSegment,
        vol.SalesChannel,
        vol.ItemNumber,
        p.Category,
        p.UnitCost,
        p.ListPrice,

        CASE vol.CustomerSegment
            WHEN 'Enterprise' THEN
                12
                + CAST(
                    (
                        vol.OrderID
                        + vol.ItemNumber * 7
                    ) % 14
                    AS DECIMAL(5,2)
                )

            WHEN 'Mid-Market' THEN
                7
                + CAST(
                    (
                        vol.OrderID
                        + vol.ItemNumber * 5
                    ) % 12
                    AS DECIMAL(5,2)
                )

            WHEN 'Small Business' THEN
                CAST(
                    (
                        vol.OrderID
                        + vol.ItemNumber * 3
                    ) % 13
                    AS DECIMAL(5,2)
                )
        END
        +
        CASE
            WHEN vol.SalesChannel IN
            (
                'Online',
                'Marketplace'
            )
                THEN 2
            ELSE 0
        END AS DiscountPercentage,

        CASE vol.CustomerSegment
            WHEN 'Enterprise' THEN
                5
                + CAST(
                    (
                        vol.OrderID
                        + vol.ItemNumber * 11
                    ) % 46
                    AS INT
                )

            WHEN 'Mid-Market' THEN
                2
                + CAST(
                    (
                        vol.OrderID
                        + vol.ItemNumber * 7
                    ) % 19
                    AS INT
                )

            WHEN 'Small Business' THEN
                1
                + CAST(
                    (
                        vol.OrderID
                        + vol.ItemNumber * 5
                    ) % 8
                    AS INT
                )
        END AS BaseQuantity

    FROM ValidOrderLines AS vol

    INNER JOIN dbo.Products AS p
        ON vol.ProductID = p.ProductID
)
INSERT INTO dbo.OrderItems
(
    OrderID,
    ProductID,
    Quantity,
    UnitSellingPrice,
    DiscountPercentage,
    UnitCost
)
SELECT
    OrderID,
    ProductID,

    BaseQuantity
    +
    CASE
        WHEN Category IN
        (
            'Office Supplies',
            'Food and Beverages',
            'Packaging'
        )
            THEN 3
        ELSE 0
    END AS Quantity,

    CAST(
        ListPrice
        *
        (
            1 - DiscountPercentage / 100.0
        )
        AS DECIMAL(10,2)
    ) AS UnitSellingPrice,

    DiscountPercentage,
    UnitCost

FROM OrderLineDetails;
GO

SET NOCOUNT OFF;
GO

SELECT
    COUNT(*) AS OrderItemCount
FROM dbo.OrderItems;
GO

SELECT
    COUNT(*) AS OrderItemCount,
    COUNT(DISTINCT OrderID) AS OrdersWithItems,

    CAST(
        COUNT(*) * 1.0
        / COUNT(DISTINCT OrderID)
        AS DECIMAL(10,2)
    ) AS AverageItemsPerOrder

FROM dbo.OrderItems;
GO

SELECT
    MIN(DiscountPercentage) AS MinimumDiscount,
    MAX(DiscountPercentage) AS MaximumDiscount,

    CAST(
        AVG(DiscountPercentage)
        AS DECIMAL(10,2)
    ) AS AverageDiscount,

    MIN(UnitSellingPrice) AS MinimumSellingPrice,
    MAX(UnitSellingPrice) AS MaximumSellingPrice

FROM dbo.OrderItems;
GO

SELECT
    c.CustomerSegment,
    COUNT(*) AS OrderItemCount,

    CAST(
        AVG(oi.Quantity * 1.0)
        AS DECIMAL(10,2)
    ) AS AverageQuantity,

    CAST(
        AVG(oi.DiscountPercentage)
        AS DECIMAL(10,2)
    ) AS AverageDiscount

FROM dbo.OrderItems AS oi

INNER JOIN dbo.Orders AS o
    ON oi.OrderID = o.OrderID

INNER JOIN dbo.Customers AS c
    ON o.CustomerID = c.CustomerID

GROUP BY c.CustomerSegment
ORDER BY c.CustomerSegment;
GO

SELECT
    COUNT(*) AS OrdersWithoutItems

FROM dbo.Orders AS o

LEFT JOIN dbo.OrderItems AS oi
    ON o.OrderID = oi.OrderID

WHERE oi.OrderID IS NULL;
GO