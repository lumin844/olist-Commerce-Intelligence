# Metric definitions

These definitions govern SQL, Power BI and Python analysis.

| Metric | Definition | Grain / caveat |
| --- | --- | --- |
| Delivered orders | DISTINCT order_id where order_status='delivered' | Order |
| Customers | DISTINCT customer_unique_id on delivered orders | Customer |
| Merchandise GMV | SUM(order item price), delivered orders | Excludes freight |
| Freight | SUM(order item freight_value), delivered orders | Items summed once |
| Gross order value | Merchandise GMV + freight | Not equal to payment value |
| AOV | Merchandise GMV / delivered orders | Delivered-order scope |
| Repeat customer | Customer with >=2 delivered orders during observed period | Full-period classification |
| Repeat rate | Repeat customers / delivered-order customers | Subject to right censoring |
| Latest review score | Latest review per order using deterministic timestamp/id selection | One review score/order |
| Low-rating rate | Orders with 1-2 star score / orders with valid review score | Excludes missing reviews |
| Delay rate | Delayed / delivered orders with observable timing | **Declare timestamp vs calendar-day definition** |
| Cohort M1 | Customers buying in next calendar month / customers acquired in cohort month | Repeat purchase, not app retention |
| RFM | Recency, frequency and monetary features at a fixed analysis cutoff | Historical snapshot |
| Seller GMV | Delivered item-price revenue assigned to seller | Order × seller aggregation |
| Geographic distance | ZIP-centroid straight-line seller-to-customer distance | Single-seller delivered order subset |
| Risk Ratio | Low-rating probability in delayed group / not-delayed group | Observational association |
| Logistic OR | Ratio of odds estimated by regression | **Not** probability ratio or causal effect |

Use explicitly named denominators for all proportions, retain unreviewed orders
when auditing review coverage and avoid attributing all order-level ratings to
individual products or sellers.
