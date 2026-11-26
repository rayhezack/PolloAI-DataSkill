-- K-103 当天采纳：行为明细关联与 DWS 汇总对账草稿
-- status: pending_review
-- owner: 数据组
-- created: 2026-11-26
-- scope: 全端；UTC+8 自然日；任务数、作品数、比例（0~1）
-- parameters: ${start_date}, ${end_date}，采纳发生日 yyyymmdd 闭区间
-- source: Section 04 DS 提供的采纳识别；CNB main@29f9758 的 DWS 关联实现
-- definitions: M-CRE-019；默认来源和有效/成功过滤待 OQ-21，不由本 SQL 决定。
-- execution: 未远程运行；生产表存在性、字段及历史回刷尚未核验，无金标结果。
-- 注意：作品和任务可能在统计窗之前很早创建，需全历史分区映射，不能按采纳日裁掉它们。
-- 本草稿可能扫描较大数据量；它用于对账，不是默认日常问数模板。
SET odps.sql.hive.compatible = true;
SET odps.sql.allow.fullscan = true;

WITH behavior_events AS (
    SELECT CAST(event_time AS DATE) AS adopt_date,
           event_id,
           UPPER(COALESCE(NULLIF(TRIM(platform_type), ''), 'OTHER')) AS event_platform,
           LOWER(GET_JSON_OBJECT(properties, '$.button_name')) AS button_name,
           NULLIF(TRIM(GET_JSON_OBJECT(properties, '$.content_id')), '') AS content_id,
           NULLIF(TRIM(GET_JSON_OBJECT(properties, '$.video_id')), '') AS video_id
    FROM mc_prd.dwd_pollo_behavior_base_content_dip
    WHERE p_date BETWEEN '${start_date}' AND '${end_date}'
      AND TO_CHAR(event_time, 'yyyymmdd') BETWEEN '${start_date}' AND '${end_date}'
      AND event_id IN ('content_click', 'content_download')
),
adoption AS (
    SELECT adopt_date, content_id AS video_id
    FROM behavior_events
    WHERE event_id = 'content_click'
      AND event_platform NOT IN ('IOS', 'ANDROID')
      AND button_name RLIKE '^(download|share|create_similar|imagetoimage|imagetovideo)'
      AND content_id IS NOT NULL
    UNION
    SELECT adopt_date, video_id
    FROM behavior_events
    WHERE event_id = 'content_download' AND video_id IS NOT NULL
),
work_map AS (
    SELECT DISTINCT CAST(video_id AS STRING) AS video_id,
                    CAST(record_id AS STRING) AS record_id
    FROM mc_prd.dwd_pollo_creation_work_dip
),
work_conflicts AS (
    SELECT video_id
    FROM work_map
    GROUP BY video_id
    HAVING COUNT(DISTINCT record_id) > 1
),
task_map AS (
    SELECT CAST(record_id AS STRING) AS record_id, user_id,
           is_valid_task, is_success_by_output
    FROM mc_prd.dwd_pollo_creation_task_dip
),
detail_daily AS (
    SELECT a.adopt_date,
           COUNT(DISTINCT a.video_id) AS source_adopted_output_cnt,
           COUNT(DISTINCT CASE WHEN w.record_id IS NOT NULL THEN a.video_id END)
               AS work_mapped_output_cnt,
           COUNT(DISTINCT CASE WHEN k.record_id IS NOT NULL THEN a.video_id END)
               AS task_mapped_output_cnt,
           COUNT(DISTINCT CASE WHEN f.video_id IS NOT NULL THEN a.video_id END)
               AS multi_task_output_cnt,
           COUNT(DISTINCT CASE WHEN k.user_id IS NOT NULL THEN k.record_id END)
               AS detail_broad_task_cnt,
           COUNT(DISTINCT CASE WHEN k.user_id IS NOT NULL AND k.is_valid_task = 1
                               THEN k.record_id END) AS detail_valid_task_cnt,
           COUNT(DISTINCT CASE WHEN k.user_id IS NOT NULL AND k.is_valid_task = 1
                                    AND k.is_success_by_output = 1
                               THEN k.record_id END) AS detail_valid_success_task_cnt
    FROM adoption a
    LEFT JOIN work_map w ON a.video_id = w.video_id
    LEFT JOIN task_map k ON w.record_id = k.record_id
    LEFT JOIN work_conflicts f ON a.video_id = f.video_id
    GROUP BY a.adopt_date
),
dws_daily AS (
    SELECT stat_date,
           SUM(adopt_date_task_cnt) AS dws_broad_task_cnt,
           SUM(CASE WHEN is_valid_task = 1 THEN adopt_date_task_cnt ELSE 0 END)
               AS dws_valid_task_cnt,
           SUM(CASE WHEN is_valid_task = 1 AND is_success_task = 1
                    THEN adopt_date_task_cnt ELSE 0 END) AS dws_valid_success_task_cnt
    FROM mc_prd.dws_pollo_creation_user_adopt_daily_dip
    WHERE p_date BETWEEN '${start_date}' AND '${end_date}'
      AND TO_CHAR(stat_date, 'yyyymmdd') BETWEEN '${start_date}' AND '${end_date}'
    GROUP BY stat_date
)
SELECT COALESCE(d.adopt_date, s.stat_date) AS adopt_date,
       d.source_adopted_output_cnt, d.work_mapped_output_cnt,
       d.task_mapped_output_cnt, d.multi_task_output_cnt,
       CAST(d.task_mapped_output_cnt AS DOUBLE) / NULLIF(d.source_adopted_output_cnt, 0)
           AS output_to_task_mapping_rate,
       d.detail_broad_task_cnt, s.dws_broad_task_cnt,
       d.detail_valid_task_cnt, s.dws_valid_task_cnt,
       d.detail_valid_success_task_cnt, s.dws_valid_success_task_cnt,
       d.detail_valid_task_cnt - s.dws_valid_task_cnt AS valid_task_delta
FROM detail_daily d
FULL OUTER JOIN dws_daily s ON d.adopt_date = s.stat_date
ORDER BY adopt_date;
