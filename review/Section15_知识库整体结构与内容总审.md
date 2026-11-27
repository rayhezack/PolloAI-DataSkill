# Section 15：知识库整体结构总审与顺序导航

日期：2026-11-27。状态：**待总审**。

这是整个知识库的可点击审查导航。从第 0 步开始，按下表顺序打开文件；每一节列出阅读顺序、检查重点和完成标准。你可以直接在对应文件中写意见，也可以在聊天中指出文件名和条目 ID。

**本轮检查最终文件是否完整、准确地反映业务要求。Section 01~14 已确认的结论无需重复批准；发现内容不符时直接修改。黄金题和 Skill 准确率测试留到总审完成之后。**

## 一、总审顺序

| 顺序 | 审查内容与可点击入口 | 重点看什么 | 完成标准 |
|---:|---|---|---|
| 0 | [README](../README.md) → [AGENTS](../AGENTS.md) | 谁使用、如何检索、回答需交代什么 | 使用流程符合团队要求 |
| 1 | [治理约定](../governance/conventions.md) → [未决事项](../governance/open_questions.md) → [数仓待办](../governance/dw_issues.md) | 决策权责、状态、已决与待办是否清楚 | 已确认口径不会被未决或历史建议覆盖 |
| 2 | L1：本节第四部分逐一链接 12 张表卡，可先看 [用户画像表](../L1_datasets/T-009_ads_pollo_user_profile_dfp.yaml) | 用途、粒度、主键、日期、来源、过滤 | 核心表完整且分工清楚 |
| 3 | L2：[维度](../L2_dimensions.yaml) → [用户](../L2_metrics/user.yaml) → [支付](../L2_metrics/payment.yaml) → [创作](../L2_metrics/creation.yaml) → [广告](../L2_metrics/ads.yaml) → [Agent](../L2_metrics/agent.yaml) | 指标完整性、定义、算法、适用范围 | 最终指标卡符合业务要求 |
| 4 | L3：[术语](../L3_glossary.yaml) → [规则](../L3_rules.md) → [分析方法](../L3_analysis_patterns.md) | 同义词、歧义词、默认口径、错误算法 | 自然语言能落到正确指标，边界表述清楚 |
| 5 | L4：本节第七部分逐一链接 12 份 SQL 和代表性结果，可先看 [用户比率 SQL](../L4_verified_queries/K-105.sql) | SQL 是否实现指标定义，证据对应哪个日期和版本 | SQL、指标和证据相互一致 |
| 6 | 本节第八部分：检查评测资产的职责和后续顺序 | 题集、执行记录和准确率报告分别起什么作用 | 总审完成后再进入 [Section 16](Section16_R2黄金问题集与问数路由.md) |

**现在从第 0 步开始。第 2～5 步同时检查实际文件内容，不需要最后再重复审一遍五个域。**

## 二、第 0 步：使用入口

请先看：

- [README.md](../README.md)：最高优先级的评审权责、检索流程、硬规则和状态定义。
- [AGENTS.md](../AGENTS.md)：Coding Agent 实际取数时的操作顺序。
- [CONTRIBUTING.md](../CONTRIBUTING.md)：团队协作、提交和分支方式。

你只需要确认三件事：

1. 业务口径由 DS 决定，Codex 负责按结论维护文件和 SQL；
2. Agent 取数前先查术语、指标状态和 SQL 证据；
3. GitHub 是团队当前协作版本。

## 三、第 1 步：治理与裁决

请按这个顺序看：

1. [Section 01：口径维护与冲突裁决](Section01_口径维护与冲突裁决.md)
2. [治理约定](../governance/conventions.md)
3. [待拍板事项](../governance/open_questions.md)
4. [存量知识对照](../governance/legacy_alignment.md)
5. [纠错记录](../governance/corrections.md)

重点检查：

- 维护权责是否清楚；
- `draft → pending_review → pilot → verified → deprecated` 是否符合团队协作；
- “单个指标进入 pilot”和“整个 Skill 通过 R3”是否明确区分；
- 已决事项与仍待确认的事项是否分清，例如 OQ-24 的 Agent 纳入决定已通过，但来源表仍待基建落地。

## 四、第 2 步：L1 数据集

先看每张表卡的“用途、粒度、关键字段、状态、限制”，不需要先读所有字段。

### 用户

- [T-009 用户画像表](../L1_datasets/T-009_ads_pollo_user_profile_dfp.yaml)
- [T-005 用户活跃日表](../L1_datasets/T-005_ads_pollo_user_active_daily_dip.yaml)
- [T-004 用户基础表](../L1_datasets/T-004_dwd_ai_video_pollo_user_dfp.yaml)

### 支付

- [T-001 订单明细表](../L1_datasets/T-001_dwd_pollo_transaction_order_detail_view.yaml)
- [T-002 付费墙用户日表](../L1_datasets/T-002_ads_pollo_transaction_paywall_user_daily_dip.yaml)
- [T-003 续费 cohort 日表](../L1_datasets/T-003_ads_pollo_transaction_renewal_cohort_daily_dip.yaml)

### 创作

- [T-006 创作任务表](../L1_datasets/T-006_dwd_pollo_creation_task_dip.yaml)
- [T-007 事件埋点表](../L1_datasets/T-007_ods_pollo_log_event_dip.yaml)
- [T-011 内容行为表](../L1_datasets/T-011_dwd_pollo_behavior_base_content_dip.yaml)
- [T-012 用户采纳日汇总表](../L1_datasets/T-012_dws_pollo_creation_user_adopt_daily_dip.yaml)

### 广告

- [T-008 广告注册日归因表](../L1_datasets/T-008_ads_pollo_ad_attribution_daily_dip.yaml)
- [T-010 广告投放日收入表](../L1_datasets/T-010_ads_pollo_ad_attribution_delivery_daily_hip.yaml)

### Agent

Agent 当前没有正式表卡；[Agent 指标卡](../L2_metrics/agent.yaml)中的来源表全部为 `TBD`，这是已确认的基建边界，不是遗漏。

本步请回答：

- 这 12 张表的业务覆盖是否完整；
- 是否有表应该删除、合并或补充；
- 表卡中的“用途”和“不能用于什么”是否清楚。

## 五、第 3 步：L2 业务模型

先看维度，再看各域指标。

- [L2_dimensions.yaml：14 个维度](../L2_dimensions.yaml)

### 指标文件

- [用户指标](../L2_metrics/user.yaml)：注册、访客、活跃和留存
- [支付指标](../L2_metrics/payment.yaml)：GMV、订单、支付用户、续费金额和续订率
- [创作指标](../L2_metrics/creation.yaml)：任务、作品、采纳、积分和成本
- [广告指标](../L2_metrics/ads.yaml)：Web CAC、LTV、ROAS 和渠道归因
- [Agent 指标](../L2_metrics/agent.yaml)：创作北极星、商业化北极星、诊断和护栏

本步只看体系设计：

- 指标是否按业务域归类；
- 每个指标是否有完整名称、定义、公式、过滤、单位、状态和证据；
- `pilot` 是否只表示限定范围可试用；
- Agent 的 `draft/TBD` 是否明确不能用于生产取数。

指标卡阅读顺序：名称/同义词（name/synonyms）→ 业务定义与算法（definition/expr）→ 来源表（table）→ 过滤和时间（filters/time_axis）→ 单位与维度（unit/dimensions）→ 状态、限制与证据（status/disclaimer/evidence）。字段内容如不完整或与已确认结论不符，直接记录文件名和指标 ID。

前面已确认的业务结论可按需查证，无需重新批准：

- 用户：[Section 06 命名](Section06_用户域_访问注册率命名.md)、[Section 07 活跃与留存](Section07_用户域_月活与访客留存.md)、[Section 08 整体确认](Section08_用户域_整体锁定.md)。
- 支付：[Section 12 续费金额与续订率](Section12_支付域_财务续费率统计单位.md)、[Section 13 GMV 金额组成](Section13_支付域_GMV含税说明.md)。
- 创作：[Section 02 分母](Section02_创作域_注册访问UV.md)、[Section 03 分子](Section03_创作域_分子匹配口径.md)、[Section 04 采纳与临时口径](Section04_创作域_采纳与临时口径.md)、[Section 05 当天采纳](Section05_创作域_当天采纳选表.md)。
- 广告：[Section 09 选表](Section09_广告域_表分工与CAC.md)、[Section 10 LTV/ROAS](Section10_广告域_LTV与ROI衔接.md)、[Section 11 Web 范围](Section11_广告域_Web试用范围.md)。
- Agent：[Section 14 业务定义与基建待办](Section14_Agent域_指标纳入与基建待办.md)。

## 六、第 4 步：L3 语义与规则

请按这个顺序看：

1. [L3_glossary.yaml：术语、歧义词和删除词](../L3_glossary.yaml)
2. [L3_rules.md：基线和陷阱规则](../L3_rules.md)
3. [L3_analysis_patterns.md：分析方法](../L3_analysis_patterns.md)
4. [Google Ads 官方口径调研](GoogleAds_CAC与ROAS_官方口径调研.md)

重点检查：

- “CAC、续费率、访问注册率”等歧义词是否会先回问；
- ROI 删除后是否不会被自动映射成其他指标；
- Web 广告和 App 范围是否清楚；
- 分析方法是否与指标定义分开，没有偷偷新增业务指标。

## 七、第 5 步：L4 执行资产

先看模板状态，再看 SQL 内容。目录名 `L4_verified_queries` 不代表每个 SQL 都已经验证。

### 当前可限定试用的模板

- [K-107 Web 大盘 CAC](../L4_verified_queries/K-107.sql)
- [K-109 Web 投放日 LTV/ROAS](../L4_verified_queries/K-109.sql)
- [K-110 Web 渠道 CAC](../L4_verified_queries/K-110.sql)
- [K-112 续费金额与用户续订率](../L4_verified_queries/K-112.sql)

### 当前仍为 pending_review 的模板

- [K-101 设备实验 SQL](../L4_verified_queries/K-101.sql)
- [K-102 创作渗透率对照](../L4_verified_queries/K-102.sql)
- [K-103 当天采纳对账草稿](../L4_verified_queries/K-103.sql)
- [K-104 当天采纳默认 SQL](../L4_verified_queries/K-104.sql)
- [K-105 用户比率](../L4_verified_queries/K-105.sql)
- [K-106 活跃与留存](../L4_verified_queries/K-106.sql)
- [K-108 注册日 cohort GMV](../L4_verified_queries/K-108.sql)
- [K-111 历史续费对照](../L4_verified_queries/K-111.sql)

本步只检查：

- SQL 是否写明参数、端别、时间窗口、过滤和单位；
- SQL 状态是否与证据一致；
- NULL、未成熟日期、零分母和缺失成本是否被正确处理；
- 模板是否会误导 Agent 把历史对照 SQL 当成当前业务口径。

代表性执行证据，按需与模板对照：

- [用户比率结果](../L5_evals/evidence/section06_user_ratios_result.json)、[用户活跃与留存结果](../L5_evals/evidence/section07_user_retention_sample_result.json)。
- [续费金额与用户续订率结果](../L5_evals/evidence/section12_renewal_amount_user_rates_result.json)。
- [当天采纳结果](../L5_evals/evidence/section05_adoption_sample_result.json)、[创作字段检查结果](../L5_evals/evidence/section05_creation_fields_result.json)。
- [Web 大盘 CAC 结果](../L5_evals/evidence/section11_paid_cac_total_result.json)、[Web 渠道 CAC 结果](../L5_evals/evidence/section11_paid_cac_channels_result.json)、[Web D30 LTV/ROAS 结果](../L5_evals/evidence/section11_web_ltv_roas_d30_result.json)。

## 八、第 6 步：只看评测资产的职责与后续顺序

- [Section 16：黄金题评审说明](Section16_R2黄金问题集与问数路由.md)：留待本节总审完成后阅读。
- [黄金题集](../L5_evals/golden.yaml)：38 道待评审题及预期行为，本轮不逐题评审。
- [R2 结构校验报告](../L5_evals/reports/R2_draft_check.json)
- [结构校验脚本](../scripts/check_golden.py)：技术细节由 Codex 检查，你无需逐行审代码。

当前检查仅验证：

- 题目能引用已存在的指标、表和评审文档；
- 固定历史值能和保存证据匹配；
- 题集已写入 Agent 域没有生产表时的预期处理方式；Agent 是否遵守仍须实测。

当前 L5 还不能证明：

- Skill 已经正确回答题目；
- 生产 SQL 一定能重新运行；
- 任何域已经通过 R3。

## 九、审查意见怎么记录

- 结构没有问题：`第 X 步评审完毕`
- 需要修改：`第 X 步：修改 [文件名] 的 [具体内容]`
- 需要新增内容：`第 X 步：新增 [业务场景/指标/表]`
- 发现业务口径问题：`第 X 步：指标 ID / 文件名 + 我的新口径`

我会保留你的原始意见，将修改落实到对应文件，校验后告诉你下一步从哪个文件开始。

**本节的总审结论只针对知识库的结构、内容边界和审查顺序；Section 16 的黄金题评审与 Skill 准确率测试，等 Section 15 总审完成后再开始。**
