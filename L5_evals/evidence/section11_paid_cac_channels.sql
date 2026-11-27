-- K-110 Web广告渠道CAC（当日/期间注册口径）；M-AD-014；status: pending_review。
-- 业务公式已由Section11 DS回复确认；本模板尚未远程核验，不标注为已核验结果。
-- 成本按花费日、注册按注册日，按同一日期和ad_platform对应；不是投放日D0注册口径。
-- 复用已纳入的注册日表T-008：cohort_user_cnt只含广告归因注册，不含自然注册。
-- start_date/end_date/as_of_date均为yyyymmdd；默认截到T-2。金额USD，分母0/NULL返回NULL。
-- 保留全部match_level；只取总产品/总首购主行。先汇总渠道成本与渠道注册再相除。
-- 当前按ad_platform输出，如google、bing；SEM/信息流大类的映射另查，不能混用。
WITH channel_totals AS (
    SELECT LOWER(ad_platform) AS ad_platform, MIN(p_date) AS period_start,
           MAX(p_date) AS period_end, SUM(cost_usd) AS cost_usd,
           SUM(cohort_user_cnt) AS channel_signup_uv
    FROM mc_prd.ads_pollo_ad_attribution_daily_dip
    WHERE p_date BETWEEN '20261030' AND '20261031'
      AND TO_CHAR(stat_date,'yyyymmdd') BETWEEN '20261030' AND '20261031'
      AND p_date = TO_CHAR(stat_date,'yyyymmdd')
      AND p_date <= TO_CHAR(DATEADD(TO_DATE('20261127','yyyymmdd'),-2,'dd'),'yyyymmdd')
      AND source_end = 'WEB'
      AND product_type = 'ALL' AND is_first_purchase = '汇总'
    GROUP BY LOWER(ad_platform)
)
SELECT ad_platform, period_start, period_end, cost_usd, channel_signup_uv,
       CAST(cost_usd AS DOUBLE)/NULLIF(channel_signup_uv,0) AS channel_cac_usd
FROM channel_totals ORDER BY ad_platform;
