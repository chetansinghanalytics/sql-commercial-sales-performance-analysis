# SQL Commercial Sales Performance Analysis

## Project Overview

This project demonstrates an end-to-end commercial analytics workflow using Microsoft SQL Server.

A purpose-built synthetic UK sales database was created to analyse customer behaviour, product performance, regional sales, profitability, sales representative achievement, returns and marketing campaign effectiveness.

The final database contains approximately:

- 20,000 customers
- 500 products
- 120 sales representatives
- 300,000 orders
- 879,000 order-item records
- 24,000 return records
- 100,000 campaign responses
- 3,420 monthly sales-target records

The project focuses on using SQL to transform large transactional data into clear commercial insights and decision-ready outputs.

> This project uses synthetic data created specifically for portfolio purposes. It does not contain confidential customer or company information.

---

## Business Problem

A UK commercial distributor wants to understand the key drivers of its sales performance and identify opportunities to improve growth, profitability and operational efficiency.

Management requires insight into:

- Revenue and profit trends
- Regional performance
- Customer value and concentration
- Product and category profitability
- Sales representative target achievement
- Discount effectiveness
- Return rates and refund costs
- Marketing campaign conversion and ROI
- Commercial risks and growth opportunities

---

## Tools Used

- Microsoft SQL Server
- SQL Server Management Studio
- Git and GitHub
- Power BI planned for the dashboard stage

---

## SQL Skills Demonstrated

- Relational database design
- Primary and foreign keys
- Validation constraints
- Index creation
- Multi-table joins
- Common table expressions
- Window functions
- `ROW_NUMBER`
- `DENSE_RANK`
- `LAG`
- `PERCENT_RANK`
- Conditional aggregation
- Date analysis
- Customer segmentation
- Revenue and profitability calculations
- Target-versus-actual analysis
- Data-quality validation
- Synthetic data generation
- Query performance optimisation

---

## Database Structure

The database contains nine connected tables:

| Table | Purpose |
|---|---|
| `Customers` | Customer segment, industry, location and acquisition information |
| `Products` | Product category, brand, cost and selling-price information |
| `SalesRepresentatives` | Sales team, region, manager and employment information |
| `SalesTargets` | Monthly revenue, gross-profit and new-customer targets |
| `Orders` | Order date, customer, representative, channel and status |
| `OrderItems` | Product-level quantity, selling price, cost and discount |
| `Returns` | Returned quantities, reasons, status and refund amount |
| `MarketingCampaigns` | Campaign type, budget, dates and target segment |
| `CustomerCampaignResponses` | Engagement, conversion and attributed revenue |

---

## Project Structure

```text
sql-commercial-sales-performance-analysis
│
├── sql
│   ├── 01_schema
│   │   ├── 01_create_database.sql
│   │   ├── 02_create_tables.sql
│   │   └── 03_create_indexes.sql
│   │
│   ├── 02_data_generation
│   │   ├── 01_generate_products.sql
│   │   ├── 02_generate_sales_representatives.sql
│   │   ├── 03_generate_customers.sql
│   │   ├── 04_generate_marketing_campaigns.sql
│   │   ├── 05_generate_orders.sql
│   │   ├── 06_generate_order_items.sql
│   │   ├── 07_generate_sales_targets.sql
│   │   ├── 08_generate_returns.sql
│   │   └── 09_generate_campaign_responses.sql
│   │
│   ├── 03_data_quality
│   │   └── 01_data_quality_audit.sql
│   │
│   ├── 04_analysis
│   │   ├── 01_business_overview.sql
│   │   ├── 02_monthly_sales_trends.sql
│   │   ├── 03_regional_performance.sql
│   │   ├── 04_customer_analysis.sql
│   │   ├── 05_product_profitability.sql
│   │   ├── 06_sales_rep_performance.sql
│   │   ├── 07_returns_analysis.sql
│   │   ├── 08_marketing_campaign_analysis.sql
│   │   └── 09_executive_insights.sql
│   │
│   └── 05_power_bi_views
│
├── data
├── images
├── reports
├── .gitignore
├── LICENSE
└── README.md