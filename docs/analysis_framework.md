# Business analysis framework

## Central business question
What are the drivers of the platform's merchandise volume and where do
customer value, seller operations and fulfillment performance require
additional investigation?

## Analysis layers

1. **Scale & growth** — delivered-order GMV, orders, AOV and monthly trends.
2. **Customer behavior** — purchase frequency, repeat purchase, cohort
   retention, lifetime value and RFM snapshots.
3. **Portfolio & supply** — category contribution and ABC, seller
   concentration, ratings and dispatch performance.
4. **Fulfillment & experience** — on-time performance, delay severity,
   customer reviews and logistic association.
5. **Geography & payments** — customer-state demand, seller origins,
   payment methods, single-seller approximate transport distance.
6. **Decision support** — business impact vs issue severity; proposed
   investigations and carefully scoped experiments.

## Statistical analysis design

- Unit: delivered order, one row/order.
- Reviewed subset: restrict to valid 1–5 scores when studying low ratings.
- Primary contrast: late vs not late; low rating = 1–2.
- Report absolute risk difference, relative risk, confidence intervals.
- Multivariable logistic regression controls available order covariates;
  customer-clustered standard errors address repeated customers.
- Sensitivity: severity groups and single-seller subset.
- Interpret as association, not causation; review missingness, observation
  windows and unobserved confounding limit inference.

## Evidence standards

Always distinguish:
**Observed fact** → **Comparison** → **Interpretation** → **Hypothesis**.

Publish exact verified results, the sample definition and the original
query/notebook that supports each claim.
