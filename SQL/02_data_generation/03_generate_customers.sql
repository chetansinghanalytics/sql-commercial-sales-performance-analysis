/*
Project: Commercial Sales Performance Analysis
File: 03_generate_customers.sql
Author: Chetan Singh

Purpose:
Generate 20,000 synthetic customers across UK regions, segments,
industries, acquisition channels and account statuses.
*/

USE CommercialSalesAnalysis;
GO

-- Prevent accidental duplicate insertion
IF EXISTS (SELECT 1 FROM dbo.Customers)
BEGIN
    PRINT 'Customers table already contains data. No records were inserted.';
    RETURN;
END;
GO

;WITH Numbers AS
(
    SELECT TOP (20000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects AS a
    CROSS JOIN sys.all_objects AS b
),
CustomerBase AS
(
    SELECT
        n,

        -- Customer-segment distribution:
        -- 65% Small Business, 27% Mid-Market, 8% Enterprise
        CASE
            WHEN n % 100 < 65 THEN 1
            WHEN n % 100 < 92 THEN 2
            ELSE 3
        END AS SegmentCode,

        -- Weighted regional distribution
        CASE
            WHEN n % 100 < 18 THEN 1
            WHEN n % 100 < 32 THEN 2
            WHEN n % 100 < 40 THEN 3
            WHEN n % 100 < 50 THEN 4
            WHEN n % 100 < 59 THEN 5
            WHEN n % 100 < 66 THEN 6
            WHEN n % 100 < 77 THEN 7
            WHEN n % 100 < 82 THEN 8
            WHEN n % 100 < 90 THEN 9
            WHEN n % 100 < 94 THEN 10
            WHEN n % 100 < 98 THEN 11
            ELSE 12
        END AS RegionCode,

        ((n * 13 - 1) % 12) + 1 AS IndustryCode,

        DATEADD(
            DAY,
            (n * 29) % 2922,
            CAST('2018-01-01' AS DATE)
        ) AS GeneratedSignupDate
    FROM Numbers
),
CustomerDetails AS
(
    SELECT
        n,
        SegmentCode,
        RegionCode,
        IndustryCode,
        GeneratedSignupDate,

        CASE SegmentCode
            WHEN 1 THEN 'Small Business'
            WHEN 2 THEN 'Mid-Market'
            WHEN 3 THEN 'Enterprise'
        END AS CustomerSegment,

        CASE RegionCode
            WHEN 1 THEN 'London'
            WHEN 2 THEN 'South East'
            WHEN 3 THEN 'South West'
            WHEN 4 THEN 'East of England'
            WHEN 5 THEN 'West Midlands'
            WHEN 6 THEN 'East Midlands'
            WHEN 7 THEN 'North West'
            WHEN 8 THEN 'North East'
            WHEN 9 THEN 'Yorkshire and the Humber'
            WHEN 10 THEN 'Wales'
            WHEN 11 THEN 'Scotland'
            WHEN 12 THEN 'Northern Ireland'
        END AS Region,

        CASE IndustryCode
            WHEN 1 THEN 'Retail'
            WHEN 2 THEN 'Hospitality'
            WHEN 3 THEN 'Professional Services'
            WHEN 4 THEN 'Manufacturing'
            WHEN 5 THEN 'Healthcare'
            WHEN 6 THEN 'Education'
            WHEN 7 THEN 'Construction'
            WHEN 8 THEN 'Technology'
            WHEN 9 THEN 'Logistics'
            WHEN 10 THEN 'Financial Services'
            WHEN 11 THEN 'Food and Beverage'
            WHEN 12 THEN 'Public and Non-Profit'
        END AS Industry
    FROM CustomerBase
)
INSERT INTO dbo.Customers
(
    CustomerName,
    CustomerSegment,
    Industry,
    Region,
    City,
    SignupDate,
    AcquisitionChannel,
    AccountStatus,
    CreditLimit
)
SELECT
    CONCAT(
        CASE ((n - 1) % 15) + 1
            WHEN 1 THEN 'Apex'
            WHEN 2 THEN 'Brighton'
            WHEN 3 THEN 'Crown'
            WHEN 4 THEN 'Dynamic'
            WHEN 5 THEN 'Evergreen'
            WHEN 6 THEN 'Frontier'
            WHEN 7 THEN 'Global'
            WHEN 8 THEN 'Horizon'
            WHEN 9 THEN 'Imperial'
            WHEN 10 THEN 'Kingston'
            WHEN 11 THEN 'Meridian'
            WHEN 12 THEN 'Northstar'
            WHEN 13 THEN 'Oakbridge'
            WHEN 14 THEN 'Premier'
            WHEN 15 THEN 'Sterling'
        END,
        ' ',
        CASE IndustryCode
            WHEN 1 THEN 'Retail'
            WHEN 2 THEN 'Hospitality'
            WHEN 3 THEN 'Consulting'
            WHEN 4 THEN 'Manufacturing'
            WHEN 5 THEN 'Healthcare'
            WHEN 6 THEN 'Education'
            WHEN 7 THEN 'Construction'
            WHEN 8 THEN 'Technology'
            WHEN 9 THEN 'Logistics'
            WHEN 10 THEN 'Finance'
            WHEN 11 THEN 'Foods'
            WHEN 12 THEN 'Community'
        END,
        ' ',
        CASE SegmentCode
            WHEN 1 THEN 'Services'
            WHEN 2 THEN 'Group'
            WHEN 3 THEN 'Holdings'
        END,
        ' ',
        RIGHT('00000' + CAST(n AS VARCHAR(5)), 5)
    ) AS CustomerName,

    CustomerSegment,
    Industry,
    Region,

    CASE RegionCode
        WHEN 1 THEN
            CASE n % 4
                WHEN 0 THEN 'London'
                WHEN 1 THEN 'Westminster'
                WHEN 2 THEN 'Croydon'
                WHEN 3 THEN 'Harrow'
            END

        WHEN 2 THEN
            CASE n % 4
                WHEN 0 THEN 'Brighton'
                WHEN 1 THEN 'Reading'
                WHEN 2 THEN 'Guildford'
                WHEN 3 THEN 'Oxford'
            END

        WHEN 3 THEN
            CASE n % 4
                WHEN 0 THEN 'Bristol'
                WHEN 1 THEN 'Exeter'
                WHEN 2 THEN 'Plymouth'
                WHEN 3 THEN 'Bath'
            END

        WHEN 4 THEN
            CASE n % 4
                WHEN 0 THEN 'Cambridge'
                WHEN 1 THEN 'Norwich'
                WHEN 2 THEN 'Ipswich'
                WHEN 3 THEN 'Peterborough'
            END

        WHEN 5 THEN
            CASE n % 4
                WHEN 0 THEN 'Birmingham'
                WHEN 1 THEN 'Coventry'
                WHEN 2 THEN 'Wolverhampton'
                WHEN 3 THEN 'Stoke-on-Trent'
            END

        WHEN 6 THEN
            CASE n % 4
                WHEN 0 THEN 'Nottingham'
                WHEN 1 THEN 'Leicester'
                WHEN 2 THEN 'Derby'
                WHEN 3 THEN 'Lincoln'
            END

        WHEN 7 THEN
            CASE n % 4
                WHEN 0 THEN 'Manchester'
                WHEN 1 THEN 'Liverpool'
                WHEN 2 THEN 'Preston'
                WHEN 3 THEN 'Chester'
            END

        WHEN 8 THEN
            CASE n % 4
                WHEN 0 THEN 'Newcastle'
                WHEN 1 THEN 'Sunderland'
                WHEN 2 THEN 'Durham'
                WHEN 3 THEN 'Middlesbrough'
            END

        WHEN 9 THEN
            CASE n % 4
                WHEN 0 THEN 'Leeds'
                WHEN 1 THEN 'Sheffield'
                WHEN 2 THEN 'York'
                WHEN 3 THEN 'Hull'
            END

        WHEN 10 THEN
            CASE n % 4
                WHEN 0 THEN 'Cardiff'
                WHEN 1 THEN 'Swansea'
                WHEN 2 THEN 'Newport'
                WHEN 3 THEN 'Wrexham'
            END

        WHEN 11 THEN
            CASE n % 4
                WHEN 0 THEN 'Glasgow'
                WHEN 1 THEN 'Edinburgh'
                WHEN 2 THEN 'Aberdeen'
                WHEN 3 THEN 'Dundee'
            END

        WHEN 12 THEN
            CASE n % 4
                WHEN 0 THEN 'Belfast'
                WHEN 1 THEN 'Derry'
                WHEN 2 THEN 'Lisburn'
                WHEN 3 THEN 'Newry'
            END
    END AS City,

    GeneratedSignupDate,

    CASE
        -- Enterprise customers are more likely to come through sales teams
        WHEN SegmentCode = 3 THEN
            CASE n % 10
                WHEN 0 THEN 'Website'
                WHEN 1 THEN 'Referral'
                WHEN 2 THEN 'Trade Show'
                WHEN 3 THEN 'Partner'
                WHEN 4 THEN 'Partner'
                ELSE 'Direct Sales'
            END

        -- Mid-market customers have a more balanced acquisition mix
        WHEN SegmentCode = 2 THEN
            CASE n % 10
                WHEN 0 THEN 'Website'
                WHEN 1 THEN 'Website'
                WHEN 2 THEN 'Referral'
                WHEN 3 THEN 'Referral'
                WHEN 4 THEN 'Partner'
                WHEN 5 THEN 'Trade Show'
                WHEN 6 THEN 'Email Campaign'
                ELSE 'Direct Sales'
            END

        -- Small businesses are more digitally acquired
        ELSE
            CASE n % 10
                WHEN 0 THEN 'Direct Sales'
                WHEN 1 THEN 'Referral'
                WHEN 2 THEN 'Referral'
                WHEN 3 THEN 'Email Campaign'
                WHEN 4 THEN 'Email Campaign'
                WHEN 5 THEN 'Partner'
                ELSE 'Website'
            END
    END AS AcquisitionChannel,

    CASE
        WHEN n % 100 = 0 THEN 'Closed'
        WHEN n % 50 = 0 THEN 'Suspended'
        WHEN n % 20 = 0 THEN 'Inactive'
        ELSE 'Active'
    END AS AccountStatus,

    CASE
        WHEN n % 100 = 0 THEN NULL

        WHEN SegmentCode = 1 THEN
            CAST(
                3000 + ((n * 137) % 17000)
                AS DECIMAL(12,2)
            )

        WHEN SegmentCode = 2 THEN
            CAST(
                20000 + ((n * 419) % 80000)
                AS DECIMAL(12,2)
            )

        WHEN SegmentCode = 3 THEN
            CAST(
                100000 + ((n * 997) % 400000)
                AS DECIMAL(12,2)
            )
    END AS CreditLimit

FROM CustomerDetails;
GO

