-- =====================================================
-- 6. 六张核心图的出数 SQL
-- =====================================================

-- 图1：消费信贷资产组合违约概览
SELECT
    COUNT(*) AS total_customers,
    SUM(target_default) AS default_customers,
    ROUND(AVG(target_default) * 100, 2) AS default_rate_pct,
    ROUND(AVG(credit_amount), 2) AS avg_credit_amount,
    ROUND(AVG(income_total), 2) AS avg_income_total,
    ROUND(AVG(loan_to_income_ratio), 4) AS avg_loan_to_income_ratio
FROM agg_customer_risk_profile;

-- 图2：不同贷款收入比客户的违约率对比
SELECT
    CASE
        WHEN loan_to_income_ratio < 0.8 THEN '<0.8'
        WHEN loan_to_income_ratio < 1.0 THEN '0.8-1.0'
        WHEN loan_to_income_ratio < 1.2 THEN '1.0-1.2'
        ELSE '1.2+'
    END AS lti_band,
    COUNT(*) AS customer_cnt,
    ROUND(AVG(target_default) * 100, 2) AS default_rate_pct
FROM agg_customer_risk_profile
GROUP BY lti_band
ORDER BY
    CASE lti_band
        WHEN '<0.8' THEN 1
        WHEN '0.8-1.0' THEN 2
        WHEN '1.0-1.2' THEN 3
        ELSE 4
    END;

-- 图3：历史拒贷率与当前违约率关系
SELECT
    CASE
        WHEN prev_refusal_rate = 0 THEN '0%'
        WHEN prev_refusal_rate <= 0.25 THEN '0%-25%'
        WHEN prev_refusal_rate <= 0.50 THEN '25%-50%'
        ELSE '50%+'
    END AS refusal_band,
    COUNT(*) AS customer_cnt,
    ROUND(AVG(target_default) * 100, 2) AS default_rate_pct
FROM agg_customer_risk_profile
GROUP BY refusal_band
ORDER BY
    CASE refusal_band
        WHEN '0%' THEN 1
        WHEN '0%-25%' THEN 2
        WHEN '25%-50%' THEN 3
        ELSE 4
    END;

-- 图4：平均逾期天数分组下的违约率表现
SELECT
    CASE
        WHEN avg_days_past_due = 0 THEN '0天'
        WHEN avg_days_past_due <= 3 THEN '1-3天'
        WHEN avg_days_past_due <= 10 THEN '4-10天'
        ELSE '10天以上'
    END AS overdue_band,
    COUNT(*) AS customer_cnt,
    ROUND(AVG(target_default) * 100, 2) AS default_rate_pct
FROM agg_customer_risk_profile
GROUP BY overdue_band
ORDER BY
    CASE overdue_band
        WHEN '0天' THEN 1
        WHEN '1-3天' THEN 2
        WHEN '4-10天' THEN 3
        ELSE 4
    END;

-- 图5：客户风险分层结构分布
SELECT
    risk_level,
    COUNT(*) AS customer_cnt,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM agg_customer_risk_profile), 2) AS customer_pct
FROM agg_customer_risk_profile
GROUP BY risk_level
ORDER BY
    CASE risk_level
        WHEN 'High Risk' THEN 1
        WHEN 'Medium Risk' THEN 2
        WHEN 'Low Risk' THEN 3
        ELSE 4
    END;

-- 图6：不同风险层级客户违约率对比
SELECT
    risk_level,
    COUNT(*) AS customer_cnt,
    ROUND(AVG(target_default) * 100, 2) AS default_rate_pct,
    ROUND(AVG(credit_amount), 2) AS avg_credit_amount
FROM agg_customer_risk_profile
GROUP BY risk_level
ORDER BY
    CASE risk_level
        WHEN 'High Risk' THEN 1
        WHEN 'Medium Risk' THEN 2
        WHEN 'Low Risk' THEN 3
        ELSE 4
    END;

-- =====================================================
-- 7. 补充：高风险客户名单
-- =====================================================

SELECT
    customer_id,
    income_total,
    credit_amount,
    loan_to_income_ratio,
    prev_refusal_rate,
    avg_days_past_due,
    bureau_total_overdue,
    avg_card_utilization_ratio,
    risk_score,
    risk_level
FROM agg_customer_risk_profile
WHERE risk_level = 'High Risk'
ORDER BY risk_score DESC, loan_to_income_ratio DESC
LIMIT 20;