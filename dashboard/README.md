# Power BI｜四页 Dashboard 展示

项目通过四页 Dashboard 形成**经营概览 → 用户价值 → 商品及卖家 → 履约体验**的完整分析链。这里提供实际页面截图，打开链接即可预览。

| 页面 | 核心业务问题 | 图片 |
| --- | --- | --- |
| **01 Executive Overview** | GMV、订单、用户与增长表现如何？ | [查看经营总览](../images/01_executive_overview.png) |
| **02 Customer Intelligence** | 客户购买频率、价值集中度与重复购买如何？ | [查看客户分析](../images/02_customer_intelligence.png) |
| **03 Product & Seller Intelligence** | 核心品类、头部卖家及潜在履约风险在哪里？ | [查看商品与卖家](../images/03_product_seller_intelligence.png) |
| **04 Fulfillment & Customer Experience** | 配送表现如何与评分、运费和距离关联？ | [查看履约体验](../images/04_fulfillment_experience.png) |

## 关键建模原则

- `FactOrder` 负责订单粒度指标；按品类和卖家分析商品收入时，使用正确的商品或汇总粒度。
- 不直接对重复商品明细中的订单评分计算简单均值，以免一单多件造成重复加权。
- Cohort 和 RFM 是基于观察窗口的分析，不能把全周期快照误认为按任意日期实时重算的分群。
- 预计交付日期、实际交付时间与 `delay_days` 的时间精度需要在解释短时延迟时区分。

本仓库选择以**可直接浏览的 Dashboard 截图**展示 Power BI 成果，不提供在线交互服务。指标口径参考 [Metric definitions](../docs/metric_definitions.md)。
