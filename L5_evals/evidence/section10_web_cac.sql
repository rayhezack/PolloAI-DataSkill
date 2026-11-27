-- K-107 Web 大盘注册获客成本 CAC；Section10 后续 DS 裁决，2026-11-27。
-- M-AD-007 = M-AD-001（Web 全广告平台成本）/ M-USR-001（Web 当日注册）。
-- T-010 成本与 T-009 注册分别聚合到北京时间自然日再关联；禁止明细关联。
-- 仅 source_end=WEB / reg_platform=WEB；App/UNKNOWN 不纳入。注册包含自然和广告渠道，沿用 is_registered=1、排除内部用户、user_id 去重。
-- 不用 reg_user_cnt_d0 / install_cnt 作分母；不套用 ROAS 的 P-41 平台白名单。
-- start_date/end_date/as_of_date/snapshot_date 均为 yyyymmdd；snapshot_date 日常取昨日。
-- 默认统计截到 as_of_date 的 T-2（P-39）；同日比率，不表示逐广告归因/因果获客成本。
-- 输出每日及期间合计；期间用总成本/总注册，不平均每日 CAC。缺失任一侧/零分母返回 NULL。
WITH cost AS (
    SELECT p_date AS stat_date, SUM(cost_usd) AS cost_usd
    FROM mc_prd.ads_pollo_ad_attribution_delivery_daily_hip
    WHERE p_date BETWEEN '20261030' AND '20261031'
      AND TO_CHAR(stat_date, 'yyyymmdd') BETWEEN '20261030' AND '20261031'
      AND p_date = TO_CHAR(stat_date, 'yyyymmdd')
      AND p_date <= TO_CHAR(DATEADD(TO_DATE('20261127', 'yyyymmdd'), -2, 'dd'), 'yyyymmdd')
      AND source_end = 'WEB'
    GROUP BY p_date
), signup AS (
    SELECT TO_CHAR(register_date, 'yyyymmdd') AS stat_date,
           COUNT(DISTINCT user_id) AS signup_uv
    FROM mc_prd.ads_pollo_user_profile_dfp
    WHERE p_date = '20261126'
      AND reg_platform = 'WEB'
      AND is_registered = 1
      AND COALESCE(is_internal_user_da, 0) <> 1
      AND TO_CHAR(register_date, 'yyyymmdd') BETWEEN '20261030' AND '20261031'
      AND TO_CHAR(register_date, 'yyyymmdd') <= TO_CHAR(DATEADD(TO_DATE('20261127', 'yyyymmdd'), -2, 'dd'), 'yyyymmdd')
    GROUP BY TO_CHAR(register_date, 'yyyymmdd')
), daily AS (
    SELECT COALESCE(c.stat_date, s.stat_date) AS stat_date, c.cost_usd, s.signup_uv
    FROM cost c FULL OUTER JOIN signup s ON c.stat_date = s.stat_date
)
SELECT 'daily' AS row_type, stat_date AS period_start, stat_date AS period_end,
       cost_usd, signup_uv,
       CAST(cost_usd AS DOUBLE) / NULLIF(signup_uv, 0) AS cac_usd
FROM daily
UNION ALL
SELECT 'period_total' AS row_type, MIN(stat_date) AS period_start, MAX(stat_date) AS period_end,
       SUM(cost_usd) AS cost_usd, SUM(signup_uv) AS signup_uv,
       CASE WHEN COUNT(*) = COUNT(cost_usd) AND COUNT(*) = COUNT(signup_uv)
            THEN CAST(SUM(cost_usd) AS DOUBLE) / NULLIF(SUM(signup_uv), 0)
            ELSE NULL END AS cac_usd
FROM daily
ORDER BY row_type, period_start;
