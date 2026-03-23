# 表格输出目录

本目录用于存放各 SQL 查询的表格结果输出（CSV / Excel 格式）。

## 文件命名规范

| 文件名 | 对应 SQL | 说明 |
|---|---|---|
| `01_portfolio_overview.csv` | `05_six_core_diagrams.sql` 图1 | 消费信贷资产组合违约概览 |
| `02_default_by_lti_band.csv` | `05_six_core_diagrams.sql` 图2 | 不同贷款收入比客户的违约率对比 |
| `03_default_by_refusal_rate.csv` | `05_six_core_diagrams.sql` 图3 | 历史拒贷率与当前违约率关系 |
| `04_default_by_overdue_band.csv` | `05_six_core_diagrams.sql` 图4 | 平均逾期天数分组下的违约率表现 |
| `05_risk_level_distribution.csv` | `05_six_core_diagrams.sql` 图5 | 客户风险分层结构分布 |
| `06_default_by_risk_level.csv` | `05_six_core_diagrams.sql` 图6 | 不同风险层级客户违约率对比 |
| `07_high_risk_customer_list.csv` | `05_six_core_diagrams.sql` 补充 | 高风险客户名单 |
| `agg_customer_risk_profile.csv` | `03_build_agg_profile.sql` | 客户风险汇总宽表全量导出 |

## 导出方法

在 MySQL Workbench 中执行对应 SQL 后，可通过菜单 **Result Grid → Export** 导出为 CSV。

命令行导出示例：

```sql
SELECT * FROM agg_customer_risk_profile
INTO OUTFILE '/var/lib/mysql-files/agg_customer_risk_profile.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
```
