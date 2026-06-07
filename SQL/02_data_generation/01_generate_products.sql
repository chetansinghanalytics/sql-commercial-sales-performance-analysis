/*
Project: Commercial Sales Performance Analysis
File: 01_generate_products.sql
Author: Chetan Singh

Purpose:
Generate 500 synthetic products across eight commercial categories,
with structured subcategories, brands, costs, prices and launch dates.
*/

USE CommercialSalesAnalysis;
GO

IF EXISTS (SELECT 1 FROM dbo.Products)
BEGIN
    PRINT 'Products table already contains data. No records were inserted.';
    RETURN;
END;
GO

;WITH Numbers AS
(
    SELECT TOP (500)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects AS a
    CROSS JOIN sys.all_objects AS b
),
ProductBase AS
(
    SELECT
        n,
        ((n - 1) % 8) + 1 AS CategoryCode,
        ((n - 1) % 10) + 1 AS BrandCode,
        ((n - 1) % 5) + 1 AS SubcategoryCode
    FROM Numbers
)
INSERT INTO dbo.Products
(
    ProductName,
    Category,
    Subcategory,
    Brand,
    UnitCost,
    ListPrice,
    LaunchDate,
    DiscontinuedFlag
)
SELECT
    CONCAT(
        CASE CategoryCode
            WHEN 1 THEN 'TechPro'
            WHEN 2 THEN 'OfficeCore'
            WHEN 3 THEN 'Workspace'
            WHEN 4 THEN 'CleanGuard'
            WHEN 5 THEN 'FreshChoice'
            WHEN 6 THEN 'PackRight'
            WHEN 7 THEN 'SafeLine'
            WHEN 8 THEN 'VoltEdge'
        END,
        ' ',
        RIGHT('0000' + CAST(n AS VARCHAR(4)), 4)
    ) AS ProductName,

    CASE CategoryCode
        WHEN 1 THEN 'Technology'
        WHEN 2 THEN 'Office Supplies'
        WHEN 3 THEN 'Furniture'
        WHEN 4 THEN 'Cleaning and Hygiene'
        WHEN 5 THEN 'Food and Beverages'
        WHEN 6 THEN 'Packaging'
        WHEN 7 THEN 'Safety Equipment'
        WHEN 8 THEN 'Electrical Supplies'
    END AS Category,

    CASE CategoryCode
        WHEN 1 THEN
            CASE SubcategoryCode
                WHEN 1 THEN 'Laptops'
                WHEN 2 THEN 'Monitors'
                WHEN 3 THEN 'Keyboards'
                WHEN 4 THEN 'Headsets'
                WHEN 5 THEN 'Accessories'
            END

        WHEN 2 THEN
            CASE SubcategoryCode
                WHEN 1 THEN 'Paper'
                WHEN 2 THEN 'Writing Instruments'
                WHEN 3 THEN 'Filing'
                WHEN 4 THEN 'Desk Accessories'
                WHEN 5 THEN 'Printer Supplies'
            END

        WHEN 3 THEN
            CASE SubcategoryCode
                WHEN 1 THEN 'Desks'
                WHEN 2 THEN 'Chairs'
                WHEN 3 THEN 'Storage'
                WHEN 4 THEN 'Meeting Furniture'
                WHEN 5 THEN 'Reception Furniture'
            END

        WHEN 4 THEN
            CASE SubcategoryCode
                WHEN 1 THEN 'Surface Cleaning'
                WHEN 2 THEN 'Hand Hygiene'
                WHEN 3 THEN 'Washroom Supplies'
                WHEN 4 THEN 'Waste Management'
                WHEN 5 THEN 'Cleaning Equipment'
            END

        WHEN 5 THEN
            CASE SubcategoryCode
                WHEN 1 THEN 'Hot Drinks'
                WHEN 2 THEN 'Cold Drinks'
                WHEN 3 THEN 'Snacks'
                WHEN 4 THEN 'Catering Essentials'
                WHEN 5 THEN 'Healthy Options'
            END

        WHEN 6 THEN
            CASE SubcategoryCode
                WHEN 1 THEN 'Boxes'
                WHEN 2 THEN 'Mailing Supplies'
                WHEN 3 THEN 'Protective Packaging'
                WHEN 4 THEN 'Labels'
                WHEN 5 THEN 'Sustainable Packaging'
            END

        WHEN 7 THEN
            CASE SubcategoryCode
                WHEN 1 THEN 'Protective Clothing'
                WHEN 2 THEN 'Eye Protection'
                WHEN 3 THEN 'First Aid'
                WHEN 4 THEN 'Site Safety'
                WHEN 5 THEN 'Respiratory Protection'
            END

        WHEN 8 THEN
            CASE SubcategoryCode
                WHEN 1 THEN 'Cables'
                WHEN 2 THEN 'Power Supplies'
                WHEN 3 THEN 'Lighting'
                WHEN 4 THEN 'Batteries'
                WHEN 5 THEN 'Electrical Accessories'
            END
    END AS Subcategory,

    CASE BrandCode
        WHEN 1 THEN 'Apex'
        WHEN 2 THEN 'Nova'
        WHEN 3 THEN 'Vertex'
        WHEN 4 THEN 'Sterling'
        WHEN 5 THEN 'PrimeWorks'
        WHEN 6 THEN 'BluePeak'
        WHEN 7 THEN 'MetroLine'
        WHEN 8 THEN 'EcoSphere'
        WHEN 9 THEN 'ProServe'
        WHEN 10 THEN 'Nexa'
    END AS Brand,

    CAST(
        CASE CategoryCode
            WHEN 1 THEN 45 + ((n * 37) % 955)
            WHEN 2 THEN 2 + ((n * 11) % 80)
            WHEN 3 THEN 40 + ((n * 29) % 760)
            WHEN 4 THEN 3 + ((n * 13) % 140)
            WHEN 5 THEN 1 + ((n * 7) % 55)
            WHEN 6 THEN 2 + ((n * 9) % 120)
            WHEN 7 THEN 5 + ((n * 17) % 240)
            WHEN 8 THEN 4 + ((n * 19) % 300)
        END
        + ((n % 100) / 100.0)
        AS DECIMAL(10,2)
    ) AS UnitCost,

    CAST(
        (
            CASE CategoryCode
                WHEN 1 THEN 45 + ((n * 37) % 955)
                WHEN 2 THEN 2 + ((n * 11) % 80)
                WHEN 3 THEN 40 + ((n * 29) % 760)
                WHEN 4 THEN 3 + ((n * 13) % 140)
                WHEN 5 THEN 1 + ((n * 7) % 55)
                WHEN 6 THEN 2 + ((n * 9) % 120)
                WHEN 7 THEN 5 + ((n * 17) % 240)
                WHEN 8 THEN 4 + ((n * 19) % 300)
            END
            + ((n % 100) / 100.0)
        )
        *
        (
            1.25
            + ((n % 21) / 100.0)
        )
        AS DECIMAL(10,2)
    ) AS ListPrice,

    DATEADD(
        DAY,
        -((n * 17) % 1825),
        CAST('2025-12-31' AS DATE)
    ) AS LaunchDate,

    CASE
        WHEN n % 25 = 0 THEN 1
        ELSE 0
    END AS DiscontinuedFlag

FROM ProductBase;
GO

SELECT
    COUNT(*) AS ProductCount
FROM dbo.Products;
GO

SELECT
    Category,
    COUNT(*) AS ProductCount,
    CAST(AVG(UnitCost) AS DECIMAL(10,2)) AS AverageUnitCost,
    CAST(AVG(ListPrice) AS DECIMAL(10,2)) AS AverageListPrice,
    SUM(
        CASE
            WHEN DiscontinuedFlag = 1 THEN 1
            ELSE 0
        END
    ) AS DiscontinuedProducts
FROM dbo.Products
GROUP BY Category
ORDER BY Category;
GO