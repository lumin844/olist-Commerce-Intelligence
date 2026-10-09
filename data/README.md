# Data | Olist Brazilian E-Commerce

## Original source

Olist Brazilian E-Commerce Public Dataset, available from Kaggle:
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

The source contains customer, order, order-item, payment, review, product,
seller, geolocation and product-category translation tables.

## Handling policy

- Do not commit locally extracted raw CSVs, reconstructed customer-level
  exports or any secrets. Download source data from the original publisher.
- Store local originals in `data/raw/` and generated extracts in
  `data/processed/`; both are ignored by Git.
- Review the source dataset's license and terms before redistribution.
- Keep stable source keys for reproducibility, but do not claim the dataset
  includes real customer names, cost of goods or marketing spend.

## Core modeling rules

- `customer_id` identifies the order-side customer record.
- `customer_unique_id` identifies a customer across purchases.
- Orders, items, payments and reviews have different grains.
- Aggregate multi-row tables to the order level **before** joining to
  another multi-row table.
- Deduplicate geolocation ZIP prefixes before geographic joins.

## Derived inputs

The Python statistical analysis reads `delivery_review_orders.csv`
(or the compatible aligned extract) generated from the SQL reporting layer.
See `python/README.md` for preparation and interpretation details.
