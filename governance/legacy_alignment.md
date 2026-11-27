# 存量知识对照（初版）

来源：CNB `awesomeaicode/pollo/bigdata_etl` main@`d8753d1`（2026-11-25 通过 CNB API 下载归档读取）。仓库 `ai_workspace/knowledge/` 下已有数仓维护的口径资产，本库不应另起一套。本页只记录 2026-11-25 首次读到时发现的**差异**，尚未做完整对照（计划 Step 0）。

## 仓库里的口径资产

| 文件 | 状态 | 自我定位 |
|---|---|---|
| `ai_workspace/knowledge/data-warehouse/core-metric-registry.md` | verified 2026-11-20 | 核心指标「唯一的口径登记处」，离线 ADS、实时表、告警、看板都引用 |
| `ai_workspace/knowledge/data-warehouse/ssot-rule-registry.md` | — | 汇率、端、风控、内部账号等规则的唯一实现（R01~R36） |
| `ai_workspace/knowledge/data-warehouse/table-selection-guide.md` | — | 取数选表指引 |
| `ai_workspace/knowledge/legacy-caliber/ad-delivery.md` | verified 2026-11-21 | 广告投放花费、归因、CAC/ROAS 口径，冲突以代码为准 |

## 已发现的差异

| # | 指标 | 本库（来源） | 仓库登记表 | 处理 |
|---|---|---|---|---|
| 1 | 原“访问注册率”同名差异 | 当日注册 ÷ 当日访客 UV，现命名访客注册转化率 M-USR-003 | login_visitor_cnt / dau，现单独命名访客登录占比 M-USR-009 | Section 06 / OQ-14 已决：都保留、分别命名；历史裸词先确认 |
| 2 | 作品采纳率 | 采纳作品 ÷ **成功**作品（R1 创作域 Q2 DS） | 3 日内被采纳的作品 ÷ **生成**作品（R16，创作日报） | 沿用已有 DS 定义，Codex 对账并登记看板差异；不重复提交既定口径 |
| 3 | 任务成功率 | `is_success_by_output`，创作任务表（R0 B-11 DS SQL） | 最新状态 succeed（R15），创作日报 `backend_task_success_cnt / backend_task_create_cnt` | 沿用已有 DS 定义，Codex 对账并登记看板差异；不重复提交既定口径 |
| 4 | 创作任务数 / 创作 UV | 创作任务表 `is_valid_task = 1`（R0 C2） | 创作日报 `backend_task_create_cnt`（任意状态）/ `backend_task_create_uv` | 沿用已有 DS 定义，Codex 对账并登记看板差异；不重复提交既定口径 |
| 5 | GMV | 有效订单，不要求金额 > 0（R1 Q4），含 API（R1 创作域 Q1） | 实收 > 0、非风控单（R02、R07），经营日报 `gross_pay_amount` | 差异约 4 笔 0 元单；API 是否含待对照 |
| 6 | 留存 | 访客留存用活跃日报 `retain_Nd`（dau 群） | 「访问留存」用留存日报 `user_group = 'visit'`（page_view 人群） | 两种人群，见 M-USR-007 |
| 7 | 广告 GMV 起算日 | DS：自首次注册日起，D0/D3/D7/D30 | 投放日主表从投放日起算，无 D3/D7；注册日 cohort 表才从注册日起算 | Section09 已决：两表都收，默认投放日 T-010；注册 cohort/D3/D7/支持的下钻用 T-008，不能混窗口 |
| 8 | 渗透率分母 | 登录 DAU（付费墙表 `is_active`） | 登录活跃 UV `login_active_user_cnt` | 一致：10/31 两者都是 96,695 |

## 已确定的总原则（2026-11-26）

DS 在 [Section 01](../review/Section01_口径维护与冲突裁决.md) 选择方案 A：本库维护经评审的最终业务定义，旧指标登记表逐步改为引用。DS 决定业务语义、指标算法及核心使用表；Codex 负责文档、配置和核验。OQ-16 已决，生产侧引用迁移另行协调。

上表是首次对照时的历史记录，7 处具体差异仍需按域核验与评审。第 8 行原记录为一致，但 DS 后续要求创作渗透率分母使用埋点表，其来源及去重已在 Section 02 / OQ-17 确认为 T-007 非空 uid 去重；Section 03 / OQ-18 已拆为大盘独立计数与分析链路匹配，历史一致性记录不能替代新口径对账。

## 广告域增量差异（2026-11-27）

本轮复核 CNB 最新 main@`29f97589bc61d7537844958bb646ea4e9fd4b052`，读取两张广告生产 SQL 及 `ad-delivery.md`。Section09 选择两表分工，并明确 CAC：Web 固定 D0 注册，App 固定安装。仓库说明中的同窗口注册分母不再作为本库默认 CAC；生产侧尚未修改。LTV/ROI 衔接另待 OQ-22，不因旧仓库文档存在恒等式就自动采用。

## 最新广告裁决（覆盖上节历史CAC，2026-11-27）

仅Web：大盘CAC为当天Web全部广告成本/当天Web总注册（含自然与广告注册、排除内部用户）。成本取T-010、注册取T-009，不套用生产归因CAC的注册窗口或P-41平台白名单。App本轮不包含。内部ROI已删除、历史M-AD-008编号不复用；ROAS独立为M-AD-013。生产代码仍是实现证据，未因本库文档更新而变更。
