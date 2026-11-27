-- K-109 Web投放日LTV与ROAS；status: pending_review；Section10 DS公式已确认。
-- M-AD-001/005/006/013；金额USD；LTV为USD/D0广告归因注册用户，ROAS为比值（1=100%）。
-- 参数start_date/end_date/as_of_date为yyyymmdd；window仅允许0/14/30/60/90/180/360/all。
-- 先固定同一批成熟投放日期，再分别汇总成本、GMV_N、D0注册；不计算ROI。
-- window=all表示截至观测日累计，仍截到T-2，不称完整终身价值。
-- 单次只算一个窗口；比较多窗口曲线时，end_date应统一到最大N的成熟截止日。
-- 本模板限Web可比归因平台；不用于大盘CAC，CAC另用K-107（全Web成本/全Web注册）。
WITH base AS (
    SELECT p_date, LOWER(ad_platform) AS ad_platform, cost_usd, reg_user_cnt_d0,
           CASE '30'
             WHEN '0' THEN gmv_usd_d0 WHEN '14' THEN gmv_usd_d14
             WHEN '30' THEN gmv_usd_d30 WHEN '60' THEN gmv_usd_d60
             WHEN '90' THEN gmv_usd_d90 WHEN '180' THEN gmv_usd_d180
             WHEN '360' THEN gmv_usd_d360 WHEN 'all' THEN gmv_usd_all
           END AS gmv_usd_n
    FROM mc_prd.ads_pollo_ad_attribution_delivery_daily_hip
    WHERE p_date BETWEEN '20261001' AND '20261027'
      AND TO_CHAR(stat_date, 'yyyymmdd') BETWEEN '20261001' AND '20261027'
      AND p_date = TO_CHAR(stat_date, 'yyyymmdd')
      AND source_end = 'WEB'
      AND LOWER(ad_platform) IN ('google','bing','yahoo','naver')
      AND p_date <= TO_CHAR(DATEADD(TO_DATE('20261127','yyyymmdd'),-2,'dd'),'yyyymmdd')
      AND p_date <= TO_CHAR(DATEADD(TO_DATE('20261127','yyyymmdd'),
          CASE '30' WHEN '0' THEN -1 WHEN '14' THEN -15 WHEN '30' THEN -31
            WHEN '60' THEN -61 WHEN '90' THEN -91 WHEN '180' THEN -181
            WHEN '360' THEN -361 WHEN 'all' THEN -2 END,'dd'),'yyyymmdd')
), totals AS (
    SELECT ad_platform, MIN(p_date) AS first_delivery_date, MAX(p_date) AS last_delivery_date,
           COUNT(DISTINCT p_date) AS delivery_day_count,
           SUM(cost_usd) AS cost_usd, SUM(reg_user_cnt_d0) AS reg_user_cnt_d0,
           SUM(gmv_usd_n) AS gmv_usd_n
    FROM base GROUP BY ad_platform
)
SELECT 'WEB' AS source_end, ad_platform, '30' AS window_name,
       first_delivery_date, last_delivery_date, delivery_day_count,
       cost_usd, reg_user_cnt_d0, gmv_usd_n,
       CAST(gmv_usd_n AS DOUBLE)/NULLIF(reg_user_cnt_d0,0) AS ltv_usd,
       CAST(gmv_usd_n AS DOUBLE)/NULLIF(cost_usd,0) AS roas
FROM totals ORDER BY ad_platform;
