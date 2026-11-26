-- Section 07 production sample; 2026-11-26, UTC+8.
SELECT p_date, stat_date, SUM(mau) AS rolling_30d_visitor_active, SUM(dau) AS visitor_uv,
       SUM(retain_1d) AS retain_1d, SUM(retain_3d) AS retain_3d, SUM(retain_7d) AS retain_7d,
       CAST(SUM(retain_1d) AS DOUBLE)/NULLIF(SUM(dau),0) AS visitor_d1_retention,
       CAST(SUM(retain_3d) AS DOUBLE)/NULLIF(SUM(dau),0) AS visitor_d3_retention,
       CAST(SUM(retain_7d) AS DOUBLE)/NULLIF(SUM(dau),0) AS visitor_d7_retention
FROM mc_prd.ads_pollo_user_active_daily_dip
WHERE p_date IN ('20261030','20261031','20261124') AND TO_CHAR(stat_date,'yyyymmdd') = p_date
  AND client_type='汇总' AND country='汇总' AND borderline_tag='汇总'
GROUP BY p_date, stat_date ORDER BY p_date;
