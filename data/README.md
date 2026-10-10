# 数据来源 | Olist Brazilian E-Commerce

项目使用 Kaggle 发布的 [Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)。

数据包含九类 CSV：客户、订单、订单商品、支付、评论、商品、卖家、地理位置及商品类别翻译。原始数据由发布方提供，仓库集中存放分析 SQL、Notebook 和可视化成果，不重复打包原始交易 CSV。

## 数据处理注意事项

- `customer_id` 对应单次订单相关的客户记录，跨订单客户分析使用 `customer_unique_id`。
- 一笔订单可包含多个商品、支付记录或评价记录；必须先检查粒度再关联。
- 原始地理位置表存在重复 ZIP 前缀，地理分析需要去重或聚合。
- 商品 GMV 按已交付订单的商品价格计算，不包括运费或支付渠道金额。

SQL 使用已在 MySQL 中导入的数据表，参见 [SQL 分析流程](../sql/README.md)。
