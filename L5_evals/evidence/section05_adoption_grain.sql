-- Section 05 production sample grain check; 2026-11-26; UTC+8.
WITH grain_check AS (
    SELECT p_date, stat_date, user_id, visitor_type, platform_type,
           web_client_type, req_country_code, task_type,
           is_valid_task, is_success_task, COUNT(1) AS copies
    FROM mc_prd.dws_pollo_creation_user_adopt_daily_dip
    WHERE p_date IN ('20261031','20261124','20261125')
      AND TO_CHAR(stat_date,'yyyymmdd') = p_date
    GROUP BY p_date, stat_date, user_id, visitor_type, platform_type,
             web_client_type, req_country_code, task_type,
             is_valid_task, is_success_task
)
SELECT p_date, COUNT(1) AS grain_groups,
       SUM(copies - 1) AS duplicate_extra_rows
FROM grain_check
GROUP BY p_date
ORDER BY p_date
