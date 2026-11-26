-- Section 06 user ratios sample; 2026-11-26, UTC+8.
-- mau/retain_1d columns are field diagnostics for Section 07, not scope approval.
WITH active AS (
    SELECT stat_date, p_date,
           SUM(dau) AS visitor_uv,
           SUM(login_visitor_cnt) AS logged_in_visitor_uv,
           SUM(mau) AS rolling_30d_visitor_uv,
           SUM(retain_1d) AS visitor_d1_retained
    FROM mc_prd.ads_pollo_user_active_daily_dip
    WHERE p_date IN ('20261030','20261031','20261124')
      AND TO_CHAR(stat_date,'yyyymmdd') = p_date
      AND client_type = '汇总'
      AND country = '汇总'
      AND borderline_tag = '汇总'
    GROUP BY stat_date, p_date
),
signup AS (
    SELECT TO_DATE(SUBSTR(CAST(register_date AS STRING),1,10),'yyyy-mm-dd') AS signup_date,
           COUNT(DISTINCT user_id) AS signup_uv
    FROM mc_prd.ads_pollo_user_profile_dfp
    WHERE p_date = '20261125'
      AND is_registered = 1
      AND COALESCE(is_internal_user_da,0) <> 1
      AND TO_CHAR(register_date,'yyyymmdd') IN ('20261030','20261031','20261124')
    GROUP BY TO_DATE(SUBSTR(CAST(register_date AS STRING),1,10),'yyyy-mm-dd')
)
SELECT a.p_date,
       a.visitor_uv,
       a.logged_in_visitor_uv,
       s.signup_uv,
       CAST(s.signup_uv AS DOUBLE) / NULLIF(a.visitor_uv,0) AS visitor_signup_rate,
       CAST(a.logged_in_visitor_uv AS DOUBLE) / NULLIF(a.visitor_uv,0) AS visitor_login_share,
       a.rolling_30d_visitor_uv,
       a.visitor_d1_retained,
       CAST(a.visitor_d1_retained AS DOUBLE) / NULLIF(a.visitor_uv,0) AS visitor_d1_retention
FROM active a
LEFT JOIN signup s ON a.stat_date = CAST(s.signup_date AS DATE)
ORDER BY a.p_date
