# SQL analytics pipeline

Database: **MySQL 8.x**. Source: the nine Olist CSV datasets.

The numbered scripts developed for this project cover:

| Stage | Purpose |
| --- | --- |
| 00–02 | Setup, source profiling, data quality |
| 03 | Order-level semantic layer with grain-preserving aggregates |
| 04–05 | Executive KPI and growth |
| 06–08 | Customer behavior, cohort, RFM |
| 09–10 | Product portfolio and seller performance |
| 11–12 | Fulfillment and customer experience |
| 13–14 | Payment and geographic analysis |
| 15 | Cross-domain business diagnostics |
| 16 | Reporting views for Power BI |

## Reproduction guidance

1. Import the nine source CSVs into MySQL.
2. Confirm ID/data types and verify primary keys.
3. Execute original numbered SQL files in order.
4. Reconcile delivered-order counts, monetary sums and order-grain
   uniqueness after building each semantic/reporting layer.
5. Load only the curated `rpt_*` views into Power BI.

The complete original SQL scripts must be copied into this folder before
claiming end-to-end SQL reproducibility. Do **not** substitute simplified
example SQL for the analyses actually performed.

## Important metric distinction

Merchandise GMV = SUM(item price) on delivered orders, **excluding**
freight. Gross order value includes freight. Payment value is a
separate payment-side measure, not a synonym for GMV.
