# SQL 分析流程（MySQL 8）

本目录为 Olist 电商经营分析项目的 SQL 代码，按照**数据检查 → 语义层构建 → 经营与客户分析 → 商品及卖家运营 → 交付体验 → 综合诊断 → BI 报表视图**的顺序组织。

| 脚本 | 作用 |
| --- | --- |
| [`01_data_profile.sql`](01_data_profile.sql) | 原始数据规模、字段粒度与分布画像 |
| [`02_data_quality.sql`](02_data_quality.sql) | 缺失值、重复记录、关联完整性和业务逻辑检查 |
| [`03_semantic_layer.sql`](03_semantic_layer.sql) | 订单级、商品级和客户级语义层 |
| [`04_executive_kpi.sql`](04_executive_kpi.sql) | 经营核心 KPI |
| [`05_growth_analysis.sql`](05_growth_analysis.sql) | 月度增长与增长来源 |
| [`06_customer_analysis.sql`](06_customer_analysis.sql) | 购买频率、客户价值和复购 |
| [`07_cohort_analysis.sql`](07_cohort_analysis.sql) | 按首购月份划分的 Cohort 分析 |
| [`08_rfm_segmentation.sql`](08_rfm_segmentation.sql) | RFM 客户分群 |
| [`09_product_portfolio.sql`](09_product_portfolio.sql) | 商品品类、ABC 分类及价值结构 |
| [`10_seller_performance.sql`](10_seller_performance.sql) | 卖家贡献、履约及客户体验 |
| [`11_fulfillment_analysis.sql`](11_fulfillment_analysis.sql) | 订单履约环节及延迟诊断 |
| [`12_customer_experience.sql`](12_customer_experience.sql) | 评分、低评分与履约相关分析 |
| [`13_payment_analysis.sql`](13_payment_analysis.sql) | 支付方式、分期与订单金额 |
| [`14_geographic_analysis.sql`](14_geographic_analysis.sql) | 地区供需分布、地理距离与履约 |
| [`15_business_diagnostics.sql`](15_business_diagnostics.sql) | 综合业务诊断及部分阶段性修订逻辑 |
| [`16_reporting_views.sql`](16_reporting_views.sql) | 面向 Power BI 的报表事实表和维度视图 |
| [`17_delivery_review_extract.sql`](17_delivery_review_extract.sql) | Python 统计分析所需的订单级数据提取 |

## 运行说明

SQL 使用**已导入 Olist 原始 CSV 的 MySQL 8 数据库**。仓库保存的是实际分析脚本与视图定义，包含中间核对查询；它们不是设计为可重复执行的自动化数据库迁移脚本。

建议按文件编号阅读，正式执行前先检查源表名称、视图依赖和是否已经存在同名视图。在已有数据库中重复执行 `CREATE VIEW` 可能报错；不要直接执行整套脚本来覆盖原有分析环境。

## 核心技术原则

**订单粒度保护**：订单商品、支付与评价记录都可能存在一对多关系，不应不经汇总便同时与订单表连接。

**明确业务口径**：商品 GMV 为已交付订单商品 `price` 之和，不包含运费；客户去重采用 `customer_unique_id`。

**报表层与统计层衔接**：[第 16 章](16_reporting_views.sql) 构建面向 Power BI 的 `rpt_*` 视图；[第 17 章](17_delivery_review_extract.sql) 从订单报表视图提取统计分析数据。

[返回项目首页](../README.md)。
