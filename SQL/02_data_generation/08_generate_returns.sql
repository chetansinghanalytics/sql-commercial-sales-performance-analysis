/*
Project: Commercial Sales Performance Analysis
File: 08_generate_returns.sql
Author: Chetan Singh

Purpose:
Generate realistic return records for orders marked as returned, while
ensuring returned quantities do not exceed purchased quantities and
return dates do not precede order dates.
*/

USE CommercialSalesAnalysis;
GO

SET NOCOUNT ON;
GO

IF EXISTS (SELECT 1 FROM dbo.Returns)
BEGIN
    PRINT 'Returns table already contains data. No records were inserted.';
    RETURN;
END;
GO

;WITH ReturnedOrderItems AS
(
    SELECT
        o.OrderID,
        o.OrderDate,
        oi.OrderItemID,
        oi.ProductID,
        oi.Quantity,
        oi.UnitSellingPrice,
        p.Category,

        ROW_NUMBER() OVER
        (
            PARTITION BY o.OrderID
            ORDER BY oi.OrderItemID
        ) AS ItemPosition

    FROM dbo.Orders AS o

    INNER JOIN dbo.OrderItems AS oi
        ON o.OrderID = oi.OrderID

    INNER JOIN dbo.Products AS p
        ON oi.ProductID = p.ProductID

    WHERE o.OrderStatus = 'Returned'
),
SelectedReturns AS
(
    SELECT
        OrderID,
        OrderDate,
        OrderItemID,
        ProductID,
        Quantity,
        UnitSellingPrice,
        Category,
        ItemPosition,

        CASE
            WHEN OrderID % 2 = 0 THEN 1
            ELSE 2
        END AS PlannedReturnLines

    FROM ReturnedOrderItems
),
ReturnDetails AS
(
    SELECT
        OrderID,
        OrderDate,
        OrderItemID,
        Quantity,
        UnitSellingPrice,
        Category,

        CASE
            WHEN Quantity = 1 THEN 1

            WHEN 1 + ((OrderItemID * 7) % Quantity) > Quantity
                THEN Quantity

            ELSE
                1 + CAST(
                    (OrderItemID * 7) % Quantity
                    AS INT
                )
        END AS ReturnQuantity,

        CASE
            WHEN OrderItemID % 100 < 42 THEN 'Damaged'
            WHEN OrderItemID % 100 < 62 THEN 'Defective'
            WHEN OrderItemID % 100 < 72 THEN 'Wrong Item'
            WHEN OrderItemID % 100 < 82 THEN 'No Longer Required'
            WHEN OrderItemID % 100 < 89 THEN 'Late Delivery'
            WHEN OrderItemID % 100 < 96 THEN 'Poor Quality'
            ELSE 'Other'
        END AS ReturnReason,

        CASE
            WHEN OrderItemID % 100 < 4 THEN 'Rejected'
            WHEN OrderItemID % 100 < 10 THEN 'Requested'
            WHEN OrderItemID % 100 < 20 THEN 'Approved'
            ELSE 'Refunded'
        END AS ReturnStatus

    FROM SelectedReturns

    WHERE ItemPosition <= PlannedReturnLines
),
FinalReturns AS
(
    SELECT
        OrderItemID,
        OrderDate,
        ReturnQuantity,
        UnitSellingPrice,
        ReturnReason,
        ReturnStatus,

        CASE
            WHEN DATEADD(
                DAY,
                3 + CAST(
                    (OrderItemID * 11) % 28
                    AS INT
                ),
                OrderDate
            ) > CAST('2025-12-31' AS DATE)
                THEN CAST('2025-12-31' AS DATE)

            ELSE DATEADD(
                DAY,
                3 + CAST(
                    (OrderItemID * 11) % 28
                    AS INT
                ),
                OrderDate
            )
        END AS ReturnDate

    FROM ReturnDetails
)
INSERT INTO dbo.Returns
(
    OrderItemID,
    ReturnDate,
    ReturnQuantity,
    ReturnReason,
    RefundAmount,
    ReturnStatus
)
SELECT
    OrderItemID,
    ReturnDate,
    ReturnQuantity,
    ReturnReason,

    CASE
        WHEN ReturnStatus IN ('Requested', 'Rejected')
            THEN 0.00

        WHEN ReturnStatus = 'Approved'
            THEN CAST(
                ReturnQuantity
                * UnitSellingPrice
                * 0.95
                AS DECIMAL(12,2)
            )

        WHEN ReturnStatus = 'Refunded'
            THEN CAST(
                ReturnQuantity
                * UnitSellingPrice
                AS DECIMAL(12,2)
            )
    END AS RefundAmount,

    ReturnStatus

FROM FinalReturns;
GO

SET NOCOUNT OFF;
GO

SELECT
    COUNT(*) AS ReturnRecordCount,
    MIN(ReturnDate) AS FirstReturnDate,
    MAX(ReturnDate) AS LastReturnDate
FROM dbo.Returns;
GO

SELECT
    ReturnStatus,
    COUNT(*) AS ReturnCount,

    CAST(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER ()
        AS DECIMAL(5,2)
    ) AS PercentageOfReturns,

    CAST(
        SUM(RefundAmount)
        AS DECIMAL(18,2)
    ) AS TotalRefundAmount

FROM dbo.Returns
GROUP BY ReturnStatus
ORDER BY ReturnCount DESC;
GO

SELECT
    COUNT(*) AS InvalidReturnQuantityCount

FROM dbo.Returns AS r

INNER JOIN dbo.OrderItems AS oi
    ON r.OrderItemID = oi.OrderItemID

WHERE r.ReturnQuantity > oi.Quantity
   OR r.ReturnQuantity <= 0;
GO

SELECT
    COUNT(*) AS InvalidReturnDateCount

FROM dbo.Returns AS r

INNER JOIN dbo.OrderItems AS oi
    ON r.OrderItemID = oi.OrderItemID

INNER JOIN dbo.Orders AS o
    ON oi.OrderID = o.OrderID

WHERE r.ReturnDate < o.OrderDate;
GO

SELECT
    COUNT(*) AS InvalidRejectedRefundCount
FROM dbo.Returns
WHERE ReturnStatus = 'Rejected'
  AND RefundAmount <> 0;
GO