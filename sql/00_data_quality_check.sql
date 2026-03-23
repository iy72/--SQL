-- =====================================================
-- 基于 MySQL 的消费信贷信用风险分层分析
-- 0. 数据质量检查与预处理
-- =====================================================
-- 说明：本脚本在正式建表、插入数据之前执行数据质量检查，
--       涵盖：缺失值检查、主键重复检查、数值字段异常值识别、
--             无效值检查、类别字段统一 等核心预处理步骤。
--       执行顺序：00 → 01 → 02 → 03 → 04 → 05
-- =====================================================

USE credit_risk_demo;

-- =====================================================
-- 一、缺失值检查（NULL 值统计）
-- =====================================================

-- 1.1 客户主表 dim_customer 关键字段缺失检查
SELECT
    'dim_customer'                                          AS table_name,
    COUNT(*)                                                AS total_rows,
    SUM(CASE WHEN customer_id      IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN income_total     IS NULL THEN 1 ELSE 0 END) AS null_income_total,
    SUM(CASE WHEN credit_amount    IS NULL THEN 1 ELSE 0 END) AS null_credit_amount,
    SUM(CASE WHEN annuity_amount   IS NULL THEN 1 ELSE 0 END) AS null_annuity_amount,
    SUM(CASE WHEN goods_price      IS NULL THEN 1 ELSE 0 END) AS null_goods_price,
    SUM(CASE WHEN days_birth       IS NULL THEN 1 ELSE 0 END) AS null_days_birth,
    SUM(CASE WHEN days_employed    IS NULL THEN 1 ELSE 0 END) AS null_days_employed,
    SUM(CASE WHEN target_default   IS NULL THEN 1 ELSE 0 END) AS null_target_default
FROM dim_customer;

-- 1.2 历史申请表 fact_previous_application 关键字段缺失检查
SELECT
    'fact_previous_application'                             AS table_name,
    COUNT(*)                                                AS total_rows,
    SUM(CASE WHEN prev_app_id         IS NULL THEN 1 ELSE 0 END) AS null_prev_app_id,
    SUM(CASE WHEN customer_id         IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN applied_amount      IS NULL THEN 1 ELSE 0 END) AS null_applied_amount,
    SUM(CASE WHEN approved_amount     IS NULL THEN 1 ELSE 0 END) AS null_approved_amount,
    SUM(CASE WHEN application_status  IS NULL THEN 1 ELSE 0 END) AS null_application_status
FROM fact_previous_application;

-- 1.3 分期还款表 fact_installment_payment 关键字段缺失检查
SELECT
    'fact_installment_payment'                              AS table_name,
    COUNT(*)                                                AS total_rows,
    SUM(CASE WHEN installment_id            IS NULL THEN 1 ELSE 0 END) AS null_installment_id,
    SUM(CASE WHEN customer_id               IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN scheduled_days            IS NULL THEN 1 ELSE 0 END) AS null_scheduled_days,
    SUM(CASE WHEN actual_payment_days       IS NULL THEN 1 ELSE 0 END) AS null_actual_payment_days,
    SUM(CASE WHEN scheduled_amount          IS NULL THEN 1 ELSE 0 END) AS null_scheduled_amount,
    SUM(CASE WHEN actual_payment_amount     IS NULL THEN 1 ELSE 0 END) AS null_actual_payment_amount
FROM fact_installment_payment;

-- 1.4 外部征信表 fact_bureau_credit 关键字段缺失检查
SELECT
    'fact_bureau_credit'                                    AS table_name,
    COUNT(*)                                                AS total_rows,
    SUM(CASE WHEN bureau_id               IS NULL THEN 1 ELSE 0 END) AS null_bureau_id,
    SUM(CASE WHEN customer_id             IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN amt_credit_sum          IS NULL THEN 1 ELSE 0 END) AS null_amt_credit_sum,
    SUM(CASE WHEN amt_credit_sum_debt     IS NULL THEN 1 ELSE 0 END) AS null_amt_credit_sum_debt,
    SUM(CASE WHEN amt_credit_sum_overdue  IS NULL THEN 1 ELSE 0 END) AS null_amt_credit_sum_overdue
FROM fact_bureau_credit;

-- 1.5 信用卡行为表 fact_credit_card_balance 关键字段缺失检查
SELECT
    'fact_credit_card_balance'                              AS table_name,
    COUNT(*)                                                AS total_rows,
    SUM(CASE WHEN card_record_id              IS NULL THEN 1 ELSE 0 END) AS null_card_record_id,
    SUM(CASE WHEN customer_id                 IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN amt_balance                 IS NULL THEN 1 ELSE 0 END) AS null_amt_balance,
    SUM(CASE WHEN amt_credit_limit_actual     IS NULL THEN 1 ELSE 0 END) AS null_credit_limit,
    SUM(CASE WHEN amt_payment_total_current   IS NULL THEN 1 ELSE 0 END) AS null_payment_total
FROM fact_credit_card_balance;


-- =====================================================
-- 二、主键唯一性检查（重复主键检测）
-- =====================================================

-- 2.1 dim_customer 主键重复检测
SELECT 'dim_customer' AS table_name, customer_id, COUNT(*) AS cnt
FROM dim_customer
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- 2.2 fact_previous_application 主键重复检测
SELECT 'fact_previous_application' AS table_name, prev_app_id, COUNT(*) AS cnt
FROM fact_previous_application
GROUP BY prev_app_id
HAVING COUNT(*) > 1;

-- 2.3 fact_installment_payment 主键重复检测
SELECT 'fact_installment_payment' AS table_name, installment_id, COUNT(*) AS cnt
FROM fact_installment_payment
GROUP BY installment_id
HAVING COUNT(*) > 1;

-- 2.4 fact_bureau_credit 主键重复检测
SELECT 'fact_bureau_credit' AS table_name, bureau_id, COUNT(*) AS cnt
FROM fact_bureau_credit
GROUP BY bureau_id
HAVING COUNT(*) > 1;

-- 2.5 fact_credit_card_balance 主键重复检测
SELECT 'fact_credit_card_balance' AS table_name, card_record_id, COUNT(*) AS cnt
FROM fact_credit_card_balance
GROUP BY card_record_id
HAVING COUNT(*) > 1;


-- =====================================================
-- 三、数值字段异常值识别
-- =====================================================

-- 3.1 客户主表：收入、贷款金额、年金的基本统计（用于发现极端值）
SELECT
    'dim_customer'                          AS table_name,
    MIN(income_total)                       AS min_income,
    MAX(income_total)                       AS max_income,
    ROUND(AVG(income_total), 2)             AS avg_income,
    MIN(credit_amount)                      AS min_credit,
    MAX(credit_amount)                      AS max_credit,
    ROUND(AVG(credit_amount), 2)            AS avg_credit,
    MIN(annuity_amount)                     AS min_annuity,
    MAX(annuity_amount)                     AS max_annuity,
    ROUND(AVG(annuity_amount), 2)           AS avg_annuity
FROM dim_customer;

-- 3.2 收入或贷款金额为负值或零值的异常记录
SELECT customer_id, income_total, credit_amount, annuity_amount
FROM dim_customer
WHERE income_total <= 0
   OR credit_amount <= 0
   OR annuity_amount <= 0;

-- 3.3 年龄异常：days_birth 换算后，识别年龄小于 18 岁或大于 90 岁的记录
--     （days_birth 为负值，代表从申请日往前推的天数）
SELECT
    customer_id,
    days_birth,
    ROUND(ABS(days_birth) / 365, 1) AS age_years
FROM dim_customer
WHERE ABS(days_birth) / 365 < 18
   OR ABS(days_birth) / 365 > 90;

-- 3.4 就业天数异常：days_employed 为正值通常代表数据错误
--     （正常情况下应为负值，代表入职距申请日的天数）
SELECT
    customer_id,
    days_employed
FROM dim_customer
WHERE days_employed > 0;

-- 3.5 征信表：逾期金额为负值的异常记录
SELECT bureau_id, customer_id, amt_credit_sum_overdue
FROM fact_bureau_credit
WHERE amt_credit_sum_overdue < 0;

-- 3.6 信用卡表：余额超过授信额度 2 倍的异常记录（疑似数据录入错误）
SELECT
    card_record_id,
    customer_id,
    amt_balance,
    amt_credit_limit_actual,
    ROUND(amt_balance / NULLIF(amt_credit_limit_actual, 0), 4) AS utilization_ratio
FROM fact_credit_card_balance
WHERE amt_credit_limit_actual > 0
  AND amt_balance > amt_credit_limit_actual * 2;


-- =====================================================
-- 四、类别字段有效值检查
-- =====================================================

-- 4.1 dim_customer.gender 枚举检查（仅允许 'M' / 'F'）
SELECT DISTINCT gender, COUNT(*) AS cnt
FROM dim_customer
GROUP BY gender;

-- 4.2 dim_customer.contract_type 枚举检查
SELECT DISTINCT contract_type, COUNT(*) AS cnt
FROM dim_customer
GROUP BY contract_type;

-- 4.3 dim_customer.target_default 枚举检查（仅允许 0 / 1）
SELECT DISTINCT target_default, COUNT(*) AS cnt
FROM dim_customer
GROUP BY target_default;

-- 4.4 fact_previous_application.application_status 枚举检查
SELECT DISTINCT application_status, COUNT(*) AS cnt
FROM fact_previous_application
GROUP BY application_status;

-- 4.5 fact_bureau_credit.credit_active_status 枚举检查
SELECT DISTINCT credit_active_status, COUNT(*) AS cnt
FROM fact_bureau_credit
GROUP BY credit_active_status;


-- =====================================================
-- 五、外键完整性检查（孤立记录检测）
-- =====================================================

-- 5.1 历史申请表中存在但客户主表中不存在的 customer_id
SELECT pa.customer_id
FROM fact_previous_application pa
LEFT JOIN dim_customer c ON pa.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 5.2 分期还款表中存在但历史申请表中不存在的 prev_app_id
SELECT ip.prev_app_id
FROM fact_installment_payment ip
LEFT JOIN fact_previous_application pa ON ip.prev_app_id = pa.prev_app_id
WHERE pa.prev_app_id IS NULL;

-- 5.3 外部征信表中存在但客户主表中不存在的 customer_id
SELECT bc.customer_id
FROM fact_bureau_credit bc
LEFT JOIN dim_customer c ON bc.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 5.4 信用卡行为表中存在但客户主表中不存在的 customer_id
SELECT cc.customer_id
FROM fact_credit_card_balance cc
LEFT JOIN dim_customer c ON cc.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- =====================================================
-- 六、数据完整性概览（各表行数汇总）
-- =====================================================

SELECT 'dim_customer'               AS table_name, COUNT(*) AS row_count FROM dim_customer
UNION ALL
SELECT 'fact_previous_application'  AS table_name, COUNT(*) AS row_count FROM fact_previous_application
UNION ALL
SELECT 'fact_installment_payment'   AS table_name, COUNT(*) AS row_count FROM fact_installment_payment
UNION ALL
SELECT 'fact_bureau_credit'         AS table_name, COUNT(*) AS row_count FROM fact_bureau_credit
UNION ALL
SELECT 'fact_credit_card_balance'   AS table_name, COUNT(*) AS row_count FROM fact_credit_card_balance
UNION ALL
SELECT 'agg_customer_risk_profile'  AS table_name, COUNT(*) AS row_count FROM agg_customer_risk_profile;
