-- ============================================================================
-- K-101 设备分流实验离线测算（实验版口径）
-- status: pending_review          owner: 数据组          created: 2026-11-25
-- 用途：did 实验结论的兜底与 DataTester 平台口径复核（平台宽表不知道分组和串组，这里补上）
-- 口径来源：《设备分流实验 ID Mapping 与样本清洗口径》2026-11-23；
--           指标：M-PAY-001 支付GMV（含 API）、M-CRE-001 创作任务数，及 uid 实验回收标准 SQL
-- 时间窗：${start_date}–${end_date}（UTC+8）；端别：Web；单位：USD、个
-- 试跑：creation-default-reference-to-video-ab-test，20261010–20261012，结果见 did 设计文档第 9 节
-- 姊妹表：did指标组/02_did实验回收日宽表.sql（平台日常口径）
-- ============================================================================
-- 设备粒度实验离线测算（实验版口径）：did 实验的结论兜底与平台复核
-- 清洗逻辑：《设备分流实验 ID Mapping 与样本清洗口径》（2026-11-23）；指标口径：uid 实验回收标准 SQL、did 宽表
-- 参数：${exp_id}；${start_date} / ${end_date} = 实验窗口 yyyymmdd（UTC+8）
-- 端别：Web（Web did 一律取前 32 位小写 hex）；App 实验把 platform 过滤改为 ios / android，并去掉 did 截取
-- 指标窗口：设备从首次曝光日起、用户从归属设备首次曝光日起，累计到 ${end_date}；创作留存需要 ${end_date} 后 30 天数据
WITH
-- ① 读曝光：只要求 device_id 非空，user_id 可为空
exp_raw AS (
    SELECT REGEXP_EXTRACT(LOWER(TRIM(device_id)), '^([0-9a-f]{32})', 1) AS device_id,
           NULLIF(TRIM(CAST(user_id AS STRING)), '') AS user_id,
           TRIM(group_label) AS group_label,
           CAST(exp_exposure_time AS DATETIME) AS exp_exposure_time
    FROM mc_prd.dwd_video_pollo_exp_log_dip
    WHERE p_date BETWEEN '${start_date}' AND '${end_date}'
      AND exp_id = '${exp_id}'
      AND LOWER(platform) = 'web'
      AND NULLIF(TRIM(group_label), '') IS NOT NULL
),
-- ② 设备串组与分母：在全部曝光行上统计组数和首次曝光时间
device_first AS (
    SELECT device_id,
           MIN(group_label) AS group_label,
           COUNT(DISTINCT group_label) AS device_group_cnt,
           MIN(exp_exposure_time) AS device_first_time
    FROM exp_raw
    WHERE device_id IS NOT NULL
      AND device_id <> '00000000000000000000000000000000'
    GROUP BY device_id
),
-- 合格设备 = 实验分母：只剔除命中多个组的设备
clean_device AS (
    SELECT device_id, group_label, device_first_time,
           CAST(device_first_time AS DATE) AS device_first_date
    FROM device_first
    WHERE device_group_cnt = 1
),
-- ③ 用户-设备关系：曝光日志 user_id ∪ 设备关系表（实验窗口内分区）
device_user_link AS (
    SELECT device_id, user_id
    FROM (
        SELECT device_id, user_id FROM exp_raw
        UNION
        SELECT REGEXP_EXTRACT(LOWER(TRIM(device_id)), '^([0-9a-f]{32})', 1) AS device_id,
               NULLIF(TRIM(CAST(uid AS STRING)), '') AS user_id
        FROM mc_prd.dwd_pollo_user_device_relation_dip
        WHERE p_date BETWEEN '${start_date}' AND '${end_date}'
          AND UPPER(platform_type) = 'WEB'
    ) t
    WHERE device_id IS NOT NULL
      AND user_id IS NOT NULL
      AND user_id NOT LIKE 'anon-%'
),
-- 只保留关联到实验设备的关系；组别取原始 (设备, 组别) 对，串组设备的两个组别都保留
device_user_exp AS (
    SELECT l.device_id, l.user_id, g.group_label, d.device_first_time
    FROM device_user_link l
    INNER JOIN (SELECT DISTINCT device_id, group_label FROM exp_raw WHERE device_id IS NOT NULL) g
            ON l.device_id = g.device_id
    INNER JOIN device_first d ON l.device_id = d.device_id
),
-- ④ 用户串组：关联到的设备出现在多个组（含用过串组设备）时整户剔除，其设备仍留在分母
user_map AS (
    SELECT user_id,
           COUNT(DISTINCT device_id) AS user_device_cnt,
           COUNT(DISTINCT group_label) AS user_group_cnt
    FROM device_user_exp
    GROUP BY user_id
),
-- ⑤ 一人一设备：归到首次曝光最早的设备，device_id 为并列时的稳定排序键
canonical_device_user AS (
    SELECT user_id, device_id, group_label,
           device_first_time AS user_first_time,
           CAST(device_first_time AS DATE) AS user_first_date
    FROM (
        SELECT e.user_id, e.device_id, e.group_label, e.device_first_time,
               ROW_NUMBER() OVER (PARTITION BY e.user_id
                                  ORDER BY e.device_first_time ASC, e.device_id ASC) AS rn
        FROM device_user_exp e
        INNER JOIN user_map u ON e.user_id = u.user_id
        WHERE u.user_group_cnt = 1
    ) t
    WHERE rn = 1
),
-- ⑥-a 账号行为（只按 user_id 记录）：归属设备首次曝光日起至 ${end_date}
-- 支付：M-PAY-001 支付GMV（含 API）；新购 = 非续费
pay_user AS (
    SELECT c.user_id,
           MAX(CASE WHEN o.amount_received_usd > 0 THEN 1 ELSE 0 END) AS is_pay,
           SUM(o.amount_received_usd) AS pay_amount_usd,
           COUNT(DISTINCT o.payment_id) AS pay_order_cnt,
           MAX(CASE WHEN COALESCE(o.sub_order_type, '') <> 'RENEWAL' AND o.amount_received_usd > 0 THEN 1 ELSE 0 END) AS is_new_purchase_pay,
           SUM(CASE WHEN COALESCE(o.sub_order_type, '') <> 'RENEWAL' THEN o.amount_received_usd ELSE 0 END) AS new_purchase_amount_usd,
           MAX(CASE WHEN o.sub_order_type = 'FIRST_SUB' AND o.amount_received_usd > 0 THEN 1 ELSE 0 END) AS is_first_sub_pay,
           SUM(CASE WHEN o.sub_order_type = 'FIRST_SUB' THEN o.amount_received_usd ELSE 0 END) AS first_sub_amount_usd,
           SUM(CASE WHEN o.sub_order_type = 'RENEWAL' THEN o.amount_received_usd ELSE 0 END) AS renewal_amount_usd
    FROM canonical_device_user c
    INNER JOIN (
        SELECT CAST(user_id AS STRING) AS user_id, payment_id, pay_date, amount_received_usd, sub_order_type
        FROM mc_prd.dwd_pollo_transaction_order_dip
        WHERE p_date BETWEEN '${start_date}' AND '${end_date}'
          AND pay_date BETWEEN CAST(TO_DATE('${start_date}', 'yyyymmdd') AS DATE)
                           AND CAST(TO_DATE('${end_date}', 'yyyymmdd') AS DATE)
          AND is_valid_order = 1
          AND LOWER(pay_platform) = 'web'
          AND user_id IS NOT NULL
    ) o ON c.user_id = o.user_id
    WHERE o.pay_date >= c.user_first_date
    GROUP BY c.user_id
),
-- 创作：M-CRE-001 创作任务数；按创建日归日，读到 ${end_date} 后 30 天供留存使用
creation_user_day AS (
    SELECT CAST(user_id AS STRING) AS user_id,
           CAST(created_time AS DATE) AS create_date,
           COUNT(DISTINCT record_id) AS creation_task_cnt,
           COUNT(DISTINCT CASE WHEN submit_time IS NOT NULL THEN record_id END) AS submit_task_cnt,
           COUNT(DISTINCT CASE WHEN is_success_by_output = 1 THEN record_id END) AS success_task_cnt,
           COUNT(DISTINCT CASE WHEN adopted_output_cnt_3d > 0 THEN record_id END) AS adopted_task_cnt,
           SUM(credit_consume) AS credit_consume,
           SUM(gen_duration_sec) AS gen_duration_sec
    FROM mc_prd.dwd_pollo_creation_task_dip
    WHERE p_date BETWEEN '${start_date}'
                     AND TO_CHAR(DATEADD(TO_DATE('${end_date}', 'yyyymmdd'), 30, 'dd'), 'yyyymmdd')
      AND TO_CHAR(created_time, 'yyyymmdd') BETWEEN '${start_date}'
                     AND TO_CHAR(DATEADD(TO_DATE('${end_date}', 'yyyymmdd'), 30, 'dd'), 'yyyymmdd')
      AND is_valid_task = 1
      AND LOWER(platform_type) = 'web'
    GROUP BY CAST(user_id AS STRING), CAST(created_time AS DATE)
),
creation_user AS (
    SELECT c.user_id,
           -- 计数类只算实验窗口内（与平台「首次命中后全实验周期」一致）
           MAX(CASE WHEN t.create_date <= CAST(TO_DATE('${end_date}', 'yyyymmdd') AS DATE) THEN 1 ELSE 0 END) AS is_create,
           SUM(CASE WHEN t.create_date <= CAST(TO_DATE('${end_date}', 'yyyymmdd') AS DATE) THEN t.creation_task_cnt ELSE 0 END) AS creation_task_cnt,
           SUM(CASE WHEN t.create_date <= CAST(TO_DATE('${end_date}', 'yyyymmdd') AS DATE) THEN t.submit_task_cnt ELSE 0 END) AS submit_task_cnt,
           SUM(CASE WHEN t.create_date <= CAST(TO_DATE('${end_date}', 'yyyymmdd') AS DATE) THEN t.success_task_cnt ELSE 0 END) AS success_task_cnt,
           SUM(CASE WHEN t.create_date <= CAST(TO_DATE('${end_date}', 'yyyymmdd') AS DATE) THEN t.adopted_task_cnt ELSE 0 END) AS adopted_task_cnt,
           SUM(CASE WHEN t.create_date <= CAST(TO_DATE('${end_date}', 'yyyymmdd') AS DATE) THEN t.credit_consume ELSE 0 END) AS credit_consume,
           SUM(CASE WHEN t.create_date <= CAST(TO_DATE('${end_date}', 'yyyymmdd') AS DATE) THEN t.gen_duration_sec ELSE 0 END) AS gen_duration_sec,
           -- 精确自然日留存：归属设备首次曝光日 + N 天当天有创作
           MAX(CASE WHEN DATEDIFF(t.create_date, c.user_first_date, 'dd') = 1 THEN 1 ELSE 0 END) AS is_creation_d1,
           MAX(CASE WHEN DATEDIFF(t.create_date, c.user_first_date, 'dd') = 7 THEN 1 ELSE 0 END) AS is_creation_d7
    FROM canonical_device_user c
    INNER JOIN creation_user_day t ON c.user_id = t.user_id
    WHERE t.create_date >= c.user_first_date
    GROUP BY c.user_id
),
-- 注册：在归属设备首次曝光日到 ${end_date} 之间注册的 Web 账号
signup_user AS (
    SELECT c.user_id, 1 AS is_signup
    FROM canonical_device_user c
    INNER JOIN (
        SELECT CAST(id AS STRING) AS user_id, CAST(date_created AS DATE) AS reg_date
        FROM mc_prd.dwd_ai_video_pollo_user_dfp
        WHERE p_date = TO_CHAR(DATEADD(GETDATE(), -1, 'dd'), 'yyyymmdd')   -- 全量快照只保留昨日分区，回刷历史也读它
          AND TO_CHAR(date_created, 'yyyymmdd') BETWEEN '${start_date}' AND '${end_date}'
          AND email IS NOT NULL
    ) r ON c.user_id = r.user_id
    WHERE r.reg_date >= c.user_first_date
),
-- 账号行为汇总到归属设备：一台设备多个用户时，0/1 取 MAX，金额和次数取 SUM
device_attr AS (
    SELECT c.device_id,
           COUNT(DISTINCT c.user_id) AS user_cnt,
           MAX(COALESCE(p.is_pay, 0)) AS is_pay,
           SUM(COALESCE(p.pay_amount_usd, 0)) AS pay_amount_usd,
           SUM(COALESCE(p.pay_order_cnt, 0)) AS pay_order_cnt,
           MAX(COALESCE(p.is_new_purchase_pay, 0)) AS is_new_purchase_pay,
           SUM(COALESCE(p.new_purchase_amount_usd, 0)) AS new_purchase_amount_usd,
           MAX(COALESCE(p.is_first_sub_pay, 0)) AS is_first_sub_pay,
           SUM(COALESCE(p.first_sub_amount_usd, 0)) AS first_sub_amount_usd,
           SUM(COALESCE(p.renewal_amount_usd, 0)) AS renewal_amount_usd,
           MAX(COALESCE(cr.is_create, 0)) AS is_create,
           SUM(COALESCE(cr.creation_task_cnt, 0)) AS creation_task_cnt,
           SUM(COALESCE(cr.submit_task_cnt, 0)) AS submit_task_cnt,
           SUM(COALESCE(cr.success_task_cnt, 0)) AS success_task_cnt,
           SUM(COALESCE(cr.adopted_task_cnt, 0)) AS adopted_task_cnt,
           SUM(COALESCE(cr.credit_consume, 0)) AS credit_consume,
           SUM(COALESCE(cr.gen_duration_sec, 0)) AS gen_duration_sec,
           MAX(COALESCE(cr.is_creation_d1, 0)) AS is_creation_d1,
           MAX(COALESCE(cr.is_creation_d7, 0)) AS is_creation_d7,
           MAX(COALESCE(s.is_signup, 0)) AS is_signup
    FROM canonical_device_user c
    LEFT JOIN pay_user p       ON c.user_id = p.user_id
    LEFT JOIN creation_user cr ON c.user_id = cr.user_id
    LEFT JOIN signup_user s    ON c.user_id = s.user_id
    GROUP BY c.device_id
),
-- ⑥-b 设备原生指标：埋点 did 取前 32 位后直接汇总，含未登录；设备首次曝光日起至 ${end_date}，回访读到 +7 天
device_event_day AS (
    SELECT e.device_id, e.event_date,
           MAX(e.is_paywall_expose) AS is_paywall_expose,
           MAX(e.is_paywall_submit) AS is_paywall_submit,
           MAX(e.is_login) AS is_login
    FROM (
        SELECT REGEXP_EXTRACT(LOWER(TRIM(device_id)), '^([0-9a-f]{32})', 1) AS device_id,
               CAST(event_time AS DATE) AS event_date,
               CASE WHEN (event_id = 'page_view' AND page_name IN ('account/billing', 'pricing'))
                         OR event_id = 'sub_start' THEN 1 ELSE 0 END AS is_paywall_expose,
               CASE WHEN event_id IN ('sub_submit', 'refresh_billing_click') THEN 1 ELSE 0 END AS is_paywall_submit,
               CASE WHEN NULLIF(TRIM(uid), '') IS NOT NULL THEN 1 ELSE 0 END AS is_login
        FROM mc_prd.ods_pollo_log_event_dip
        WHERE p_date BETWEEN '${start_date}'
                         AND TO_CHAR(DATEADD(TO_DATE('${end_date}', 'yyyymmdd'), 7, 'dd'), 'yyyymmdd')
          AND TO_CHAR(event_time, 'yyyymmdd') BETWEEN '${start_date}'
                         AND TO_CHAR(DATEADD(TO_DATE('${end_date}', 'yyyymmdd'), 7, 'dd'), 'yyyymmdd')
          AND LOWER(platform_type) = 'web'
    ) e
    LEFT SEMI JOIN clean_device d ON e.device_id = d.device_id
    GROUP BY e.device_id, e.event_date
),
device_native AS (
    SELECT d.device_id,
           MAX(CASE WHEN v.event_date <= CAST(TO_DATE('${end_date}', 'yyyymmdd') AS DATE) THEN 1 ELSE 0 END) AS is_event_matched,
           MAX(CASE WHEN v.event_date <= CAST(TO_DATE('${end_date}', 'yyyymmdd') AS DATE) THEN v.is_paywall_expose ELSE 0 END) AS is_paywall_expose,
           MAX(CASE WHEN v.event_date <= CAST(TO_DATE('${end_date}', 'yyyymmdd') AS DATE) THEN v.is_paywall_submit ELSE 0 END) AS is_paywall_submit,
           MAX(CASE WHEN v.event_date <= CAST(TO_DATE('${end_date}', 'yyyymmdd') AS DATE) THEN v.is_login ELSE 0 END) AS is_login,
           MAX(CASE WHEN DATEDIFF(v.event_date, d.device_first_date, 'dd') = 1 THEN 1 ELSE 0 END) AS is_active_d1,
           MAX(CASE WHEN DATEDIFF(v.event_date, d.device_first_date, 'dd') = 7 THEN 1 ELSE 0 END) AS is_active_d7
    FROM clean_device d
    INNER JOIN device_event_day v ON d.device_id = v.device_id
    WHERE v.event_date >= d.device_first_date
    GROUP BY d.device_id
),
-- ⑦ 设备级汇总：以合格设备为主表，挂不上用户、对不上埋点的设备各项指标记 0
device_level_metrics AS (
    SELECT d.device_id, d.group_label, d.device_first_date, 1 AS k,
           CASE WHEN a.device_id IS NOT NULL THEN 1 ELSE 0 END AS has_user,
           COALESCE(a.user_cnt, 0) AS user_cnt,
           COALESCE(n.is_event_matched, 0) AS is_event_matched,
           COALESCE(n.is_paywall_expose, 0) AS is_paywall_expose,
           COALESCE(n.is_paywall_submit, 0) AS is_paywall_submit,
           COALESCE(n.is_login, 0) AS is_login,
           COALESCE(n.is_active_d1, 0) AS is_active_d1,
           COALESCE(n.is_active_d7, 0) AS is_active_d7,
           COALESCE(a.is_signup, 0) AS is_signup,
           COALESCE(a.is_pay, 0) AS is_pay,
           COALESCE(a.pay_amount_usd, 0) AS pay_amount_usd,
           COALESCE(a.pay_order_cnt, 0) AS pay_order_cnt,
           COALESCE(a.is_new_purchase_pay, 0) AS is_new_purchase_pay,
           COALESCE(a.new_purchase_amount_usd, 0) AS new_purchase_amount_usd,
           COALESCE(a.is_first_sub_pay, 0) AS is_first_sub_pay,
           COALESCE(a.first_sub_amount_usd, 0) AS first_sub_amount_usd,
           COALESCE(a.renewal_amount_usd, 0) AS renewal_amount_usd,
           COALESCE(a.is_create, 0) AS is_create,
           COALESCE(a.creation_task_cnt, 0) AS creation_task_cnt,
           COALESCE(a.submit_task_cnt, 0) AS submit_task_cnt,
           COALESCE(a.success_task_cnt, 0) AS success_task_cnt,
           COALESCE(a.adopted_task_cnt, 0) AS adopted_task_cnt,
           COALESCE(a.credit_consume, 0) AS credit_consume,
           COALESCE(a.gen_duration_sec, 0) AS gen_duration_sec,
           COALESCE(a.is_creation_d1, 0) AS is_creation_d1,
           COALESCE(a.is_creation_d7, 0) AS is_creation_d7
    FROM clean_device d
    LEFT JOIN device_attr a   ON d.device_id = a.device_id
    LEFT JOIN device_native n ON d.device_id = n.device_id
),
-- 金额 P95：在全部合格付费设备上计算，两组同一阈值
cap AS (
    SELECT 1 AS k, PERCENTILE_APPROX(CAST(pay_amount_usd AS DOUBLE), 0.95) AS p95
    FROM device_level_metrics
    WHERE pay_amount_usd > 0
)
-- 分组汇总。做显著性检验时，把这里换成 SELECT * FROM device_level_metrics 导出设备明细，
-- 交给 maxcompute-ab-analysis（SRM、t 检验 / 比率指标 delta 方法、BH 校正）
SELECT m.group_label,
       COUNT(1) AS device_cnt,                                    -- 分母：合格曝光设备（SRM 用）
       SUM(m.has_user) AS user_linked_device_cnt,
       SUM(m.is_event_matched) AS event_matched_device_cnt,
       SUM(m.is_paywall_expose) / COUNT(1) AS paywall_expose_rate,
       SUM(m.is_paywall_submit) / COUNT(1) AS paywall_submit_rate,
       SUM(m.is_login) / COUNT(1) AS login_rate,
       SUM(m.is_signup) / COUNT(1) AS signup_rate,
       SUM(m.is_active_d1) / COUNT(1) AS active_d1_rate,
       SUM(m.is_pay) / COUNT(1) AS pay_rate,
       SUM(m.new_purchase_amount_usd) / COUNT(1) AS new_purchase_gmv_per_device,
       SUM(m.pay_amount_usd) / COUNT(1) AS gmv_per_device,
       SUM(CASE WHEN m.pay_amount_usd > c.p95 THEN c.p95 ELSE m.pay_amount_usd END) / COUNT(1) AS gmv_p95_per_device,
       SUM(m.is_first_sub_pay) / COUNT(1) AS first_sub_rate,
       SUM(m.is_create) / COUNT(1) AS create_rate,
       SUM(m.creation_task_cnt) / COUNT(1) AS tasks_per_device,
       SUM(m.success_task_cnt) / COUNT(1) AS success_tasks_per_device,
       SUM(m.success_task_cnt) / NULLIF(SUM(m.creation_task_cnt), 0) AS task_success_rate,
       SUM(m.adopted_task_cnt) / NULLIF(SUM(m.creation_task_cnt), 0) AS task_adopt_rate,
       SUM(m.is_creation_d1) / COUNT(1) AS creation_d1_rate,
       SUM(m.credit_consume) / COUNT(1) AS credit_per_device,
       SUM(m.pay_amount_usd) AS gmv_usd,
       SUM(m.new_purchase_amount_usd) AS new_purchase_gmv_usd,
       SUM(m.renewal_amount_usd) AS renewal_gmv_usd,
       SUM(m.creation_task_cnt) AS creation_task_cnt
FROM device_level_metrics m
INNER JOIN cap c ON m.k = c.k
GROUP BY m.group_label
ORDER BY m.group_label;

-- ============================================================================
-- 诊断（与上面共用 ①–⑤ 的 CTE，把最后的 SELECT 换成下面这段）：
-- 每组的设备串组、用户串组和被剔除用户的 GMV，作为跨设备污染的监控指标
-- ============================================================================
-- SELECT g.group_label,
--        COUNT(DISTINCT g.device_id) AS exposed_device_cnt,
--        COUNT(DISTINCT CASE WHEN f.device_group_cnt > 1 THEN g.device_id END) AS cross_group_device_cnt,
--        COUNT(DISTINCT e.user_id) AS linked_user_cnt,
--        COUNT(DISTINCT CASE WHEN u.user_group_cnt > 1 THEN e.user_id END) AS cross_group_user_cnt,
--        COUNT(DISTINCT CASE WHEN u.user_group_cnt = 1 AND u.user_device_cnt > 1 THEN e.user_id END) AS multi_device_clean_user_cnt
-- FROM (SELECT DISTINCT device_id, group_label FROM exp_raw WHERE device_id IS NOT NULL) g
-- INNER JOIN device_first f ON g.device_id = f.device_id
-- LEFT JOIN device_user_exp e ON g.device_id = e.device_id AND g.group_label = e.group_label
-- LEFT JOIN user_map u ON e.user_id = u.user_id
-- GROUP BY g.group_label;
