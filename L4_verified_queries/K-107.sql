-- K-107 Web付费渠道大盘CAC；status: pilot；M-AD-007；2026-11-27最新DS纠正。
-- 全部Web付费渠道成本合计 / 全部Web付费渠道注册人数合计；不含自然渠道注册。
-- 复用T-008注册日表，与渠道CAC K-110使用同一批成本和注册，只改变汇总层级。
-- 成本按花费日、注册按注册日；不是投放日D0注册，也不使用T-009全Web注册。
-- start_date/end_date/as_of_date为yyyymmdd；仅Web、截到T-2；本版生产样本见section11_paid_cac_total_result.json。
-- 主行固定ALL/汇总，保留全部match_level；付费渠道覆盖沿用表内广告归因定义。
-- 输出每日及期间合计；期间用总成本/总付费注册，不平均每日或渠道CAC；零分母返回NULL。
-- 若有渠道注册而成本为NULL，需随结果标明成本覆盖缺口；NULL不等于0，不宣称完整成本已齐。
WITH daily AS (
    SELECT p_date AS stat_date, SUM(cost_usd) AS cost_usd,
           SUM(cohort_user_cnt) AS paid_signup_uv
    FROM mc_prd.ads_pollo_ad_attribution_daily_dip
    WHERE p_date BETWEEN '${start_date}' AND '${end_date}'
      AND TO_CHAR(stat_date,'yyyymmdd') BETWEEN '${start_date}' AND '${end_date}'
      AND p_date = TO_CHAR(stat_date,'yyyymmdd')
      AND p_date <= TO_CHAR(DATEADD(TO_DATE('${as_of_date}','yyyymmdd'),-2,'dd'),'yyyymmdd')
      AND source_end = 'WEB'
      AND product_type = 'ALL' AND is_first_purchase = '汇总'
    GROUP BY p_date
)
SELECT 'daily' AS row_type, stat_date AS period_start, stat_date AS period_end,
       cost_usd, paid_signup_uv,
       CAST(cost_usd AS DOUBLE)/NULLIF(paid_signup_uv,0) AS cac_usd
FROM daily
UNION ALL
SELECT 'period_total' AS row_type, MIN(stat_date) AS period_start, MAX(stat_date) AS period_end,
       SUM(cost_usd) AS cost_usd, SUM(paid_signup_uv) AS paid_signup_uv,
       CASE WHEN COUNT(*)=COUNT(cost_usd) AND COUNT(*)=COUNT(paid_signup_uv)
            THEN CAST(SUM(cost_usd) AS DOUBLE)/NULLIF(SUM(paid_signup_uv),0)
            ELSE NULL END AS cac_usd
FROM daily
ORDER BY row_type, period_start;
