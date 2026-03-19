-- =====================================================
-- 2. 插入示例数据（100 个客户）
-- =====================================================

INSERT INTO dim_customer
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 100
)
SELECT
    n AS customer_id,
    CASE WHEN MOD(n, 2) = 0 THEN 'Cash loans' ELSE 'Revolving loans' END AS contract_type,
    CASE WHEN MOD(n, 2) = 0 THEN 'M' ELSE 'F' END AS gender,
    CASE WHEN MOD(n, 3) = 0 THEN 'Y' ELSE 'N' END AS car_flag,
    CASE WHEN MOD(n, 4) IN (0, 1) THEN 'Y' ELSE 'N' END AS realty_flag,
    MOD(n, 4) AS children_cnt,
    80000 + n * 2500 AS income_total,
    50000 + n * 1800 AS credit_amount,
    ROUND((50000 + n * 1800) / 12, 2) AS annuity_amount,
    45000 + n * 1600 AS goods_price,
    CASE
        WHEN MOD(n, 4) = 0 THEN 'Working'
        WHEN MOD(n, 4) = 1 THEN 'Commercial associate'
        WHEN MOD(n, 4) = 2 THEN 'Pensioner'
        ELSE 'State servant'
    END AS income_type,
    CASE
        WHEN MOD(n, 3) = 0 THEN 'Higher education'
        WHEN MOD(n, 3) = 1 THEN 'Secondary'
        ELSE 'Incomplete higher'
    END AS education_type,
    CASE
        WHEN MOD(n, 3) = 0 THEN 'Married'
        WHEN MOD(n, 3) = 1 THEN 'Single'
        ELSE 'Separated'
    END AS family_status,
    CASE
        WHEN MOD(n, 3) = 0 THEN 'House / apartment'
        WHEN MOD(n, 3) = 1 THEN 'Rented apartment'
        ELSE 'With parents'
    END AS housing_type,
    -(22 + MOD(n, 25)) * 365 AS days_birth,
    -(1 + MOD(n, 20)) * 365 AS days_employed,
    1 + MOD(n, 3) AS region_rating,
    CASE
        WHEN MOD(n, 10) IN (0, 1, 2) THEN 1
        ELSE 0
    END AS target_default
FROM seq;

-- 历史申请表：每个客户 1 条，共 100 条
INSERT INTO fact_previous_application
SELECT
    1000 + customer_id AS prev_app_id,
    customer_id,
    'Cash loans' AS contract_type,
    CASE
        WHEN MOD(customer_id, 4) = 0 THEN 'Car'
        WHEN MOD(customer_id, 4) = 1 THEN 'Education'
        WHEN MOD(customer_id, 4) = 2 THEN 'Repairs'
        ELSE 'Consumer goods'
    END AS loan_purpose,
    credit_amount * 1.05 AS applied_amount,
    credit_amount * 0.95 AS approved_amount,
    goods_price,
    annuity_amount,
    CASE
        WHEN MOD(customer_id, 5) = 0 THEN 'Refused'
        WHEN MOD(customer_id, 7) = 0 THEN 'Canceled'
        ELSE 'Approved'
    END AS application_status,
    -30 * MOD(customer_id, 24) AS decision_days,
    CASE
        WHEN MOD(customer_id, 2) = 0 THEN 'Cash through the bank'
        ELSE 'Non-cash'
    END AS payment_type,
    CASE
        WHEN MOD(customer_id, 3) = 0 THEN 'New'
        ELSE 'Repeater'
    END AS client_type,
    ROUND(MOD(customer_id, 20) / 100, 4) AS rate_down_payment
FROM dim_customer;

-- 额外加 20 条历史申请，让部分客户有多次申请
INSERT INTO fact_previous_application
SELECT
    2000 + customer_id AS prev_app_id,
    customer_id,
    'Cash loans' AS contract_type,
    'Consumer goods' AS loan_purpose,
    credit_amount * 0.80 AS applied_amount,
    credit_amount * 0.75 AS approved_amount,
    goods_price * 0.90 AS goods_price,
    annuity_amount * 0.80 AS annuity_amount,
    CASE
        WHEN MOD(customer_id, 4) = 0 THEN 'Refused'
        ELSE 'Approved'
    END AS application_status,
    -15 * MOD(customer_id, 12) AS decision_days,
    'Non-cash' AS payment_type,
    'Repeater' AS client_type,
    0.0500 AS rate_down_payment
FROM dim_customer
WHERE customer_id <= 20;

-- 分期还款表：每条历史申请生成 2 条还款记录
INSERT INTO fact_installment_payment
SELECT
    prev_app_id * 10 + 1 AS installment_id,
    prev_app_id,
    customer_id,
    1 AS installment_number,
    -60 AS scheduled_days,
    -60 + CASE
        WHEN MOD(customer_id, 10) IN (0,1,2) THEN 10
        WHEN MOD(customer_id, 10) IN (3,4) THEN 3
        ELSE 0
    END AS actual_payment_days,
    annuity_amount AS scheduled_amount,
    annuity_amount - CASE
        WHEN MOD(customer_id, 10) IN (0,1) THEN 300
        ELSE 0
    END AS actual_payment_amount
FROM fact_previous_application;

INSERT INTO fact_installment_payment
SELECT
    prev_app_id * 10 + 2 AS installment_id,
    prev_app_id,
    customer_id,
    2 AS installment_number,
    -30 AS scheduled_days,
    -30 + CASE
        WHEN MOD(customer_id, 10) IN (0,1,2) THEN 15
        WHEN MOD(customer_id, 10) IN (3,4) THEN 5
        ELSE 0
    END AS actual_payment_days,
    annuity_amount AS scheduled_amount,
    annuity_amount - CASE
        WHEN MOD(customer_id, 10) IN (0,1) THEN 500
        ELSE 0
    END AS actual_payment_amount
FROM fact_previous_application;

-- 外部征信表：每个客户 1 条
INSERT INTO fact_bureau_credit
SELECT
    3000 + customer_id AS bureau_id,
    customer_id,
    CASE
        WHEN MOD(customer_id, 3) = 0 THEN 'Active'
        ELSE 'Closed'
    END AS credit_active_status,
    CASE
        WHEN MOD(customer_id, 2) = 0 THEN 'Consumer credit'
        ELSE 'Credit card'
    END AS credit_type,
    -100 * MOD(customer_id, 12) AS days_credit,
    120 * MOD(customer_id, 10) AS days_credit_enddate,
    100 * MOD(customer_id, 8) AS days_enddate_fact,
    CASE
        WHEN MOD(customer_id, 10) IN (0,1,2) THEN 20
        WHEN MOD(customer_id, 10) IN (3,4) THEN 5
        ELSE 0
    END AS credit_day_overdue,
    20000 + customer_id * 1000 AS amt_credit_sum,
    CASE
        WHEN MOD(customer_id, 10) IN (0,1,2) THEN 30000 + customer_id * 800
        ELSE 10000 + customer_id * 500
    END AS amt_credit_sum_debt,
    CASE
        WHEN MOD(customer_id, 10) IN (0,1,2) THEN 2000 + customer_id * 30
        WHEN MOD(customer_id, 10) IN (3,4) THEN 500 + customer_id * 10
        ELSE 0
    END AS amt_credit_sum_overdue,
    1000 + customer_id * 20 AS amt_annuity
FROM dim_customer;

-- 信用卡行为表：每个客户 1 条
INSERT INTO fact_credit_card_balance
SELECT
    4000 + customer_id AS card_record_id,
    1000 + customer_id AS prev_app_id,
    customer_id,
    -1 AS month_balance,
    CASE
        WHEN MOD(customer_id, 10) IN (0,1,2) THEN 20000 + customer_id * 300
        WHEN MOD(customer_id, 10) IN (3,4) THEN 12000 + customer_id * 200
        ELSE 5000 + customer_id * 100
    END AS amt_balance,
    CASE
        WHEN MOD(customer_id, 10) IN (0,1,2) THEN 22000 + customer_id * 300
        WHEN MOD(customer_id, 10) IN (3,4) THEN 20000 + customer_id * 250
        ELSE 25000 + customer_id * 200
    END AS amt_credit_limit_actual,
    1000 + customer_id * 20 AS amt_drawings_current,
    800 + customer_id * 15 AS amt_payment_total_current,
    500 + customer_id * 10 AS amt_receivable_principal,
    CASE
        WHEN MOD(customer_id, 10) IN (0,1,2) THEN 25
        WHEN MOD(customer_id, 10) IN (3,4) THEN 7
        ELSE 0
    END AS sk_dpd,
    CASE
        WHEN MOD(customer_id, 10) IN (0,1,2) THEN 20
        WHEN MOD(customer_id, 10) IN (3,4) THEN 5
        ELSE 0
    END AS sk_dpd_def
FROM dim_customer;