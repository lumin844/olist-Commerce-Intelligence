# SQL analysis pipeline (MySQL 8)

The repository contains the project's original exploratory SQL scripts, organized in analysis order. They use an already populated MySQL database with source tables such as `orders`, `customers`, `order_items`, `payments`, `reviews`, `products`, `sellers` and `geolocations`.

| Script | Analysis area |
| --- | --- |
| [01_data_profile.sql](01_data_profile.sql) | Profiling and source-grain inspection |
| [02_data_quality.sql](02_data_quality.sql) | Completeness, referential checks and data validity |
| [03_semantic_layer.sql](03_semantic_layer.sql) | Order-grain and customer semantic views |
| [04_executive_kpi.sql](04_executive_kpi.sql) | Executive KPI |
| [05_growth_analysis.sql](05_growth_analysis.sql) | Monthly business growth |
| [06_customer_analysis.sql](06_customer_analysis.sql) | Customer behavior |
| [07_cohort_analysis.sql](07_cohort_analysis.sql) | Cohort repeat purchase |
| [08_rfm_segmentation.sql](08_rfm_segmentation.sql) | RFM segmentation |
| [09_product_portfolio.sql](09_product_portfolio.sql) | Category / product portfolio |
| [10_seller_performance.sql](10_seller_performance.sql) | Seller analysis |
| [11_fulfillment_analysis.sql](11_fulfillment_analysis.sql) | Fulfillment |
| [12_customer_experience.sql](12_customer_experience.sql) | Customer reviews |
| [13_payment_analysis.sql](13_payment_analysis.sql) | Payment methods |
| [14_geographic_analysis.sql](14_geographic_analysis.sql) | Geographic patterns |
| [15_business_diagnostics.sql](15_business_diagnostics.sql) | Cross-domain diagnostics; includes revised cohort logic |
| [16_reporting_views.sql](16_reporting_views.sql) | Power BI reporting layer |
| [17_delivery_review_extract.sql](17_delivery_review_extract.sql) | Delivered-order extract for Python |

## Execution notes

These files preserve the original SQL analysis, including intermediate inspection queries, and are **not** presented as a single idempotent migration script. The source import DDL/CSV files are not part of this repository. Run on an appropriately prepared local MySQL 8 database and inspect dependencies before applying `CREATE VIEW` statements to an existing environment.

Core modeling principles: one row/order for order KPIs; aggregate order items, reviews and payments before broad joins; keep `customer_unique_id` as the true customer key. Merchandise GMV excludes freight.
