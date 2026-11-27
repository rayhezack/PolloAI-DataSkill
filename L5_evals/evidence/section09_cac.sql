-- K-107 广告 CAC；Section09 已确认业务定义，SQL 仍为 pending_review。
-- M-AD-007；T-010；按投放端 × 平台先汇总再相除，不输出跨端总 CAC。
-- 参数 start_date/end_date/as_of_date 均为北京时间 yyyymmdd；默认统计截至 as_of_date 的 T-2。
-- 金额 USD；Web 分母为 D0 注册人数，App 分母为安装数；分母不随 GMV 窗口改变。
-- APP 2025 年口径与逐人归因尚未校准，本模板仅覆盖 20260101 起；无数据/零分母返回 NULL。
WITH base AS (
    SELECT source_end, LOWER(ad_platform) AS ad_platform,
           cost_usd, reg_user_cnt_d0, install_cnt
    FROM mc_prd.ads_pollo_ad_attribution_delivery_daily_hip
    WHERE p_date BETWEEN '20261001' AND '20261031'
      AND TO_CHAR(stat_date, 'yyyymmdd') BETWEEN '20261001' AND '20261031'
      AND p_date = TO_CHAR(stat_date, 'yyyymmdd')
      AND p_date <= TO_CHAR(DATEADD(TO_DATE('20261127', 'yyyymmdd'), -2, 'dd'), 'yyyymmdd')
      AND ((source_end = 'WEB' AND LOWER(ad_platform) IN ('google','bing','yahoo','naver'))
        OR (source_end = 'APP' AND p_date >= '20260101'
            AND (LOWER(ad_platform) IN ('meta','asa','tiktok')
              OR (LOWER(ad_platform) = 'google' AND p_date >= '20260401'))))
), totals AS (
    SELECT source_end, ad_platform, SUM(cost_usd) AS cost_usd,
           SUM(reg_user_cnt_d0) AS reg_user_cnt_d0, SUM(install_cnt) AS install_cnt
    FROM base GROUP BY source_end, ad_platform
)
SELECT source_end, ad_platform, cost_usd, reg_user_cnt_d0, install_cnt,
       CASE WHEN source_end = 'WEB' THEN 'D0 registrations' ELSE 'installs' END AS denominator_basis,
       CAST(cost_usd AS DOUBLE) / NULLIF(
           CASE WHEN source_end = 'WEB' THEN reg_user_cnt_d0 ELSE install_cnt END, 0) AS cac_usd
FROM totals ORDER BY source_end, ad_platform;
