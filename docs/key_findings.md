# Selected findings and evidence status

This document lists previously reported **exploratory** findings.
Replace preliminary figures with the checked exports from the final
statistical notebook and the local SQL/Power BI source before presenting
a definitive public numerical claim.

## 1. Repeat purchase is uncommon

A previous Power BI customer snapshot showed approximately 3.0% repeat
customers over the observed data window, with repeat customers having
approximately 1.9× the **historical spend per customer** of one-time
customers. These are retrospective, unequal-window comparisons.

**Action to investigate:** first-to-second-order conversion, segment
eligibility and measurement windows.

## 2. Delivery delay is strongly associated with low reviews

A reviewed-order analysis reported:
- Non-delayed: 8,130 low-rated among 88,163, or 9.22%.
- Delayed: 4,142 low-rated among 7,661, or 54.07%.
- Risk difference: 44.84 percentage points, 95% CI [43.71, 45.97].
- Risk ratio: 5.863, 95% CI [5.694, 6.037].
- Pearson chi-square ~12,693.82; p<0.001.

**Definition caveat:** These figures came from the originally used delay
flag. Later analysis distinguished sub-day timestamp delays from
calendar-day bins. Check the final dataset and use a single declared
definition when publishing adjusted analyses or comparing with Power BI.

## 3. Severity pattern is not strictly monotone

An initial severity analysis showed low-rating proportions increasing
through the 8–14 day group, then marginally lower in 15+ days.
Use the final re-run output before quoting group percentages; report
sample sizes and uncertainty intervals.

## Interpretation

These are observational historical associations. A lower review score
does not establish delay as its cause. Product quality, customer
expectations, seller behavior and unmeasured service factors remain
possible alternative explanations.

## To finalize

Add verified evidence and actions from the user's chapter-19 business
findings before treating this document as the final set of recommendations.
