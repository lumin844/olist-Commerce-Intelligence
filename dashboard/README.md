# Power BI dashboard

**File:** `Olist_Commerce_Intelligence.pbix` (add the final local file).

Four-page analytical structure:

| Page | Question answered | Main visuals |
| --- | --- | --- |
| 01 Executive Overview | How is business performance evolving? | KPI cards, monthly trends, category contribution, state value vs fulfillment |
| 02 Customer Intelligence | Who buys again, and which customers are valuable? | Frequency, customer concentration, cohort heatmap, RFM |
| 03 Product & Seller Intelligence | Which categories and sellers generate GMV, and where are the risks? | ABC, category portfolio, seller concentration, dispatch vs delivery |
| 04 Fulfillment & Customer Experience | How does delivery performance relate to ratings? | Delay severity, experience segments, distance and freight |

## Model conventions

- Order-grain metrics from `FactOrder`.
- Item/category/seller contribution metrics from `FactOrderItem`.
- Shared, single-direction dimensions for date, customer, category,
  seller and customer state.
- Cohort and RFM are historical/snapshot analytics with distinct
  time-filter semantics; do not represent them as historical dynamic RFM.
- Order-level review scores must not be averaged over repeated
  order-item rows.
- Document whether delay is defined on timestamp precision
  or calendar dates; avoid mixing definitions.

## Publishing

1. Save the final .pbix locally.
2. Export clean **final** full-page PNG screenshots for each dashboard.
3. Add screenshots to `images/` using the filenames in the README.
4. Check `.pbix` size before pushing. GitHub rejects individual files
   larger than 100 MiB; use Git LFS if needed, or publish a link instead.

Local MySQL credentials must not be committed in connection strings,
scripts, notebooks or configuration files.
