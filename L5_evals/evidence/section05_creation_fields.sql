-- Section 05 production field rollout sample; 2026-11-26; UTC+8.
SELECT p_date,
       COUNT(1) AS task_rows,
       COUNT(DISTINCT record_id) AS unique_tasks,
       SUM(CASE WHEN submit_time IS NOT NULL THEN 1 ELSE 0 END) AS legacy_request_cnt,
       SUM(CASE WHEN is_submitted_to_provider = 1 THEN 1 ELSE 0 END) AS provider_request_cnt,
       SUM(CASE WHEN LOWER(entry_code) = 'transcription' AND task_status = 'succeed' THEN 1 ELSE 0 END) AS succeeded_transcription_cnt,
       SUM(CASE WHEN LOWER(entry_code) = 'transcription' AND task_status = 'succeed' AND is_success_by_output <> 1 THEN 1 ELSE 0 END) AS succeeded_transcription_misclassified_cnt,
       SUM(credit_consume) AS gross_credit_consume,
       SUM(return_credit) AS returned_credit,
       SUM(credit_consume - COALESCE(return_credit,0)) AS net_credit_consume,
       SUM(CASE WHEN is_success_by_output = 1 THEN credit_consume ELSE 0 END) AS temporary_success_credit_consume,
       SUM(create_date_adopted_output_cnt_3d) AS create_date_adopted_output_cnt_3d,
       CAST(MAX(etl_time) AS STRING) AS latest_etl_time
FROM mc_prd.dwd_pollo_creation_task_dip
WHERE p_date IN ('20261031','20261124','20261125')
  AND TO_CHAR(created_time,'yyyymmdd') = p_date
  AND is_valid_task = 1
GROUP BY p_date
ORDER BY p_date
