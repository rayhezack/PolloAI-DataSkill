-- status: pending_review
-- K-108 注册日 cohort GMV 核验；T-008；USD。
-- 本模板只输出 D3/D7，不能冒充投放日起算的 D3/D7；不计算LTV；内部ROI已删除。
-- 参数均为北京时间 yyyymmdd。分母和成本未输出；所有行用同一批已满 D7 的注册日期。
-- 保留全部 match_level；只取总产品/总首购主行，避免与产品拆分重复。
SELECT source_end, LOWER(ad_platform) AS ad_platform,
       MIN(p_date) AS first_cohort_date, MAX(p_date) AS last_cohort_date,
       SUM(cohort_user_cnt) AS cohort_user_cnt,
       SUM(gmv_usd_d3) AS gmv_usd_d3, SUM(gmv_usd_d7) AS gmv_usd_d7
FROM mc_prd.ads_pollo_ad_attribution_daily_dip
WHERE p_date BETWEEN '${start_date}' AND '${end_date}'
  AND TO_CHAR(stat_date, 'yyyymmdd') BETWEEN '${start_date}' AND '${end_date}'
  AND p_date = TO_CHAR(stat_date, 'yyyymmdd')
  AND p_date <= TO_CHAR(DATEADD(TO_DATE('${as_of_date}', 'yyyymmdd'), -8, 'dd'), 'yyyymmdd')
  AND product_type = 'ALL' AND is_first_purchase = '汇总'
GROUP BY source_end, LOWER(ad_platform)
ORDER BY source_end, ad_platform;
