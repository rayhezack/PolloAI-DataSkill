# Section 04：创作域的 3 日采纳与临时口径

日期：2026-11-26。状态：DS 已评审。评审人：DS。评审日期：2026-11-26。对应 OQ-10/20；当天采纳选表另转 OQ-21。

**本节目标：确认当前创作域可以交付哪些指标，以及哪些指标必须带临时口径说明。**

## 已确认的结论

- 3 日采纳继续使用，不额外加创建成熟期限制；与当天采纳分别定义。
- 当天采纳纳入一期。你已提供行为表 `mc_prd.dwd_pollo_behavior_base_content_dip` 和 Web/App 的事件识别 SQL，不再索要已给出的信息。
- 请求任务数、成功任务数、积分消耗获准带限制进入 `pilot`；原子 3 日采纳任务/作品数也按当前批准范围试用，不代表全域或 SQL 已核验。
- Codex 已读最新代码 main@29f9758，发现作品关联与采纳日 DWS 已建，相关数仓修正也已写入代码。部署、历史回刷与结果仍待核验。

以下保留评审背景、你的原始结论和参考 SQL。

## 当前现状（评审前）

Section 03 已完成创作渗透率的场景拆分：大盘使用 M-CRE-009，分析链路使用 M-CRE-020/021；创作主表继续使用 T-006。

创作域剩余问题集中在三类：

| 类别 | 当前状态 | 影响 |
|---|---|---|
| 3 日采纳 | `adopted_output_cnt_3d` 按任务创建日归属，采纳行为为下载、分享或复用任一；你已要求暂用 3 日采纳口径，不再额外标成熟期 | 可用于当前创作域指标，但不能回答“当天发生的采纳任务数” |
| 当天采纳 | 需要按采纳发生日关联采纳事件与作品，再关联任务；当前没有要纳入本库的独立表建设 | M-CRE-019 暂不对外输出，不能用 3 日采纳替代 |
| 临时口径 | 请求任务数、成功任务数、积分消耗受数仓字段修复影响 | 可用于有限试用，但交付必须带限制说明；是否进入 pilot 需 DS 定 |

此外，本库与数仓核心指标登记表在作品采纳率、任务成功率、创作任务数/UV 上仍有 3 处定义差异，尚未完成数值对账。

## 你现在要做什么

### 1. 确认 3 日采纳的当前使用范围

**已有结论：** 先使用 `adopted_output_cnt_3d` 计算 3 日采纳任务数和 3 日采纳作品数；不额外加“创建满 3 天”的成熟期限制；被问到“当天采纳”时，不得用它代替。

**你的结论：** 同意按上述临时范围使用。

### 2. 确认当天采纳是否暂缓

当前 `M-CRE-019 当天采纳任务数` 没有可直接引用的表卡和核验 SQL。建议：保留为草稿，直到数仓建设或明确提供采纳事件、作品和关联键；一期交付不输出该指标。

**你的结论：**纳入一期

参考SQL：
```sql
behavior_events AS (
    SELECT
        event_id,
        CAST(event_time AS DATETIME) AS adopt_time,
        UPPER(COALESCE(NULLIF(TRIM(platform_type), ''), 'OTHER')) AS platform_type,
        LOWER(GET_JSON_OBJECT(properties, '$.button_name')) AS button_name,
        NULLIF(TRIM(GET_JSON_OBJECT(properties, '$.content_id')), '') AS content_id,
        NULLIF(TRIM(GET_JSON_OBJECT(properties, '$.video_id')), '') AS video_id
    FROM mc_prd.dwd_pollo_behavior_base_content_dip
    WHERE p_date BETWEEN '${start_date}'
                         AND TO_CHAR(DATEADD(TO_DATE('${end_date}', 'yyyymmdd'), 3, 'dd'), 'yyyymmdd')
      AND TO_CHAR(event_time, 'yyyymmdd') BETWEEN '${start_date}'
                                               AND TO_CHAR(DATEADD(TO_DATE('${end_date}', 'yyyymmdd'), 3, 'dd'), 'yyyymmdd')
      AND event_id IN ('content_click', 'content_download')
),

adoption_events AS (
    -- WEB：content_click，作品 ID 在 content_id。
    SELECT
        content_id AS video_id,
        adopt_time,
        CASE WHEN button_name RLIKE '^download' THEN 1 ELSE 0 END AS is_download,
        CASE WHEN button_name RLIKE '^share' THEN 1 ELSE 0 END AS is_share,
        CASE
            WHEN button_name RLIKE '^(create_similar|imagetoimage|imagetovideo)' THEN 1
            ELSE 0
        END AS is_reuse
    FROM behavior_events
    WHERE event_id = 'content_click'
      AND platform_type NOT IN ('IOS', 'ANDROID')
      AND button_name RLIKE '^(download|share|create_similar|imagetoimage|imagetovideo)'
      AND content_id IS NOT NULL

    UNION ALL

    -- APP：下载使用 content_download，作品 ID 在 video_id；不再叠加 APP content_click。
    SELECT
        video_id,
        adopt_time,
        1 AS is_download,
        0 AS is_share,
        0 AS is_reuse
    FROM behavior_events
    WHERE event_id = 'content_download'
      AND video_id IS NOT NULL
),
```

### 3. 确认临时口径能否进入 pilot

以下指标可以进入有限试用，但必须在结果中注明当前处理：

- 请求任务数：数仓新增“是否已提交给厂商”列前，用 `submit_time IS NOT NULL`，会漏掉语音转写。
- 成功任务数：语音转写成功但没有作品时，当前 `is_success_by_output` 会低估成功数，数仓处理中。
- 积分消耗：返还字段修正前暂只算成功任务，不能直接把全部有效任务的 `credit_consume` 当净消耗。

**你的结论：** 允许带限制进入 pilot。

## 你需要评审什么

- 3 日采纳是否继续作为当前创作域的默认采纳口径。
- 当天采纳是否暂缓，不用现有 3 日字段替代。
- 临时口径是否允许有限试用；如果允许，需接受每次交付带“临时口径”说明。
- Section 05 再评本库与数仓登记表的 3 处差异及创作域整体锁定，不在本节重复决策。

## 回复模板

```text
3日采纳：同意
当天采纳：纳入一期，你参考上方的信息。
临时口径：允许带限制进入 pilot。
```

## 评审后我会做什么

1. 更新 M-CRE-004/006/019、DW-03~05 和相关陷阱说明。
2. 已将请求任务数、成功任务数、积分消耗及获准使用的 3 日采纳任务/作品数设为 pilot，记录评审人和日期；查询仍须核对生产列与限制，未标成 verified。
3. 当前进入 [Section 05：当天采纳的默认表与过滤](Section05_创作域_当天采纳选表.md)，因为新代码已提供完整汇总实现。旧登记表差异及全域锁定后续单列。

关联文件：[创作指标](../L2_metrics/creation.yaml)、[创作域评审包](R1_创作域.md)、[数仓待办](../governance/dw_issues.md)、[待拍板事项](../governance/open_questions.md)。
