# Python statistical validation

## Workflow

The project extends the SQL and four-page Power BI dashboard with
inferential analysis of delivery delay and customer ratings.

Input: an **order-level** CSV extracted from the MySQL reporting view,
placed locally at `data/processed/delivery_review_orders.csv`.
Also supports `delivery_review_orders_aligned.csv` where available.

Recommended analyses:
- Review coverage by delivery status
- Low-rating rates, risk difference / ratio and confidence intervals
- Chi-square independence test
- Binary and severity-level Logistic GLMs
- Sensitivity analysis on single-seller delivered orders
- Model diagnostics, in-sample AUC and Brier score
- Export reproducible summary tables and plots

### Run locally

```bash
python -m venv .venv
python -m pip install -r requirements.txt
```

Select the `.venv` interpreter/kernel in VS Code, then run the
notebook from top to bottom. If Jupyter state is reset, run earlier cells
again before referencing existing model variables. The **independent**
chapter-18 diagnostic notebook does not require pre-existing session
variables.

**Statistical limitation:** Logistic odds ratios are not risk ratios.
In-sample metrics are not out-of-sample validation. Statistical
association does not imply causal impact.
