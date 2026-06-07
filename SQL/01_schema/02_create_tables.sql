/*
Project: Commercial Sales Performance Analysis
File: 02_create_tables.sql
Author: Chetan Singh

Purpose:
Create the nine relational tables used in the synthetic commercial
sales database, including primary keys, foreign keys and validation
constraints.
*/

USE CommercialSalesAnalysis;
GO

/* =========================================================
   1. Customers
   ========================================================= */

IF OBJECT_ID('dbo.Customers', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Customers
    (
        CustomerID INT IDENTITY(1,1) NOT NULL,
        CustomerName VARCHAR(120) NOT NULL,
        CustomerSegment VARCHAR(30) NOT NULL,
        Industry VARCHAR(50) NOT NULL,
        Region VARCHAR(30) NOT NULL,
        City VARCHAR(50) NOT NULL,
        SignupDate DATE NOT NULL,
        AcquisitionChannel VARCHAR(30) NOT NULL,
        AccountStatus VARCHAR(20) NOT NULL,
        CreditLimit DECIMAL(12,2) NULL,

        CONSTRAINT PK_Customers
            PRIMARY KEY (CustomerID),

        CONSTRAINT CK_Customers_Segment
            CHECK
            (
                CustomerSegment IN
                (
                    'Small Business',
                    'Mid-Market',
                    'Enterprise'
                )
            ),

        CONSTRAINT CK_Customers_Region
            CHECK
            (
                Region IN
                (
                    'London',
                    'South East',
                    'South West',
                    'East of England',
                    'West Midlands',
                    'East Midlands',
                    'North West',
                    'North East',
                    'Yorkshire and the Humber',
                    'Wales',
                    'Scotland',
                    'Northern Ireland'
                )
            ),

        CONSTRAINT CK_Customers_AcquisitionChannel
            CHECK
            (
                AcquisitionChannel IN
                (
                    'Direct Sales',
                    'Website',
                    'Referral',
                    'Partner',
                    'Trade Show',
                    'Email Campaign'
                )
            ),

        CONSTRAINT CK_Customers_AccountStatus
            CHECK
            (
                AccountStatus IN
                (
                    'Active',
                    'Inactive',
                    'Suspended',
                    'Closed'
                )
            ),

        CONSTRAINT CK_Customers_CreditLimit
            CHECK
            (
                CreditLimit IS NULL
                OR CreditLimit >= 0
            )
    );
END;
GO

/* =========================================================
   2. Products
   ========================================================= */

IF OBJECT_ID('dbo.Products', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Products
    (
        ProductID INT IDENTITY(1,1) NOT NULL,
        ProductName VARCHAR(120) NOT NULL,
        Category VARCHAR(50) NOT NULL,
        Subcategory VARCHAR(60) NOT NULL,
        Brand VARCHAR(60) NOT NULL,
        UnitCost DECIMAL(10,2) NOT NULL,
        ListPrice DECIMAL(10,2) NOT NULL,
        LaunchDate DATE NOT NULL,
        DiscontinuedFlag BIT NOT NULL
            CONSTRAINT DF_Products_DiscontinuedFlag DEFAULT 0,

        CONSTRAINT PK_Products
            PRIMARY KEY (ProductID),

        CONSTRAINT CK_Products_UnitCost
            CHECK (UnitCost > 0),

        CONSTRAINT CK_Products_ListPrice
            CHECK (ListPrice > 0),

        CONSTRAINT CK_Products_PriceRelationship
            CHECK (ListPrice >= UnitCost),

        CONSTRAINT CK_Products_Category
            CHECK
            (
                Category IN
                (
                    'Technology',
                    'Office Supplies',
                    'Furniture',
                    'Cleaning and Hygiene',
                    'Food and Beverages',
                    'Packaging',
                    'Safety Equipment',
                    'Electrical Supplies'
                )
            )
    );
END;
GO

/* =========================================================
   3. Sales Representatives
   ========================================================= */

IF OBJECT_ID('dbo.SalesRepresentatives', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.SalesRepresentatives
    (
        SalesRepID INT IDENTITY(1,1) NOT NULL,
        SalesRepName VARCHAR(100) NOT NULL,
        Region VARCHAR(30) NOT NULL,
        Team VARCHAR(50) NOT NULL,
        HireDate DATE NOT NULL,
        ManagerName VARCHAR(100) NOT NULL,
        EmploymentStatus VARCHAR(20) NOT NULL,
        AnnualSalary DECIMAL(10,2) NULL,

        CONSTRAINT PK_SalesRepresentatives
            PRIMARY KEY (SalesRepID),

        CONSTRAINT CK_SalesRepresentatives_Region
            CHECK
            (
                Region IN
                (
                    'London',
                    'South East',
                    'South West',
                    'East of England',
                    'West Midlands',
                    'East Midlands',
                    'North West',
                    'North East',
                    'Yorkshire and the Humber',
                    'Wales',
                    'Scotland',
                    'Northern Ireland'
                )
            ),

        CONSTRAINT CK_SalesRepresentatives_Status
            CHECK
            (
                EmploymentStatus IN
                (
                    'Active',
                    'On Leave',
                    'Resigned',
                    'Terminated'
                )
            ),

        CONSTRAINT CK_SalesRepresentatives_Salary
            CHECK
            (
                AnnualSalary IS NULL
                OR AnnualSalary > 0
            )
    );
END;
GO

/* =========================================================
   4. Sales Targets
   ========================================================= */

IF OBJECT_ID('dbo.SalesTargets', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.SalesTargets
    (
        TargetID INT IDENTITY(1,1) NOT NULL,
        SalesRepID INT NOT NULL,
        TargetMonth DATE NOT NULL,
        RevenueTarget DECIMAL(12,2) NOT NULL,
        GrossProfitTarget DECIMAL(12,2) NOT NULL,
        NewCustomerTarget INT NOT NULL,

        CONSTRAINT PK_SalesTargets
            PRIMARY KEY (TargetID),

        CONSTRAINT FK_SalesTargets_SalesRepresentatives
            FOREIGN KEY (SalesRepID)
            REFERENCES dbo.SalesRepresentatives(SalesRepID),

        CONSTRAINT UQ_SalesTargets_RepMonth
            UNIQUE (SalesRepID, TargetMonth),

        CONSTRAINT CK_SalesTargets_Revenue
            CHECK (RevenueTarget > 0),

        CONSTRAINT CK_SalesTargets_GrossProfit
            CHECK (GrossProfitTarget > 0),

        CONSTRAINT CK_SalesTargets_NewCustomers
            CHECK (NewCustomerTarget >= 0),

        CONSTRAINT CK_SalesTargets_MonthStart
            CHECK (DAY(TargetMonth) = 1)
    );
END;
GO

/* =========================================================
   5. Orders
   ========================================================= */

IF OBJECT_ID('dbo.Orders', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Orders
    (
        OrderID BIGINT IDENTITY(1,1) NOT NULL,
        OrderDate DATE NOT NULL,
        CustomerID INT NOT NULL,
        SalesRepID INT NOT NULL,
        Region VARCHAR(30) NOT NULL,
        SalesChannel VARCHAR(30) NOT NULL,
        PaymentMethod VARCHAR(30) NOT NULL,
        OrderStatus VARCHAR(20) NOT NULL,
        ShippingCost DECIMAL(10,2) NOT NULL,
        DeliveryDays INT NULL,

        CONSTRAINT PK_Orders
            PRIMARY KEY (OrderID),

        CONSTRAINT FK_Orders_Customers
            FOREIGN KEY (CustomerID)
            REFERENCES dbo.Customers(CustomerID),

        CONSTRAINT FK_Orders_SalesRepresentatives
            FOREIGN KEY (SalesRepID)
            REFERENCES dbo.SalesRepresentatives(SalesRepID),

        CONSTRAINT CK_Orders_Region
            CHECK
            (
                Region IN
                (
                    'London',
                    'South East',
                    'South West',
                    'East of England',
                    'West Midlands',
                    'East Midlands',
                    'North West',
                    'North East',
                    'Yorkshire and the Humber',
                    'Wales',
                    'Scotland',
                    'Northern Ireland'
                )
            ),

        CONSTRAINT CK_Orders_SalesChannel
            CHECK
            (
                SalesChannel IN
                (
                    'Direct Sales',
                    'Online',
                    'Wholesale',
                    'Marketplace',
                    'Partner'
                )
            ),

        CONSTRAINT CK_Orders_PaymentMethod
            CHECK
            (
                PaymentMethod IN
                (
                    'Credit Card',
                    'Debit Card',
                    'Bank Transfer',
                    'Direct Debit',
                    'Invoice'
                )
            ),

        CONSTRAINT CK_Orders_OrderStatus
            CHECK
            (
                OrderStatus IN
                (
                    'Completed',
                    'Pending',
                    'Cancelled',
                    'Returned'
                )
            ),

        CONSTRAINT CK_Orders_ShippingCost
            CHECK (ShippingCost >= 0),

        CONSTRAINT CK_Orders_DeliveryDays
            CHECK
            (
                DeliveryDays IS NULL
                OR DeliveryDays >= 0
            )
    );
END;
GO

/* =========================================================
   6. Order Items
   ========================================================= */

IF OBJECT_ID('dbo.OrderItems', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.OrderItems
    (
        OrderItemID BIGINT IDENTITY(1,1) NOT NULL,
        OrderID BIGINT NOT NULL,
        ProductID INT NOT NULL,
        Quantity INT NOT NULL,
        UnitSellingPrice DECIMAL(10,2) NOT NULL,
        DiscountPercentage DECIMAL(5,2) NOT NULL,
        UnitCost DECIMAL(10,2) NOT NULL,

        CONSTRAINT PK_OrderItems
            PRIMARY KEY (OrderItemID),

        CONSTRAINT FK_OrderItems_Orders
            FOREIGN KEY (OrderID)
            REFERENCES dbo.Orders(OrderID),

        CONSTRAINT FK_OrderItems_Products
            FOREIGN KEY (ProductID)
            REFERENCES dbo.Products(ProductID),

        CONSTRAINT CK_OrderItems_Quantity
            CHECK (Quantity > 0),

        CONSTRAINT CK_OrderItems_UnitSellingPrice
            CHECK (UnitSellingPrice > 0),

        CONSTRAINT CK_OrderItems_DiscountPercentage
            CHECK
            (
                DiscountPercentage >= 0
                AND DiscountPercentage <= 60
            ),

        CONSTRAINT CK_OrderItems_UnitCost
            CHECK (UnitCost > 0)
    );
END;
GO

/* =========================================================
   7. Returns
   ========================================================= */

IF OBJECT_ID('dbo.Returns', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Returns
    (
        ReturnID BIGINT IDENTITY(1,1) NOT NULL,
        OrderItemID BIGINT NOT NULL,
        ReturnDate DATE NOT NULL,
        ReturnQuantity INT NOT NULL,
        ReturnReason VARCHAR(50) NOT NULL,
        RefundAmount DECIMAL(12,2) NOT NULL,
        ReturnStatus VARCHAR(20) NOT NULL,

        CONSTRAINT PK_Returns
            PRIMARY KEY (ReturnID),

        CONSTRAINT FK_Returns_OrderItems
            FOREIGN KEY (OrderItemID)
            REFERENCES dbo.OrderItems(OrderItemID),

        CONSTRAINT CK_Returns_Quantity
            CHECK (ReturnQuantity > 0),

        CONSTRAINT CK_Returns_RefundAmount
            CHECK (RefundAmount >= 0),

        CONSTRAINT CK_Returns_Reason
            CHECK
            (
                ReturnReason IN
                (
                    'Damaged',
                    'Defective',
                    'Wrong Item',
                    'No Longer Required',
                    'Late Delivery',
                    'Poor Quality',
                    'Other'
                )
            ),

        CONSTRAINT CK_Returns_Status
            CHECK
            (
                ReturnStatus IN
                (
                    'Requested',
                    'Approved',
                    'Rejected',
                    'Refunded'
                )
            )
    );
END;
GO

/* =========================================================
   8. Marketing Campaigns
   ========================================================= */

IF OBJECT_ID('dbo.MarketingCampaigns', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.MarketingCampaigns
    (
        CampaignID INT IDENTITY(1,1) NOT NULL,
        CampaignName VARCHAR(120) NOT NULL,
        CampaignType VARCHAR(40) NOT NULL,
        StartDate DATE NOT NULL,
        EndDate DATE NOT NULL,
        Budget DECIMAL(12,2) NOT NULL,
        TargetSegment VARCHAR(30) NOT NULL,
        CampaignStatus VARCHAR(20) NOT NULL,

        CONSTRAINT PK_MarketingCampaigns
            PRIMARY KEY (CampaignID),

        CONSTRAINT CK_MarketingCampaigns_Type
            CHECK
            (
                CampaignType IN
                (
                    'Email',
                    'Paid Search',
                    'Social Media',
                    'Trade Show',
                    'Partner Promotion',
                    'Direct Mail'
                )
            ),

        CONSTRAINT CK_MarketingCampaigns_Dates
            CHECK (EndDate >= StartDate),

        CONSTRAINT CK_MarketingCampaigns_Budget
            CHECK (Budget > 0),

        CONSTRAINT CK_MarketingCampaigns_TargetSegment
            CHECK
            (
                TargetSegment IN
                (
                    'Small Business',
                    'Mid-Market',
                    'Enterprise',
                    'All Customers'
                )
            ),

        CONSTRAINT CK_MarketingCampaigns_Status
            CHECK
            (
                CampaignStatus IN
                (
                    'Planned',
                    'Active',
                    'Completed',
                    'Cancelled'
                )
            )
    );
END;
GO

/* =========================================================
   9. Customer Campaign Responses
   ========================================================= */

IF OBJECT_ID('dbo.CustomerCampaignResponses', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.CustomerCampaignResponses
    (
        ResponseID BIGINT IDENTITY(1,1) NOT NULL,
        CampaignID INT NOT NULL,
        CustomerID INT NOT NULL,
        ResponseDate DATE NOT NULL,
        ResponseType VARCHAR(30) NOT NULL,
        ConvertedFlag BIT NOT NULL
            CONSTRAINT DF_CustomerCampaignResponses_ConvertedFlag DEFAULT 0,
        RevenueGenerated DECIMAL(12,2) NULL,

        CONSTRAINT PK_CustomerCampaignResponses
            PRIMARY KEY (ResponseID),

        CONSTRAINT FK_CampaignResponses_Campaigns
            FOREIGN KEY (CampaignID)
            REFERENCES dbo.MarketingCampaigns(CampaignID),

        CONSTRAINT FK_CampaignResponses_Customers
            FOREIGN KEY (CustomerID)
            REFERENCES dbo.Customers(CustomerID),

        CONSTRAINT CK_CampaignResponses_ResponseType
            CHECK
            (
                ResponseType IN
                (
                    'Opened',
                    'Clicked',
                    'Enquired',
                    'Registered',
                    'Purchased',
                    'No Response'
                )
            ),

        CONSTRAINT CK_CampaignResponses_Revenue
            CHECK
            (
                RevenueGenerated IS NULL
                OR RevenueGenerated >= 0
            ),

        CONSTRAINT CK_CampaignResponses_ConversionRevenue
            CHECK
            (
                (ConvertedFlag = 0 AND RevenueGenerated IS NULL)
                OR
                (ConvertedFlag = 1 AND RevenueGenerated IS NOT NULL)
            )
    );
END;
GO

PRINT 'Table creation script completed successfully.';
GO