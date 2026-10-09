# Olist Commerce Intelligence 360

**SQL · Python · Power BI | E-commerce analytics portfolio**

A business-focused analytics project built on the public Olist Brazilian
e-commerce dataset. It follows the full workflow from multi-table data
quality and order-level modeling to commercial dashboards, customer
segmentation, fulfillment diagnostics and statistical validation.

> **Portfolio status:** Repository documentation is online. The original
> numbered SQL source files, final 4-page Power BI `.pbix`, polished
> screenshots and verified exported statistics still need to be added
> from the local project. This is **not yet** a fully reproducible release.

## Business questions

- How do delivered-order GMV, order count, AOV and customer base evolve?
- How much do repeat customers contribute to historical customer value?
- Which product categories and sellers concentrate commercial activity?
- How are seller dispatch, delivery delay and customer reviews related?
- Do those patterns persist after accounting for observable order factors?

## Project overview

| Area | Methods / output |
| --- | --- |
| Data modeling | MySQL 8, grain-preserving order semantic views |
| Commercial analysis | Monthly growth, delivered-order GMV and AOV |
| Customer intelligence | Frequency, cohorts, repeat rate, Pareto, RFM |
| Product & seller | ABC category portfolio, seller ranking and risk exploration |
| Operations | Delivery stages, customer reviews, geographic proxies |
| Statistical evidence | Risk difference/ratio, chi-square, Logistic GLM, 95% CIs |
| BI presentation | Four-page Power BI executive-to-operations story |

## Power BI dashboard

The completed dashboard is organized as four analytical pages.
Final screenshots and the Power BI source file will be added after local export.

| Page | Focus |
| --- | --- |
| **01 — Executive Overview** | GMV, delivered orders, customers, AOV, growth and regional fulfillment |
| **02 — Customer Intelligence** | Repeat purchase, customer value concentration, cohorts and RFM |
| **03 — Product & Seller Intelligence** | Category ABC, seller contribution and fulfillment diagnosis |
| **04 — Fulfillment & Customer Experience** | Delivery delay, reviews, severity, experience groups and distance |

See [dashboard documentation](dashboard/README.md) for page definitions
and modeling conventions.

## Data architecture

```text
Nine original Olist CSV tables
    |
    v
MySQL source profiling + quality checks
    |
    v
Semantic views (1 row/order, order-item and seller-grain summaries)
    |
    +--> Reporting views --> Power BI shared dimensions + facts
    |
    +--> Order-level export --> Python statistical notebook
```

**Grain safety matters.** Payments and order items are separate 1-to-many
tables; joining both unaggregated to orders duplicates business measures.
Customer reporting uses `customer_unique_id` rather than `customer_id`.

See [metrics](docs/metric_definitions.md), [analysis framework](docs/analysis_framework.md),
and [source data notes](data/README.md).

## Selected findings (previous exploratory outputs)

- Customer repeat purchase is relatively uncommon in the observed
  window; retrospective customer value differs by purchase frequency.
- In one reviewed-order analysis using the original delay flag, low
  ratings occurred in **54.07%** of delayed orders vs **9.22%** of
  non-delayed orders (RR **5.863**, 95% CI **5.694–6.037**).
- Delivery delay and review score show an association, **not a proven
  causal effect**. The timestamp/calendar-day boundary and differences
  in missing-review coverage must be disclosed.

See [key findings and cautions](docs/key_findings.md). Final adjusted
model estimates should be quoted from the local, verified exports only.

## Repository organization

```text
.
├── README.md
├── requirements.txt
├── .gitignore
├── data/
│   └── README.md
├── docs/
│   ├── metric_definitions.md
│   ├── analysis_framework.md
│   └── key_findings.md
├── sql/
│   └── README.md
├── python/
│   └── README.md
├── dashboard/
│   └── README.md
├── images/                 # final dashboard/analysis images to be added
└── results/                # verified aggregate outputs to be added
```

The number-labeled SQL scripts (00–16), local notebooks, dashboard file
and image exports are being added separately. Do not infer that files
listed in the workflow are already present in this repository.

## How to reproduce

1. Obtain the public [Olist Brazilian E-Commerce Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).
2. Load the original nine CSV tables into MySQL 8.x.
3. Run the project's original numbered SQL scripts when available,
   checking row counts, join grain and monetary reconciliation.
4. Import curated reporting views to Power BI; use single-direction
   relationships and grain-appropriate measures.
5. Extract an order-grain statistical dataset and run the notebook in
   a local virtual environment (`pip install -r requirements.txt`).

**Currently the full numbered SQL scripts and local dashboard assets have
not been uploaded, so reproduction is not yet end-to-end.**

## Scope and limitations

The dataset is historical and does not provide cost of goods, acquisition
spend, complete causal drivers, or a contemporary operational feed.
Delivered-only revenue definitions, review selection, the exact delay
definition and potential cohort right censoring are documented.
Some order-level review information cannot legitimately be assigned to
individual products or sellers without further assumptions.

## Source and acknowledgments

Source: Olist, **Brazilian E-Commerce Public Dataset** on
[Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).

The analysis, model definitions and dashboard narrative are an
independent educational/portfolio exercise and do not represent an
official Olist operating report.
