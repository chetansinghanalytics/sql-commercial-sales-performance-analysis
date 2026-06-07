/*
Project: Commercial Sales Performance Analysis
File: 03_create_indexes.sql
Author: Chetan Singh

Purpose:
Create indexes that improve the performance of joins, filters and
time-based analysis across the commercial sales database.
*/

USE CommercialSalesAnalysis;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_SalesTargets_SalesRepID'
      AND object_id = OBJECT_ID('dbo.SalesTargets')
)
CREATE INDEX IX_SalesTargets_SalesRepID
ON dbo.SalesTargets(SalesRepID);
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_SalesTargets_TargetMonth'
      AND object_id = OBJECT_ID('dbo.SalesTargets')
)
CREATE INDEX IX_SalesTargets_TargetMonth
ON dbo.SalesTargets(TargetMonth);
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_Orders_CustomerID'
      AND object_id = OBJECT_ID('dbo.Orders')
)
CREATE INDEX IX_Orders_CustomerID
ON dbo.Orders(CustomerID);
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_Orders_SalesRepID'
      AND object_id = OBJECT_ID('dbo.Orders')
)
CREATE INDEX IX_Orders_SalesRepID
ON dbo.Orders(SalesRepID);
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_Orders_OrderDate'
      AND object_id = OBJECT_ID('dbo.Orders')
)
CREATE INDEX IX_Orders_OrderDate
ON dbo.Orders(OrderDate);
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_Orders_Region'
      AND object_id = OBJECT_ID('dbo.Orders')
)
CREATE INDEX IX_Orders_Region
ON dbo.Orders(Region);
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_Orders_SalesChannel'
      AND object_id = OBJECT_ID('dbo.Orders')
)
CREATE INDEX IX_Orders_SalesChannel
ON dbo.Orders(SalesChannel);
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_OrderItems_OrderID'
      AND object_id = OBJECT_ID('dbo.OrderItems')
)
CREATE INDEX IX_OrderItems_OrderID
ON dbo.OrderItems(OrderID);
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_OrderItems_ProductID'
      AND object_id = OBJECT_ID('dbo.OrderItems')
)
CREATE INDEX IX_OrderItems_ProductID
ON dbo.OrderItems(ProductID);
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_Returns_OrderItemID'
      AND object_id = OBJECT_ID('dbo.Returns')
)
CREATE INDEX IX_Returns_OrderItemID
ON dbo.Returns(OrderItemID);
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_Returns_ReturnDate'
      AND object_id = OBJECT_ID('dbo.Returns')
)
CREATE INDEX IX_Returns_ReturnDate
ON dbo.Returns(ReturnDate);
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_CampaignResponses_CampaignID'
      AND object_id = OBJECT_ID('dbo.CustomerCampaignResponses')
)
CREATE INDEX IX_CampaignResponses_CampaignID
ON dbo.CustomerCampaignResponses(CampaignID);
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_CampaignResponses_CustomerID'
      AND object_id = OBJECT_ID('dbo.CustomerCampaignResponses')
)
CREATE INDEX IX_CampaignResponses_CustomerID
ON dbo.CustomerCampaignResponses(CustomerID);
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_CampaignResponses_ResponseDate'
      AND object_id = OBJECT_ID('dbo.CustomerCampaignResponses')
)
CREATE INDEX IX_CampaignResponses_ResponseDate
ON dbo.CustomerCampaignResponses(ResponseDate);
GO

PRINT 'Index creation script completed successfully.';
GO