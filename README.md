# Pollo 取数业务知识库（semantic）

一套给 AI 和人共用的取数口径，目标是形成统一事实源（SSOT）。协作仓库：[rayhezack/PolloAI-DataSkill](https://github.com/rayhezack/PolloAI-DataSkill)。DS 已确定由本库维护经评审的最终定义，旧指标登记表逐步改为引用；当前仍处于分域评审阶段（Section 01 / OQ-16）。

## 协作入口

- 新成员先读 [接续与评审路线](review/00_Codex接续与评审路线.md)，了解当前进度和待评审内容。
- 逐节评审从 [Section 01：口径维护与冲突裁决](review/Section01_口径维护与冲突裁决.md) 开始，每节说明现状、需要的决定和评审内容。
- Section 02~05 业务口径已评审；当前待评：[Section 06：用户域——访问注册率的命名与含义](review/Section06_用户域_访问注册率命名.md)。
- 环境安装、分支和 Pull Request 流程见 [协作指南](CONTRIBUTING.md)。
- 安装校验依赖：`python3 -m pip install -r requirements.txt`；在仓库根目录执行 `python3 scripts/lint.py`。
- 提交文件不代表口径已通过评审，使用前必须检查条目状态。

## 给 AI 的硬规则（优先级最高）

**评审权责**：DS 决定业务语义、指标算法及核心使用表；Codex 按结论维护文档、配置、SQL 和核验。生产代码与数仓说明用于提供实现证据，不能自动替代 DS 的选表与口径决定。

**裁决顺序**：在条目已评审且适用于当前问题的前提下，本库 L2 指标/维度与 L4 核验 SQL > L3 陷阱条款 > 生产代码与源 SQL > 个人习惯和历史报表。仍未裁决的冲突须明确说明并提交 DS，不得自行选一方覆盖；个人习惯和历史报表不能作为口径依据。

| # | 规则 |
|---|---|
| R1 | 取数前先定口径 ID（`M-`/`D-`/`K-`），结论里必须写明。没有 ID 的数字一律不可采信。 |
| R2 | 指标卡里的 `filters` 必须照搬，不得自行增删。 |
| R3 | 支付大盘默认**包含** API；只有做支付转化漏斗分析（主动付费漏斗、自动续订漏斗）时才剔除 `pay_type='API'`（R1 创作域 Q1 DS 修订，推翻 v1 和 R0 B-08 的「排除 API」）。App = `IN ('IOS','ANDROID')`，UNKNOWN 单独列出。 |
| R4 | 汇总行（ALL / 合计）不能和明细行相加。续费表是 CUBE 结构，每个维度都要钉死取值（见 P-20）。 |
| R5 | 总量和日均要显式标注。日均分母用自然日数。 |
| R6 | 去重键：用户用 `COUNT(DISTINCT user_id)`，订单用 `COUNT(DISTINCT payment_id)`，任务用 `COUNT(DISTINCT record_id)`。漏斗按人日累加。 |
| R7 | 口径没覆盖到的问题：可以借用最接近的 ID，但必须写「沿用 X + 假设」。涉及决策级指标，或命中 `governance/open_questions.md` 里的事项时，必须回问，不能自己定口径。 |
| R8 | 交付物必须写明四项：口径 ID、时间窗（UTC+8）、端别范围、过滤条件，以及单位和币种。 |
| R9 | 「新用户」「付费用户」这类裸词按 L3 术语表映射。映射不到的要回问。 |

## 检索流程（指标优先，schema 兜底）
1. 先查 `L3_glossary.yaml`，把问题里的说法映射到 M/D。
2. 命中 `L4_verified_queries/K-*.sql` 的，填参数后原样执行，并标注「核验口径」。
3. 只命中 M/D 的，读指标卡里的 `expr`/`filters`，再读对应的 `L1_datasets` 表卡，然后组装 SQL。
4. 都没命中的，读 L1 表卡写 SQL，并按 R7 处理。
5. 输出时附上 R8 要求的四项。

## 目录
```
README.md                 本文件
review/                   DS 评审包（R0 已锁定，R1 按域逐个进行）
governance/               conventions / open_questions / corrections / changelog
_schema/                  YAML 的 JSON Schema
L1_datasets/T-*.yaml      表卡
L2_dimensions.yaml        D-*
L2_metrics/<域>.yaml      M-*
L3_rules.md               G 基线 + P 陷阱
L4_verified_queries/      K-*.sql
L5_evals/golden.yaml      黄金问题集（R2 之后）
L5_evals/evidence/        已执行的样本查询及聚合结果（不等于黄金题集验收）
scripts/lint.py           校验
```

## 状态
条目状态按 `draft → pending_review → pilot → verified → deprecated` 流转。AI 最多只能把条目推进到 `pending_review`，后续状态由 DS 评审后改。只有 `verified`/`pilot` 状态的条目可以作为口径依据，其余状态的条目引用时都要标注「未评审」。
