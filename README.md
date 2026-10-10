# Olist Commerce Intelligence 360

**An end-to-end e-commerce analytics portfolio | MySQL · Python · Power BI**

This project analyzes Olist's public Brazilian e-commerce transactions through a business-focused workflow: data quality → order-level semantic modeling → commercial and customer analysis → operational diagnostics → interactive dashboards → statistical validation.

[**Explore the SQL analysis**](sql/) · [**Open the Python notebook**](python/01_delivery_review_analysis.ipynb) · [**Browse the dashboard gallery**](dashboard/README.md) · [**Metric definitions**](docs/metric_definitions.md)

## Dashboard gallery

### 01 · Executive Overview
Business scale, GMV and order trends, category contribution, and geographic fulfillment risk.

![Executive Overview](images/01_executive_overview.png)

### 02 · Customer Intelligence
Purchase frequency, customer value concentration, cohort repeat purchase, and RFM segmentation.

![Customer Intelligence](images/02_customer_intelligence.png)

### 03 · Product & Seller Intelligence
Category ABC portfolio, seller GMV contribution, and seller fulfillment diagnosis.

![Product and Seller Intelligence](images/03_product_seller_intelligence.png)

### 04 · Fulfillment & Customer Experience
Delay severity, review distributions, customer experience groups, and delivery distance.

![Fulfillment and Customer Experience](images/04_fulfillment_experience.png)

> **Viewing note:** the repository currently contains the four dashboard images, **not a Power BI `.pbix` file or a live Power BI link**. The screenshots show the dashboard as exported, without recreating the underlying interactions in GitHub.

## Business questions

1. How do delivered-order merchandise GMV, order volume, customer count and AOV evolve?
2. What do purchase frequency, cohorts, RFM segments and customer value reveal?
3. Which categories and sellers concentrate merchandise value?
4. How are seller dispatch, delivery delay and customer reviews associated?
5. How robust is the delivery–review association across order characteristics?

## Analytics workflow

```text
Public Olist dataset (9 source CSVs)
              │
              ▼
    MySQL profiling + quality checks
              │
              ▼
    Semantic views by explicit data grain
    (order, order item, customer, seller)
              │
       ┌──────┴────────────┐
       ▼                   ▼
  Reporting views      Statistical export
       │                   │
       ▼                   ▼
  Power BI dashboard   Python / GLM analysis
```

**Grain discipline:** item, payment and review records are not always one row per order. The SQL analysis aggregates one-to-many relationships before joining them to order-level measures. A customer's cross-order identifier is `customer_unique_id`.

## Methods and evidence

| Domain | Included analyses |
| --- | --- |
| Growth | Delivered-order GMV, customers, orders, AOV, trends |
| Customer | Repeat purchase, cohort, customer Pareto, RFM |
| Product & Seller | Category ABC, commercial concentration, seller fulfillment |
| Operations | Dispatch, delays, order reviews, geographic patterns |
| Statistical validation | Chi-square, risk difference, risk ratio, Logistic regression and sensitivity analysis |

### Delivery delay and reviews

In the order-level analysis using the original delay flag, **9.22%** of non-delayed reviewed orders and **54.07%** of delayed reviewed orders received a low rating (1–2 stars). The corresponding **risk ratio was 5.863** (95% CI: 5.694–6.037).

The association is **not causal evidence**. Timestamp-level delay flags and day-binned delay severity require careful interpretation; the notebook documents its precise definition and excludes missing reviews from the rate denominator.

![Low-rating rate by delay severity](images/statistical/01_delay_severity_ci.png)

![Adjusted OR by delay severity](images/statistical/02_severity_or_forest.png)

[See the full methodological notes](docs/key_findings.md).

## Repository structure

```text
.
├── README.md
├── requirements.txt
├── .gitignore
├── sql/
│   ├── 01_data_profile.sql
│   ├── 02_data_quality.sql
│   ├── 03_semantic_layer.sql
│   ├── ... (analysis chapters 04–15)
│   ├── 16_reporting_views.sql
│   └── 17_delivery_review_extract.sql
├── python/
│   ├── 01_delivery_review_analysis.ipynb
│   └── README.md
├── dashboard/
│   └── README.md
├── images/
│   ├── 01_executive_overview.png
│   ├── 02_customer_intelligence.png
│   ├── 03_product_seller_intelligence.png
│   ├── 04_fulfillment_experience.png
│   └── statistical/
│       ├── 01_delay_severity_ci.png
│       └── 02_severity_or_forest.png
├── data/
│   └── README.md
└── docs/
    ├── analysis_framework.md
    ├── key_findings.md
    └── metric_definitions.md
```
## Definitions and limitations

- **GMV** is delivered-order item-price revenue, excluding freight; it is not net profit.
- **Repeat rate / RFM** refer to the observed period and have limited historical-comparability semantics.
- **Customer reviews** are order-level evidence, not automatically product- or seller-specific ratings.
- **Distance** uses approximated straight-line geography on a restricted order subset.
- **Statistical results** describe historical associations, not causal impacts.
- The dataset lacks complete cost, acquisition and experimentation data.

See [metric definitions](docs/metric_definitions.md) and [data provenance](data/README.md).

## Source

[Olist Brazilian E-Commerce Public Dataset — Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce). Independent educational analysis; not an official Olist business report.
