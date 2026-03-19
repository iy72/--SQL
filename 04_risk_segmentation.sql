-- =====================================================
-- 4. 风险评分与分层
-- =====================================================

UPDATE agg_customer_risk_profile
SET risk_score =
      (CASE
          WHEN loan_to_income_ratio >= 1.5 THEN 25
          WHEN loan_to_income_ratio >= 1.0 THEN 15
          ELSE 5
       END)
    + (CASE
          WHEN prev_refusal_rate > 0.5 THEN 20
          WHEN prev_refusal_rate > 0.25 THEN 10
          ELSE 0
       END)
    + (CASE
          WHEN avg_days_past_due > 10 THEN 25
          WHEN avg_days_past_due > 3 THEN 15
          WHEN avg_days_past_due > 0 THEN 8
          ELSE 0
       END)
    + (CASE
          WHEN bureau_total_overdue > 1500 THEN 15
          WHEN bureau_total_overdue > 0 THEN 8
          ELSE 0
       END)
    + (CASE
          WHEN avg_card_utilization_ratio > 0.8 THEN 15
          WHEN avg_card_utilization_ratio > 0.5 THEN 8
          ELSE 0
       END);

UPDATE agg_customer_risk_profile
SET risk_level = CASE
    WHEN risk_score >= 60 THEN 'High Risk'
    WHEN risk_score >= 35 THEN 'Medium Risk'
    ELSE 'Low Risk'
END;
-- =====================================================
-- 5. 先看汇总结果
-- =====================================================

SELECT * FROM agg_customer_risk_profile ORDER BY customer_id LIMIT 20;