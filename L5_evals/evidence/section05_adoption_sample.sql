-- Section 05 生产样本核验；2026-11-26，UTC+8，全站。
-- instance: 20261126135817577gu6nke01999
-- 当天采纳默认口径只限定有效任务；成功状态列用于核查，不作为新增过滤。
SELECT p_date,
       COUNT(1) AS row_cnt,
       SUM(adopt_date_task_cnt) AS broad_task_cnt,
       SUM(CASE WHEN is_valid_task = 1 THEN adopt_date_task_cnt ELSE 0 END) AS valid_task_cnt,
       SUM(CASE WHEN is_valid_task = 1 AND is_success_task = 1 THEN adopt_date_task_cnt ELSE 0 END) AS valid_success_task_cnt,
       SUM(CASE WHEN is_valid_task = 1 AND (is_success_task <> 1 OR is_success_task IS NULL)
                THEN adopt_date_task_cnt ELSE 0 END) AS valid_adopt_with_non_success_flag_cnt,
       SUM(CASE WHEN is_valid_task = 1 THEN adopt_date_output_cnt ELSE 0 END) AS valid_output_cnt
FROM mc_prd.dws_pollo_creation_user_adopt_daily_dip
WHERE p_date IN ('20261031','20261124','20261125')
  AND TO_CHAR(stat_date,'yyyymmdd') = p_date
GROUP BY p_date
ORDER BY p_date;
