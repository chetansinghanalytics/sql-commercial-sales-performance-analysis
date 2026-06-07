/*
Project: Commercial Sales Performance Analysis
File: 06_generate_orders.sql
Author: Chetan Singh

Purpose:
Generate 300,000 synthetic orders across three years, linking customers
to sales representatives within the same region and creating realistic
patterns by customer segment, channel, payment method and order status.

Orders are distributed across all ten representatives in each region
within every month, preventing unrealistic zero-activity periods.
*/

USE CommercialSalesAnalysis;
GO

SET NOCOUNT ON;
GO

IF EXISTS
(
    SELECT 1
    FROM dbo.Orders
)
BEGIN
    PRINT 'Orders table already contains data. No records were inserted.';
    SET NOEXEC ON;
END;
GO

;WITH Numbers AS
(
    SELECT TOP (300000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects AS a
    CROSS JOIN sys.all_objects AS b
),
OrderBase AS
(
    SELECT
        n,

        ((n * 7919 - 1) % 20000) + 1 AS CustomerID,

        DATEADD(
            DAY,
            (n * 37) % 1096,
            CAST('2023-01-01' AS DATE)
        ) AS GeneratedOrderDate

    FROM Numbers
),
CustomerOrders AS
(
    SELECT
        ob.n,
        c.CustomerID,
        c.CustomerSegment,
        c.Region,
        c.SignupDate,

        CASE
            WHEN c.SignupDate > ob.GeneratedOrderDate
                THEN c.SignupDate
            ELSE ob.GeneratedOrderDate
        END AS OrderDate,

        ROW_NUMBER() OVER
        (
            PARTITION BY
                c.Region,
                YEAR
                (
                    CASE
                        WHEN c.SignupDate > ob.GeneratedOrderDate
                            THEN c.SignupDate
                        ELSE ob.GeneratedOrderDate
                    END
                ),
                MONTH
                (
                    CASE
                        WHEN c.SignupDate > ob.GeneratedOrderDate
                            THEN c.SignupDate
                        ELSE ob.GeneratedOrderDate
                    END
                )

            ORDER BY ob.n
        ) AS OrderSequenceWithinRegionMonth

    FROM OrderBase AS ob

    INNER JOIN dbo.Customers AS c
        ON ob.CustomerID = c.CustomerID
),
Representatives AS
(
    SELECT
        SalesRepID,
        Region,

        ROW_NUMBER() OVER
        (
            PARTITION BY Region
            ORDER BY SalesRepID
        ) AS RepPosition

    FROM dbo.SalesRepresentatives
),
FinalOrderBase AS
(
    SELECT
        co.n,
        co.OrderDate,
        co.CustomerID,
        r.SalesRepID,
        co.CustomerSegment,
        co.Region

    FROM CustomerOrders AS co

    INNER JOIN Representatives AS r
        ON co.Region = r.Region
       AND r.RepPosition =
            (
                (co.OrderSequenceWithinRegionMonth - 1) % 10
            ) + 1
)
INSERT INTO dbo.Orders
(
    OrderDate,
    CustomerID,
    SalesRepID,
    Region,
    SalesChannel,
    PaymentMethod,
    OrderStatus,
    ShippingCost,
    DeliveryDays
)
SELECT
    OrderDate,
    CustomerID,
    SalesRepID,
    Region,

    CASE CustomerSegment
        WHEN 'Enterprise' THEN
            CASE n % 10
                WHEN 0 THEN 'Online'
                WHEN 1 THEN 'Marketplace'
                WHEN 2 THEN 'Partner'
                WHEN 3 THEN 'Partner'
                WHEN 4 THEN 'Wholesale'
                WHEN 5 THEN 'Wholesale'
                ELSE 'Direct Sales'
            END

        WHEN 'Mid-Market' THEN
            CASE n % 10
                WHEN 0 THEN 'Marketplace'
                WHEN 1 THEN 'Partner'
                WHEN 2 THEN 'Partner'
                WHEN 3 THEN 'Wholesale'
                WHEN 4 THEN 'Wholesale'
                WHEN 5 THEN 'Online'
                WHEN 6 THEN 'Online'
                ELSE 'Direct Sales'
            END

        ELSE
            CASE n % 10
                WHEN 0 THEN 'Direct Sales'
                WHEN 1 THEN 'Wholesale'
                WHEN 2 THEN 'Partner'
                WHEN 3 THEN 'Marketplace'
                WHEN 4 THEN 'Marketplace'
                ELSE 'Online'
            END
    END AS SalesChannel,

    CASE CustomerSegment
        WHEN 'Enterprise' THEN
            CASE n % 10
                WHEN 0 THEN 'Credit Card'
                WHEN 1 THEN 'Direct Debit'
                WHEN 2 THEN 'Bank Transfer'
                WHEN 3 THEN 'Bank Transfer'
                ELSE 'Invoice'
            END

        WHEN 'Mid-Market' THEN
            CASE n % 10
                WHEN 0 THEN 'Debit Card'
                WHEN 1 THEN 'Credit Card'
                WHEN 2 THEN 'Direct Debit'
                WHEN 3 THEN 'Direct Debit'
                WHEN 4 THEN 'Bank Transfer'
                WHEN 5 THEN 'Bank Transfer'
                ELSE 'Invoice'
            END

        ELSE
            CASE n % 10
                WHEN 0 THEN 'Invoice'
                WHEN 1 THEN 'Bank Transfer'
                WHEN 2 THEN 'Direct Debit'
                WHEN 3 THEN 'Debit Card'
                WHEN 4 THEN 'Debit Card'
                ELSE 'Credit Card'
            END
    END AS PaymentMethod,

    CASE
        WHEN OrderDate >= '2025-12-01'
             AND n % 100 < 3
            THEN 'Pending'

        WHEN n % 100 BETWEEN 3 AND 6
            THEN 'Cancelled'

        WHEN n % 100 BETWEEN 7 AND 11
            THEN 'Returned'

        ELSE 'Completed'
    END AS OrderStatus,

    CAST(
        CASE
            WHEN n % 100 BETWEEN 3 AND 6
                THEN 0.00

            WHEN CustomerSegment = 'Enterprise'
                THEN
                    25
                    + ((n * 13) % 75)
                    + ((n % 100) / 100.0)

            WHEN CustomerSegment = 'Mid-Market'
                THEN
                    12
                    + ((n * 11) % 45)
                    + ((n % 100) / 100.0)

            ELSE
                    4
                    + ((n * 7) % 22)
                    + ((n % 100) / 100.0)
        END
        AS DECIMAL(10,2)
    ) AS ShippingCost,

    CASE
        WHEN OrderDate >= '2025-12-01'
             AND n % 100 < 3
            THEN NULL

        WHEN n % 100 BETWEEN 3 AND 6
            THEN NULL

        ELSE
            CASE
                WHEN Region IN
                (
                    'Northern Ireland',
                    'Scotland',
                    'North East'
                )
                    THEN 4 + ((n * 5) % 8)

                WHEN Region IN
                (
                    'London',
                    'South East'
                )
                    THEN 1 + ((n * 3) % 5)

                ELSE 2 + ((n * 7) % 7)
            END
    END AS DeliveryDays

FROM FinalOrderBase;
GO

SET NOCOUNT OFF;
GO

/* =========================================================
   Validation checks
   ========================================================= */

SELECT
    COUNT(*) AS OrderCount,
    MIN(OrderDate) AS FirstOrderDate,
    MAX(OrderDate) AS LastOrderDate
FROM dbo.Orders;
GO

SELECT
    OrderStatus,
    COUNT(*) AS OrderCount,

    CAST(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER ()
        AS DECIMAL(5,2)
    ) AS PercentageOfOrders

FROM dbo.Orders
GROUP BY OrderStatus
ORDER BY OrderCount DESC;
GO

SELECT
    COUNT(*) AS SalesRepRegionMismatchCount

FROM dbo.Orders AS o

INNER JOIN dbo.SalesRepresentatives AS sr
    ON o.SalesRepID = sr.SalesRepID

WHERE o.Region <> sr.Region;
GO

SELECT
    MIN(ActiveSalesMonths) AS MinimumActiveMonths,
    CAST(
        AVG(ActiveSalesMonths * 1.0)
        AS DECIMAL(10,2)
    ) AS AverageActiveMonths,
    MAX(ActiveSalesMonths) AS MaximumActiveMonths

FROM
(
    SELECT
        sr.SalesRepID,

        COUNT
        (
            DISTINCT DATEFROMPARTS
            (
                YEAR(o.OrderDate),
                MONTH(o.OrderDate),
                1
            )
        ) AS ActiveSalesMonths

    FROM dbo.SalesRepresentatives AS sr

    LEFT JOIN dbo.Orders AS o
        ON sr.SalesRepID = o.SalesRepID
       AND o.OrderStatus <> 'Cancelled'

    GROUP BY sr.SalesRepID
) AS RepresentativeActivity;
GO

SET NOEXEC OFF;
GO
