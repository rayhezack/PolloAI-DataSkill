-- K-102 创作渗透率：Web 埋点分母与两种创作分子对照
-- status: pending_review
-- owner: 数据组
-- created: 2026-11-26
-- scope: Web；UTC+8 自然日；单位为人、比例（0~1）
-- parameters: ${start_date}, ${end_date}，均为 yyyymmdd，闭区间
-- definitions: M-USR-008、M-CRE-008/009/020/021；Section 03 已决：独立口径用于大盘，匹配口径用于分析。
-- source: Section 02 DS 埋点定义；R0/R1 已选创作任务宽表 T-006
-- execution: 尚未远程运行，无金标结果；不得因所在目录名而视为已核验。
-- 只输出两表至少一侧有用户数据的日期；全部无数据的自然日需另行核查，不能静默当作零。
WITH active_user_day AS (
    SELECT CAST(event_time AS DATE) AS stat_date,
           CAST(uid AS STRING) AS user_id
    FROM mc_prd.ods_pollo_log_event_dip
    WHERE p_date BETWEEN '${start_date}' AND '${end_date}'
      AND TO_CHAR(event_time, 'yyyymmdd') BETWEEN '${start_date}' AND '${end_date}'
      AND LOWER(platform_type) = 'web'
      AND event_id IS NOT NULL
      AND uid IS NOT NULL
      AND uid <> ''
    GROUP BY CAST(event_time AS DATE), CAST(uid AS STRING)
),
creation_user_day AS (
    SELECT CAST(created_time AS DATE) AS stat_date,
           CAST(user_id AS STRING) AS user_id
    FROM mc_prd.dwd_pollo_creation_task_dip
    WHERE p_date BETWEEN '${start_date}' AND '${end_date}'
      AND TO_CHAR(created_time, 'yyyymmdd') BETWEEN '${start_date}' AND '${end_date}'
      AND LOWER(platform_type) = 'web'
      AND is_valid_task = 1
    GROUP BY CAST(created_time AS DATE), CAST(user_id AS STRING)
),
observed_dates AS (
    SELECT stat_date FROM active_user_day
    UNION
    SELECT stat_date FROM creation_user_day
),
active_daily AS (
    SELECT stat_date, COUNT(DISTINCT user_id) AS registered_visit_uv
    FROM active_user_day
    GROUP BY stat_date
),
creation_daily AS (
    SELECT stat_date, COUNT(DISTINCT user_id) AS independent_creation_uv
    FROM creation_user_day
    GROUP BY stat_date
),
matched_daily AS (
    SELECT a.stat_date, COUNT(DISTINCT a.user_id) AS matched_creation_uv
    FROM active_user_day a
    INNER JOIN creation_user_day c
        ON a.user_id = c.user_id AND a.stat_date = c.stat_date
    GROUP BY a.stat_date
),
daily AS (
    SELECT d.stat_date,
           COALESCE(a.registered_visit_uv, 0) AS registered_visit_uv,
           COALESCE(c.independent_creation_uv, 0) AS independent_creation_uv,
           COALESCE(m.matched_creation_uv, 0) AS matched_creation_uv
    FROM observed_dates d
    LEFT JOIN active_daily a ON d.stat_date = a.stat_date
    LEFT JOIN creation_daily c ON d.stat_date = c.stat_date
    LEFT JOIN matched_daily m ON d.stat_date = m.stat_date
)
SELECT stat_date,
       registered_visit_uv,
       independent_creation_uv,
       matched_creation_uv,
       independent_creation_uv - matched_creation_uv AS creation_uv_without_same_day_visit,
       CAST(independent_creation_uv AS DOUBLE) / NULLIF(registered_visit_uv, 0)
           AS independent_creation_penetration,
       CAST(matched_creation_uv AS DOUBLE) / NULLIF(registered_visit_uv, 0)
           AS matched_creation_penetration
FROM daily
ORDER BY stat_date;
