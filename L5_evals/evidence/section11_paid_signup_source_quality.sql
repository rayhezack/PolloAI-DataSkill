-- Web付费注册来源与画像注册端/内部标记的技术对照；不修改已确认CAC公式。
SELECT a.ad_platform, COUNT(DISTINCT a.uid) AS attributed_signup_uv,
       COUNT(DISTINCT CASE WHEN p.user_id IS NULL THEN a.uid END) AS profile_missing_uv,
       COUNT(DISTINCT CASE WHEN p.is_internal_user_da=1 THEN a.uid END) AS internal_uv,
       COUNT(DISTINCT CASE WHEN p.reg_platform<>'WEB' THEN a.uid END) AS non_web_profile_uv
FROM mc_prd.dws_pollo_ad_attribution_user_dip a
LEFT JOIN mc_prd.ads_pollo_user_profile_dfp p
 ON a.uid=CAST(p.user_id AS STRING) AND p.p_date='20261126'
WHERE a.p_date BETWEEN '20261030' AND '20261031'
 AND a.source_end='WEB' AND a.ad_platform IS NOT NULL
GROUP BY a.ad_platform ORDER BY a.ad_platform;
