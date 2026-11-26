# Section 02：创作域——注册访问 UV 的来源与去重方式

日期：2026-11-26。状态：分母定义 DS 已评审。评审人：DS。评审日期：2026-11-26。本节对应 OQ-17；参考 SQL 引出的分子范围差异转 Section 03。

**本节目标：把你已确定的“创作 UV ÷ 注册访问 UV”写成可执行、无歧义的取数口径。**

## 已确认的结论

- 分母主表：`mc_prd.ods_pollo_log_event_dip`。
- 过滤：`event_id IS NOT NULL`、`uid IS NOT NULL`、`uid <> ''`；所有有效事件都算访问。
- 去重：按当天的 `uid` 去重，同一账号多设备仍算 1 人。期间按人日累计或日均，不能把期间账号去重当日活。
- 定义已落为 M-USR-008，创作渗透率分母改为该指标，与付费墙登录 DAU 分开。
- 分母的业务定义已评审；指标卡记录了评审人和日期，状态暂保留 `pending_review`，以待 SQL 核验，不要求重复裁决本节分母。
- 参考 SQL 的分子限定为“访问过的人中的创作者”，与 R0 的“独立计算全部创作者”不同；同时使用了旧创作表。两项统一在 Section 03 明确，分母结论不再重复评审。

以下保留评审背景及你的原始回复。

## 当前现状（评审前）

你在 [创作域评审包](R1_创作域.md) 中已经明确：

> 创作渗透率 = 创作UV / 注册访问UV，其中分子可以用creation_task_dip宽表计算，但是分母注册访问UV要用埋点表计算。

| 部分 | 当前情况 |
|---|---|
| 分子：创作 UV | 已有 DS 结论：用 `mc_prd.dwd_pollo_creation_task_dip`，`is_valid_task = 1`，当日按 `user_id` 去重 |
| 分母：注册访问 UV | 你已指定来自埋点；现有埋点表卡记录的是 `mc_prd.ods_pollo_log_event_dip`，需你确认它是否就是核心使用表，以及按什么身份键去重 |
| 指标卡残留 | 目前仍引用付费墙日表的登录 DAU，尚未落实你的新要求；本节评审后修正 |

历史用户域回复中曾出现“埋点 did UV”，当时的 AI 又把它映射为付费墙表的用户数。因此，这次需要明确“数账号还是数设备”，避免只换表、却继续保留身份粒度歧义。

## 你现在要做什么

### 1. 确认分母使用哪张埋点表

当前候选：**`mc_prd.ods_pollo_log_event_dip`**。

这张表一行一条事件，已有表卡记录 `uid` 为登录用户 ID、`anon_id` 为匿名设备/浏览器 ID。表卡仍为待评审，不能仅凭已有卡片认定它就是你指定的核心表。

**你的结论：** 用这张表，限定event_id以及uid不为空，然后对uid去重计数。

### 2. 确认注册访问 UV 数的是“账号”还是“登录设备”

| 选项 | 业务含义与计算方式 |
|---|---|
| **A：登录账号去重（建议）** | 当天有有效访问事件的登录用户，按非空 `uid` 去重；一个账号访问多个设备仍算 1 人 |
| B：有登录行为的设备/访客去重 | 先限定有登录身份的事件，再按设备/访客 ID 去重；一个账号用多个设备可能算多次。需指定具体字段及清洗规则，不能默认把 `device_id` 和 `anon_id` 当同一个 ID |

**建议选 A 的原因：** 分子是用户账号数，分母也按账号去重时，“创作渗透率”更容易解释为账号层面的比例。如果你的业务定义本来就按设备统计，请选 B。

**事件范围草案：** 按已有表卡，`event_id IS NOT NULL`；只统计登录身份有效的事件，按 UTC+8 自然日和端限定范围。是否只取 `page_view`，以及内部用户、机器流量、异常 ID 是否另行过滤，需沿用你确认的规则。

历史核查记录（2026-10-31，本轮未重跑）：埋点表 `uid` 去重为 96,779，旧付费墙表登录 DAU 为 96,695。数值接近不能证明两种定义可以互换；历史值也未证明候选过滤规则已完整核验。

**你的结论：** A。

如果已有标准 SQL：
```sql
WITH
-- 1. 日活用户，保持基础口径不变
active_user_day AS (
    SELECT
        CAST(event_time AS DATE) AS active_date,
        CAST(uid AS STRING) AS user_id
    FROM mc_prd.ods_pollo_log_event_dip
    WHERE p_date BETWEEN '${start_date}' AND '${end_date}'
        AND to_char(event_time,'yyyymmdd') BETWEEN '${start_date}' AND '${end_date}'
      AND LOWER(platform_type) = 'web'
      AND uid IS NOT NULL
      AND uid <> ''
      AND event_id IS NOT NULL
    GROUP BY
        CAST(event_time AS DATE),
        CAST(uid AS STRING)
),

-- 2. 日粒度创作任务数，保持基础口径不变
user_creation AS (
    SELECT
        user_id,
        CAST(created_date AS DATE) AS create_date,
        COUNT(DISTINCT id) AS creation_task_cnt
    FROM mc_prd.dwd_video_pollo_video_generate_record_dfp
    WHERE p_date = MAX_PT('mc_prd.dwd_video_pollo_video_generate_record_dfp')
      AND LOWER(app_platform) = 'web'
      AND CAST(created_date AS DATE) >= CAST(TO_DATE('${start_date}', 'yyyymmdd') AS DATE)
      AND CAST(created_date AS DATE) < DATE_ADD(
            CAST(TO_DATE('${end_date}', 'yyyymmdd') AS DATE),
            1
        )
    GROUP BY
        user_id,
        CAST(created_date AS DATE)
)

SELECT
    t1.active_date,
    count(distinct t1.user_id) dau,
    count(distinct case when creation_task_cnt > 0 then user_id end) create_uv
FROM active_user_day t1
left join user_creation t2
on t1.user_id = t2.user_id and t1.active_date = t2.created_date
group by
    t1.active_date;
```

参考 SQL 原样保留；存在 `t2.created_date` 与上文别名 `create_date` 不一致、`user_id` 未限定表别名等问题，尚不能直接执行。

## 你需要评审什么（本节已完成）

- **核心表：** 上面的埋点表是否选对？最终由 DS 确定。
- **去重对象：** 一个账号用三个设备，分母应算 1 还是可能算 3？
- **访问范围：** 所有有效事件是否都算访问，还是必须命中特定事件与排除条件？

分子主表和“有有效创作任务就算创作用户”的结论已经给过，本节沿用已有结论。

## 你的回复模板

```text
分母主表：使用上述埋点表
去重方式：对uid去重
事件过滤：所有有效事件都算访问
```

## 落地与下一节

1. 已补注册访问 UV 指标卡，并更新创作渗透率分母、旧同义词及相关表卡。
2. 已准备 K-102 核验草稿，同时输出独立创作 UV、匹配创作 UV 和埋点分母，尚未远程执行，不作为已核验模板。
3. 下一节：[Section 03：创作渗透率的分子范围与创作主表](Section03_创作域_分子匹配口径.md)。

追踪位置：[创作指标卡](../L2_metrics/creation.yaml) 的 M-CRE-009；[埋点表卡](../L1_datasets/T-007_ods_pollo_log_event_dip.yaml)；[待拍板事项](../governance/open_questions.md) 的 OQ-17。
