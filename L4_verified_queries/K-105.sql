-- K-105 访客注册转化率与访客登录占比（全站逐日）
-- status: pending_review
-- owner: 数据组
-- created: 2026-11-26
-- definitions: M-USR-003、M-USR-009；来源 T-009 / T-005。
-- parameters: ${start_date}, ${end_date}, ${snapshot_date}，均为 yyyymmdd。
-- snapshot_date 为画像快照日，日常使用昨日；不能用历史行为日猜测快照分区存在。
-- scope: UTC+8，自然日，全站；输出比率为0~1，展示百分比时乘100。
-- evidence: 同算法三个生产样本已通过，见 L5_evals/evidence/section06_user_ratios.sql 及结果。
-- 原“访问注册率”裸词须先确认含义。字段或样本通过不等于全库验收。
-- 仅输出活跃表有数据的业务日；未输出的日期须排查，不能静默当作0。
-- signup_uv 为 NULL 时须检查画像快照及注册日覆盖，不将缺失快照默认为0。
WITH active AS (
    SELECT stat_date,
           SUM(dau) AS visitor_uv,
           SUM(login_visitor_cnt) AS logged_in_visitor_uv
    FROM mc_prd.ads_pollo_user_active_daily_dip
    WHERE p_date BETWEEN '${start_date}' AND '${end_date}'
      AND TO_CHAR(stat_date, 'yyyymmdd') BETWEEN '${start_date}' AND '${end_date}'
      AND client_type = '汇总'
      AND country = '汇总'
      AND borderline_tag = '汇总'
    GROUP BY stat_date
),
signup AS (
    SELECT CAST(TO_DATE(SUBSTR(CAST(register_date AS STRING), 1, 10), 'yyyy-mm-dd') AS DATE) AS signup_date,
           COUNT(DISTINCT user_id) AS signup_uv
    FROM mc_prd.ads_pollo_user_profile_dfp
    WHERE p_date = '${snapshot_date}'
      AND is_registered = 1
      AND COALESCE(is_internal_user_da, 0) <> 1
      AND TO_CHAR(register_date, 'yyyymmdd') BETWEEN '${start_date}' AND '${end_date}'
    GROUP BY CAST(TO_DATE(SUBSTR(CAST(register_date AS STRING), 1, 10), 'yyyy-mm-dd') AS DATE)
)
SELECT a.stat_date,
       a.visitor_uv,
       a.logged_in_visitor_uv,
       s.signup_uv,
       CAST(s.signup_uv AS DOUBLE) / NULLIF(a.visitor_uv, 0) AS visitor_signup_rate,
       CAST(a.logged_in_visitor_uv AS DOUBLE) / NULLIF(a.visitor_uv, 0) AS visitor_login_share
FROM active a
LEFT JOIN signup s ON CAST(a.stat_date AS DATE) = s.signup_date
ORDER BY a.stat_date;
