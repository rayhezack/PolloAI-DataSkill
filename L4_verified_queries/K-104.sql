-- K-104 当天采纳任务数：DS 已确认的默认取数 SQL
-- status: pending_review
-- owner: 数据组
-- created: 2026-11-26
-- source: Section 05 DS：汇总表为默认来源，is_valid_task=1 必须限定。
-- definitions: M-CRE-019、T-012；采纳发生日，UTC+8；单位：任务/日
-- parameters: ${start_date}, ${end_date}，yyyymmdd 闭区间；完整日通常取到昨日。
-- scope: 全站；分端时另按任务 platform_type 限定，不能误用采纳事件端。
-- validation: 生产字段与样本结果另记 governance/creation_source_check_20261126.md。
-- sample: 同过滤的生产聚合样本（section05_adoption_sample.sql）已通过；20261031 为 100856。
-- 执行成功及结果核验之前，不能因所在目录名就视为 verified。
-- 期间汇总应先说明“任务日累计”或“日均”，不当作跨天去重任务数。
SELECT stat_date,
       SUM(adopt_date_task_cnt) AS adopted_task_cnt
FROM mc_prd.dws_pollo_creation_user_adopt_daily_dip
WHERE p_date BETWEEN '${start_date}' AND '${end_date}'
  AND TO_CHAR(stat_date, 'yyyymmdd') BETWEEN '${start_date}' AND '${end_date}'
  AND is_valid_task = 1
GROUP BY stat_date
ORDER BY stat_date;
