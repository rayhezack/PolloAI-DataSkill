-- K-106 滚动30日访客活跃数与访客D1/D3/D7点位留存率
-- status: pending_review; owner: 数据组; created: 2026-11-26
-- definitions: M-USR-005、M-USR-007；T-005 汇总行；UTC+8。
-- D_N 仅在观察窗结束时输出，未成熟的 retain_Nd 保持 NULL。
SELECT p_date, stat_date, SUM(mau) AS rolling_30d_visitor_active,
       SUM(dau) AS visitor_uv, SUM(retain_1d) AS retain_1d,
       SUM(retain_3d) AS retain_3d, SUM(retain_7d) AS retain_7d,
       CAST(SUM(retain_1d) AS DOUBLE) / NULLIF(SUM(dau), 0) AS visitor_d1_retention,
       CAST(SUM(retain_3d) AS DOUBLE) / NULLIF(SUM(dau), 0) AS visitor_d3_retention,
       CAST(SUM(retain_7d) AS DOUBLE) / NULLIF(SUM(dau), 0) AS visitor_d7_retention
FROM mc_prd.ads_pollo_user_active_daily_dip
WHERE p_date BETWEEN '${start_date}' AND '${end_date}'
  AND TO_CHAR(stat_date, 'yyyymmdd') BETWEEN '${start_date}' AND '${end_date}'
  AND client_type = '汇总' AND country = '汇总' AND borderline_tag = '汇总'
GROUP BY p_date, stat_date ORDER BY p_date;
