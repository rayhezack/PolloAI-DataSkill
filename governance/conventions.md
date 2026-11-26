# 规范

## ID
| 前缀 | 含义 | 例子 | 文件 |
|---|---|---|---|
| `T-nnn` | 表卡 | T-001 | `L1_datasets/T-001_<表名>.yaml` |
| `D-nnn` | 维度 | D-001 | `L2_dimensions.yaml` |
| `M-<域>-nnn` | 指标，域 ∈ PAY / CRE / USR / AD | M-PAY-001 | `L2_metrics/<域>.yaml` |
| `G-nn` / `P-nn` | 基线 / 陷阱，沿用 v1 编号续排 | P-19 | `L3_rules.md` |
| `K-nnn` | 核验 SQL，沿用 v1 编号 | K-014 | `L4_verified_queries/K-014.sql` |

- ID 一经发布不再复用。废弃条目时，把状态改为 `deprecated`，并填写 `superseded_by`。
- 条目名称用业务词，例如「支付GMV」。字段名写进 `expr`，不写进名称。

## 状态机
`draft` → `pending_review` → `pilot` → `verified` → `deprecated`，另有 `rejected`。

- AI 新建或修改条目后，状态只能是 `draft` 或 `pending_review`。
- 晋升到 `pilot`/`verified` 需要 DS 评审，并在条目里写上 `reviewed_by`、`reviewed_at`。
- `verified` 条目必须有 `evidence`（仓库路径@commit，或核验 SQL 加结果），`lint.py` 会检查。

## 变更流程
1. 发现口径问题，或者被人纠错时，先记到 `corrections.md`。
2. 改 YAML，状态回到 `pending_review`。
3. 在 `changelog.md` 记一行：日期、ID、改了什么、为什么。
4. 下次 DS 例行评审时确认。
5. 需要业务拍板的事项，进 `open_questions.md`，注明 owner。拍板之前，AI 遇到相关问题都要回问。

## 表分区后缀
| 后缀 | 含义 | 读法 |
|---|---|---|
| `_dip` | 日增量分区 | `p_date` 和业务日双约束（G-02） |
| `_dfp` | 日全量快照 | 取昨日分区 `p_date = TO_CHAR(DATEADD(GETDATE(),-1,'dd'),'yyyymmdd')`；回溯时显式指定快照日。禁止 `MAX(p_date)` |
| `_view` | 视图 | 按底表分区规则读 |
