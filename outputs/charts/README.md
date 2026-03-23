# 图表输出目录

本目录用于存放基于六张核心图表数据绘制的可视化图表文件（PNG / PDF 格式）。

## 图表清单

| 文件名 | 图表类型 | 说明 |
|---|---|---|
| `01_portfolio_overview.png` | 汇总卡片 / 表格 | 消费信贷资产组合违约概览 |
| `02_default_by_lti_band.png` | 条形图 | 不同贷款收入比（LTI）分段的违约率对比 |
| `03_default_by_refusal_rate.png` | 条形图 | 历史拒贷率分段与当前违约率关系 |
| `04_default_by_overdue_band.png` | 条形图 | 平均逾期天数分组下的违约率表现 |
| `05_risk_level_distribution.png` | 饼图 / 环形图 | 低风险 / 中风险 / 高风险客户占比分布 |
| `06_default_by_risk_level.png` | 分组条形图 | 不同风险层级客户违约率与平均贷款金额对比 |

## 绘图工具建议

- **Python**：使用 `matplotlib` 或 `seaborn` 库，读取 `outputs/tables/` 目录下的 CSV 文件绘图。
- **Excel / WPS**：直接打开 CSV 文件后使用内置图表功能。
- **Tableau / Power BI**：连接 MySQL 数据库或导入 CSV，利用拖拽式界面完成可视化。

## Python 绘图示例（图2：LTI 分段违约率）

```python
import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv('outputs/tables/02_default_by_lti_band.csv')  # 在项目根目录下运行
plt.figure(figsize=(7, 4))
plt.bar(df['lti_band'], df['default_rate_pct'], color='steelblue')
plt.xlabel('贷款收入比分段')
plt.ylabel('违约率 (%)')
plt.title('不同贷款收入比客户的违约率对比')
plt.tight_layout()
plt.savefig('02_default_by_lti_band.png', dpi=150)
plt.show()
```
