-- K-112 续费金额与用户续订率；Section12 DS已确认，执行证据另存。
-- 财务续费金额：renew_same_day_amount_usd / renew_7d_amount_usd，单位USD，无分母。
-- 续订率：续订用户/到期用户；财务含自动、升级、重置、降级；自动续订另列，不混用。
-- 参数start_date/end_date/as_of_date为yyyymmdd；到期日cohort，五个CUBE维度全部ALL。
-- 当日窗[到期-1,到期]；7日窗[到期-1,到期+7]；7日仅汇总已成熟日期，输出实际日期与天数。
-- 期间人数为用户·天，不是跨期间去重；零分母NULL。金额不是金额比率，不自行除以应续金额。
WITH base AS (
    SELECT p_date, is_7d_closed, expire_user_cnt,
           renew_same_day_user_cnt, renew_7d_user_cnt,
           renew_same_day_amount_usd, renew_7d_amount_usd,
           renew_same_day_auto_user_cnt, renew_7d_auto_user_cnt,
           renew_same_day_auto_amount_usd, renew_7d_auto_amount_usd
    FROM mc_prd.ads_pollo_transaction_renewal_cohort_daily_dip
    WHERE p_date BETWEEN '20261030' AND '20261031'
      AND TO_CHAR(stat_date,'yyyymmdd') BETWEEN '20261030' AND '20261031'
      AND p_date = TO_CHAR(stat_date,'yyyymmdd')
      AND p_date <= TO_CHAR(DATEADD(TO_DATE('20261127','yyyymmdd'),-1,'dd'),'yyyymmdd')
      AND platform_type='ALL' AND plan_cycle='ALL' AND plan_tier='ALL'
      AND renew_stage='ALL' AND borderline_tag='ALL'
)
SELECT 'same_day' AS window_name, MIN(p_date) AS first_expiry_date, MAX(p_date) AS last_expiry_date,
       COUNT(DISTINCT p_date) AS cohort_day_count, SUM(expire_user_cnt) AS expire_user_days,
       SUM(renew_same_day_amount_usd) AS renewal_amount_usd,
       SUM(renew_same_day_user_cnt) AS renewal_user_days,
       CAST(SUM(renew_same_day_user_cnt) AS DOUBLE)/NULLIF(SUM(expire_user_cnt),0) AS user_renewal_rate,
       SUM(renew_same_day_auto_amount_usd) AS auto_renewal_amount_usd,
       SUM(renew_same_day_auto_user_cnt) AS auto_renewal_user_days,
       CAST(SUM(renew_same_day_auto_user_cnt) AS DOUBLE)/NULLIF(SUM(expire_user_cnt),0) AS auto_user_renewal_rate
FROM base
UNION ALL
SELECT '7d' AS window_name, MIN(p_date) AS first_expiry_date, MAX(p_date) AS last_expiry_date,
       COUNT(DISTINCT p_date) AS cohort_day_count, SUM(expire_user_cnt) AS expire_user_days,
       SUM(renew_7d_amount_usd) AS renewal_amount_usd, SUM(renew_7d_user_cnt) AS renewal_user_days,
       CAST(SUM(renew_7d_user_cnt) AS DOUBLE)/NULLIF(SUM(expire_user_cnt),0) AS user_renewal_rate,
       SUM(renew_7d_auto_amount_usd) AS auto_renewal_amount_usd,
       SUM(renew_7d_auto_user_cnt) AS auto_renewal_user_days,
       CAST(SUM(renew_7d_auto_user_cnt) AS DOUBLE)/NULLIF(SUM(expire_user_cnt),0) AS auto_user_renewal_rate
FROM base WHERE is_7d_closed=1
ORDER BY window_name;
