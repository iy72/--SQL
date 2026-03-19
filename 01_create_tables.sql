-- =====================================================
-- 基于 MySQL 的消费信贷信用风险分层分析
-- =====================================================

DROP DATABASE IF EXISTS credit_risk_demo;
CREATE DATABASE credit_risk_demo;#建立数据库
USE credit_risk_demo;

-- =====================================================
-- 1. 建表
-- =====================================================

DROP TABLE IF EXISTS agg_customer_risk_profile;
DROP TABLE IF EXISTS fact_credit_card_balance;
DROP TABLE IF EXISTS fact_bureau_credit;
DROP TABLE IF EXISTS fact_installment_payment;
DROP TABLE IF EXISTS fact_previous_application;
DROP TABLE IF EXISTS dim_customer;

CREATE TABLE dim_customer (
    customer_id BIGINT PRIMARY KEY,
    contract_type VARCHAR(50),
    gender VARCHAR(10),
    car_flag CHAR(1),
    realty_flag CHAR(1),
    children_cnt INT,
    income_total DECIMAL(12,2),
    credit_amount DECIMAL(12,2),
    annuity_amount DECIMAL(12,2),
    goods_price DECIMAL(12,2),
    income_type VARCHAR(50),
    education_type VARCHAR(50),
    family_status VARCHAR(50),
    housing_type VARCHAR(50),
    days_birth INT,
    days_employed INT,
    region_rating INT,
    target_default INT
);

CREATE TABLE fact_previous_application (
    prev_app_id BIGINT PRIMARY KEY,
    customer_id BIGINT,
    contract_type VARCHAR(50),
    loan_purpose VARCHAR(100),
    applied_amount DECIMAL(12,2),
    approved_amount DECIMAL(12,2),
    goods_price DECIMAL(12,2),
    annuity_amount DECIMAL(12,2),
    application_status VARCHAR(50),
    decision_days INT,
    payment_type VARCHAR(50),
    client_type VARCHAR(50),
    rate_down_payment DECIMAL(8,4),
    FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id)
);

CREATE TABLE fact_installment_payment (
    installment_id BIGINT PRIMARY KEY,
    prev_app_id BIGINT,
    customer_id BIGINT,
    installment_number INT,
    scheduled_days INT,
    actual_payment_days INT,
    scheduled_amount DECIMAL(12,2),
    actual_payment_amount DECIMAL(12,2),
    FOREIGN KEY (prev_app_id) REFERENCES fact_previous_application(prev_app_id),
    FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id)
);

CREATE TABLE fact_bureau_credit (
    bureau_id BIGINT PRIMARY KEY,
    customer_id BIGINT,
    credit_active_status VARCHAR(30),
    credit_type VARCHAR(100),
    days_credit INT,
    days_credit_enddate INT,
    days_enddate_fact INT,
    credit_day_overdue INT,
    amt_credit_sum DECIMAL(12,2),
    amt_credit_sum_debt DECIMAL(12,2),
    amt_credit_sum_overdue DECIMAL(12,2),
    amt_annuity DECIMAL(12,2),
    FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id)
);

CREATE TABLE fact_credit_card_balance (
    card_record_id BIGINT PRIMARY KEY,
    prev_app_id BIGINT,
    customer_id BIGINT,
    month_balance INT,
    amt_balance DECIMAL(12,2),
    amt_credit_limit_actual DECIMAL(12,2),
    amt_drawings_current DECIMAL(12,2),
    amt_payment_total_current DECIMAL(12,2),
    amt_receivable_principal DECIMAL(12,2),
    sk_dpd INT,
    sk_dpd_def INT,
    FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id)
);

CREATE TABLE agg_customer_risk_profile (
    customer_id BIGINT PRIMARY KEY,
    target_default INT,
    income_total DECIMAL(12,2),
    credit_amount DECIMAL(12,2),
    annuity_amount DECIMAL(12,2),
    loan_to_income_ratio DECIMAL(10,4),
    annuity_to_income_ratio DECIMAL(10,4),
    prev_app_count INT,
    prev_approved_count INT,
    prev_refused_count INT,
    prev_refusal_rate DECIMAL(10,4),
    avg_days_past_due DECIMAL(10,2),
    max_days_past_due INT,
    late_payment_count INT,
    late_payment_rate DECIMAL(10,4),
    bureau_active_loan_count INT,
    bureau_overdue_count INT,
    bureau_total_debt DECIMAL(12,2),
    bureau_total_overdue DECIMAL(12,2),
    avg_card_utilization_ratio DECIMAL(10,4),
    max_card_dpd INT,
    risk_score INT,
    risk_level VARCHAR(20)
);
