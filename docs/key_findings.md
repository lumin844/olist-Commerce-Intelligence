# Key findings | observed association and business context

## 1. Customer repeat behavior

The Customer Intelligence dashboard displays an approximately **3.0%** observed-period repeat-customer rate and a **1.9×** repeat-to-one-time average historical spend multiple.

**Interpretation:** historical repeat customers purchased more over the observation period; this is not proof that a repeat-purchase campaign creates the same uplift. Follow-up analysis should consider customer tenure and cohort eligibility.

## 2. Fulfillment and reviews

In the original order-grain, reviewed-order analysis:

| Delivery flag | Reviewed orders | 1–2 star orders | Low-rating rate |
| --- | ---: | ---: | ---: |
| Not delayed | 88,163 | 8,130 | 9.22% |
| Delayed | 7,661 | 4,142 | 54.07% |

- Risk difference: **44.84 percentage points** (95% CI **43.71–45.97 pp**).
- Risk ratio: **5.863** (95% CI **5.694–6.037**).
- Pearson χ²(1) ≈ **12,693.82**, p < 0.001.

The delay flag was time-sensitive; day-based severity groups may classify sub-day delays differently. The notebook provides the calculation history. These are **descriptive/associational** statistics, not a causal effect of delayed delivery.

## 3. Severity and operational diagnosis

The exploration found that low-rating risk rose markedly across increasingly late delivery groups and was not strictly monotonic between the most severe groups. The [severity bar chart](../images/statistical/01_delay_severity_ci.png) and [adjusted-OR forest plot](../images/statistical/02_severity_or_forest.png) illustrate the analysis.

**Operational focus:** compare high-impact seller and delivery groups by GMV, frequency and observed review coverage before prioritizing investigation; do not attribute all delayed orders to sellers.

## Limitations

- Analysis is historical; review availability differs between delayed and non-delayed groups.
- Logistic OR is not a probability ratio. The adjusted estimates do not prove causality.
- The raw data does not contain complete commercial margins, ad spend or experimentally identified drivers.
- Cohort comparisons have different observation windows.

See [Metric definitions](metric_definitions.md) and the [Python notebook](../python/01_delivery_review_analysis.ipynb) for the supporting methodology.
