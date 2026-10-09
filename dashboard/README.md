# Power BI dashboard | four-page gallery

This directory describes the original Power BI report. Four exported screenshots are included in [../images](../images/); the editable `.pbix` **is not currently stored in this GitHub repository**.

| Page | Business question | Preview |
| --- | --- | --- |
| Executive Overview | How does the business perform? | [View](../images/01_executive_overview.png) |
| Customer Intelligence | What drives customer value and repeat purchase? | [View](../images/02_customer_intelligence.png) |
| Product & Seller Intelligence | Which categories and sellers matter, and what risks warrant examination? | [View](../images/03_product_seller_intelligence.png) |
| Fulfillment & Customer Experience | How does delivery performance relate to ratings? | [View](../images/04_fulfillment_experience.png) |

## Business logic

The model uses shared dimensions (Date, Customer, Category, Seller and State) and reporting facts with separate grains.

- Order-level KPIs come from `FactOrder`.
- Item/category and seller contribution use the corresponding item or summary grain, rather than multiplying order-level revenue after joining.
- Cohort and RFM represent observed-period or fixed-cutoff customer analysis, not dynamically reconstructed historical cohorts under arbitrary date slicers.
- Review score is recorded at the order level.
- Delay definitions can depend on timestamp vs calendar-day precision, particularly for short late deliveries.

For a self-contained visual walkthrough, open the four images above. To inspect relationships and DAX measures, the original `.pbix` would need to be provided separately.
