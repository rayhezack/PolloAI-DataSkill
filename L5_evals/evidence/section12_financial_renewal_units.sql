-- K-111 财务续费率按用户/订阅对照；pending_review；供Section12业务单位评审。
-- M-PAY-021当前按用户草案；订阅口径只作对照，DS确认前不自动替换。
-- 表T-003；到期cohort；业务所谓7日窗口为[到期-1,到期+7]，沿用已确认定义。
-- 五个CUBE维度全部ALL，避免重复；只算is_7d_closed=1。
-- 期间用户数按各日汇总为用户·天，订阅数为各到期日的订阅计数，不宣称期间去重用户。
SELECT MIN(p_date) AS first_expiry_date, MAX(p_date) AS last_expiry_date,
       COUNT(DISTINCT p_date) AS mature_day_count,
       SUM(expire_user_cnt) AS expire_user_days,
       SUM(renew_7d_user_cnt) AS financial_renew_user_days,
       SUM(expire_sub_cnt) AS expire_sub_cnt,
       SUM(renew_7d_sub_cnt) AS financial_renew_sub_cnt,
       SUM(renew_7d_auto_user_cnt) AS auto_renew_user_days,
       CAST(SUM(renew_7d_user_cnt) AS DOUBLE)/NULLIF(SUM(expire_user_cnt),0) AS financial_user_rate,
       CAST(SUM(renew_7d_sub_cnt) AS DOUBLE)/NULLIF(SUM(expire_sub_cnt),0) AS financial_subscription_rate,
       CAST(SUM(renew_7d_auto_user_cnt) AS DOUBLE)/NULLIF(SUM(expire_user_cnt),0) AS business_auto_user_rate
FROM mc_prd.ads_pollo_transaction_renewal_cohort_daily_dip
WHERE p_date BETWEEN '20261030' AND '20261031'
  AND TO_CHAR(stat_date,'yyyymmdd') BETWEEN '20261030' AND '20261031'
  AND p_date = TO_CHAR(stat_date,'yyyymmdd')
  AND platform_type='ALL' AND plan_cycle='ALL' AND plan_tier='ALL'
  AND renew_stage='ALL' AND borderline_tag='ALL'
  AND is_7d_closed=1;
