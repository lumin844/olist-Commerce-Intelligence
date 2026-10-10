# Python｜配送延迟与客户低评分统计分析

[查看 Notebook](01_delivery_review_analysis.ipynb) · [查看统计图](../images/statistical/) · [查看业务发现](../docs/key_findings.md)

本目录保留项目实际使用的 **`01_delivery_review_analysis.ipynb`**。Notebook 包含数据检查、延迟组与低评分率比较、卡方检验、风险差与风险比、Logistic 回归、模型标准化预测概率和延迟严重程度分析。

## 输入数据

运行 [SQL 订单提取脚本](../sql/17_delivery_review_extract.sql)，将查询结果作为 CSV 放入本地：

```text
data/processed/delivery_review_orders.csv
```

Notebook 需要 **一行一笔订单**，常用字段包括 `order_id`、`customer_unique_id`、`is_delayed`、`delay_days`、`review_score`、商品金额、运费、商品数量、卖家数量、州及月份。

## 本地运行

在项目根目录创建 Python 环境并安装依赖：

```bash
python -m venv .venv
python -m pip install -r requirements.txt
```

使用 VS Code / Jupyter 打开 Notebook，选择相应 Kernel，**从上到下执行**。此文件保存了分析过程中迭代后的代码：需要查看各模型所在 Cell 的实际变量及口径，不应假设每个中间版本都能独立执行。

## 分析边界

- 低评分定义为 **1–2 星**，计算发生率时只使用有效评分订单。
- 延迟标记和按天取整的延迟程度可能存在不足一天的边界差异。
- **Risk Ratio 与 Logistic Odds Ratio 不同**；后者不能解释为“低评分概率的倍数”。
- 回归调整只能控制已纳入的可观测变量，不能直接证明延迟造成低评分。
- 同一客户可能有多笔订单，报告中应明确聚类稳健标准误等处理方法。
