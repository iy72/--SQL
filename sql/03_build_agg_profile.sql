-- =====================================================
-- 3. 生成客户风险汇总宽表
-- =====================================================

INSERT INTO agg_customer_risk_profile
SELECT
    c.customer_id,
    c.target_default,
    c.income_total,
    c.credit_amount,
    c.annuity_amount,
    ROUND(c.credit_amount / NULLIF(c.income_total, 0), 4) AS loan_to_income_ratio,
    ROUND(c.annuity_amount / NULLIF(c.income_total, 0), 4) AS annuity_to_income_ratio,

    COALESCE(p.prev_app_count, 0) AS prev_app_count,
    COALESCE(p.prev_approved_count, 0) AS prev_approved_count,
    COALESCE(p.prev_refused_count, 0) AS prev_refused_count,
    COALESCE(p.prev_refusal_rate, 0) AS prev_refusal_rate,

    COALESCE(i.avg_days_past_due, 0) AS avg_days_past_due,
    COALESCE(i.max_days_past_due, 0) AS max_days_past_due,
    COALESCE(i.late_payment_count, 0) AS late_payment_count,
    COALESCE(i.late_payment_rate, 0) AS late_payment_rate,

    COALESCE(b.bureau_active_loan_count, 0) AS bureau_active_loan_count,
    COALESCE(b.bureau_overdue_count, 0) AS bureau_overdue_count,
    COALESCE(b.bureau_total_debt, 0) AS bureau_total_debt,
    COALESCE(b.bureau_total_overdue, 0) AS bureau_total_overdue,

    COALESCE(cc.avg_card_utilization_ratio, 0) AS avg_card_utilization_ratio,
    COALESCE(cc.max_card_dpd, 0) AS max_card_dpd,

    NULL AS risk_score,
    NULL AS risk_level
FROM dim_customer c
LEFT JOIN (
    SELECT
        customer_id,
        COUNT(*) AS prev_app_count,
        SUM(CASE WHEN application_status = 'Approved' THEN 1 ELSE 0 END) AS prev_approved_count,
        SUM(CASE WHEN application_status = 'Refused' THEN 1 ELSE 0 END) AS prev_refused_count,
        ROUND(
            SUM(CASE WHEN application_status = 'Refused' THEN 1 ELSE 0 END) / COUNT(*),
            4
        ) AS prev_refusal_rate
    FROM fact_previous_application
    GROUP BY customer_id
) p ON c.customer_id = p.customer_id
LEFT JOIN (
    SELECT
        customer_id,
        ROUND(AVG(GREATEST(actual_payment_days - scheduled_days, 0)), 2) AS avg_days_past_due,
        MAX(GREATEST(actual_payment_days - scheduled_days, 0)) AS max_days_past_due,
        SUM(CASE WHEN actual_payment_days > scheduled_days THEN 1 ELSE 0 END) AS late_payment_count,
        ROUND(
            SUM(CASE WHEN actual_payment_days > scheduled_days THEN 1 ELSE 0 END) / COUNT(*),
            4
        ) AS late_payment_rate
    FROM fact_installment_payment
    GROUP BY customer_id
) i ON c.customer_id = i.customer_id
LEFT JOIN (
    SELECT
        customer_id,
        SUM(CASE WHEN credit_active_status = 'Active' THEN 1 ELSE 0 END) AS bureau_active_loan_count,
        SUM(CASE WHEN credit_day_overdue > 0 OR amt_credit_sum_overdue > 0 THEN 1 ELSE 0 END) AS bureau_overdue_count,
        ROUND(SUM(amt_credit_sum_debt), 2) AS bureau_total_debt,
        ROUND(SUM(amt_credit_sum_overdue), 2) AS bureau_total_overdue
    FROM fact_bureau_credit
    GROUP BY customer_id
) b ON c.customer_id = b.customer_id
LEFT JOIN (
    SELECT
        customer_id,
        ROUND(AVG(
            CASE
                WHEN amt_credit_limit_actual > 0 THEN amt_balance / amt_credit_limit_actual
                ELSE 0
            END
        ), 4) AS avg_card_utilization_ratio,
        MAX(sk_dpd) AS max_card_dpd
    FROM fact_credit_card_balance
    GROUP BY customer_id
) cc ON c.customer_id = cc.customer_id;
