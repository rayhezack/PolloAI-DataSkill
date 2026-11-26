# 创作域生产代码核查记录

核查日期：2026-11-26。远程仓库：`awesomeaicode/pollo/bigdata_etl`。分支：main。固定提交：`29f97589bc61d7537844958bb646ea4e9fd4b052`。

获取方式：CNB CLI 的 `git get-branch` 读取提交；`git get-archive` 下载固定提交归档。技能脚本的 Git 访问仍报 Repository Not Found，API 返回 200。读取在独立临时目录完成，未改动生产仓库。

**代码核查与生产查询分开记录：** 下方已补 Section 05 的生产只读样本，成功访问 3 个分区；尚未完成全部历史回刷及明细全链路对账，不能将样本通过表述为全量验收。

## 当天采纳链路

| 生产文件 | 已查明的内容 |
|---|---|
| `pollo/02_数仓/DWD/Sq_dwd_pollo_behavior_base_content_dip.sql` | 行为属性位于 properties JSON；content_click 的作品为 content_id，content_download 为 video_id；行为事件 record_id 不能当作任务 ID |
| `bigdata_dw/02_DWD/creation/Sq_dwd_pollo_creation_adopt_event_dip.sql` | 统一采纳识别；`is_app_click = 0` 排除 App 的重复点击事件；事件自带 task_record_id 不用于最终任务归属 |
| `bigdata_dw/03_DWS/creation/Sq_dws_pollo_creation_user_adopt_daily_dip.sql` | 事件 video_id 关联作品事实 `dwd_pollo_creation_work_dip.video_id`，取 record_id 再关任务；按采纳日聚合，不要求任务当天创建，不要求作品成功或限制采纳距创建的时间 |

DWS 的粒度为：采纳日 × 用户 × 登录状态 × 任务端 × Web 子端 × 请求国家 × 任务类型 × 有效标记 × 成功标记。`adopt_date_task_cnt` 为任务去重数；`adopt_date_output_cnt` 为作品去重数。

DWS 可按 `is_valid_task`、`is_success_task` 筛选。宽口径包含内部/无效任务，且剔除任务 user_id 为空的记录；Section 05 已确认默认使用该 DWS 且必须限定 is_valid_task=1；成功状态一致性由 Codex 核查，不重新向 DS 提交默认有效性的选项。生产代码称作品事实从 20260101 起收录有完成时间的作品，因此仍存在关联缺口，不可将代码中的历史估算率当本次核验率。

## 临时口径对应的修复

证据文件：`bigdata_dw/02_DWD/creation/Sq_dwd_pollo_creation_task_dip.sql` 及同目录 DDL。

| 项目 | 最新代码 | 本库处理 |
|---|---|---|
| 请求任务标志 | `is_submitted_to_provider`：submit_time 非空，或语音转写且执行记录数大于 0。代码特别说明 provider_task_id 为工作流 ID，失败也有值，不能仅凭它判断已提交 | 保留已批准的 submit_time 临时算法；核验字段及回刷后再切换，不擅自扩大为任意 provider_task_id 非空 |
| 成功判定 | 语音转写按最新 succeed 状态判成功；其他任务仍看成功作品 | 同名字段在新旧数据可能有不同实现，须记录生效日及回刷范围 |
| 积分返还 | return_credit 已取积分流水返还；credit_consume 为扣减毛额，净消耗是 `credit_consume - return_credit` | 不把新 credit_consume 当净额；临时成功任务口径仍带说明，生产核验后按已确认净消耗目标切换 |
| 3 日采纳字段 | 旧字段 `adopted_output_cnt_3d` 在代码/DDL 中改名为 `create_date_adopted_output_cnt_3d`，显式表示按任务创建日归属 | 结构化指标改为新字段，并在表卡记录旧名；生产列可查性待核验，不能自动假定兼容旧名 |

## 待完成的技术核验

1. 对新旧字段执行生产 schema 检查，确认调度部署、生效日和历史回刷。
2. 运行 K-103，检查作品多任务映射、作品/任务关联覆盖率，以及 DWS 宽/有效/成功口径的差异。
3. 对临时指标修复前后和代表性历史日期对账，结果附固定查询、数据截至时间和口径限制。
4. 未完成核验前，不把代码证据写成 verified，不用历史 9.9 万替代新金标。

## Section 05 生产样本（2026-11-26）

首次调用因公司 WARP 内网连接不可用而失败；用户连接后重试成功。查询实例：`20261126135817577gu6nke01999`。完整查询见 [样本 SQL](../L5_evals/evidence/section05_adoption_sample.sql)，保存的聚合结果见 [样本 JSON](../L5_evals/evidence/section05_adoption_sample_result.json)。

| 采纳日 | 有效采纳任务数（默认口径） | 额外筛成功后的任务数（仅诊断） | 成功标志非 1 的有效采纳任务数 |
|---|---|---|---|
| 2026-10-31 | 100,856 | 100,848 | 8 |
| 2026-11-24 | 96,365 | 96,343 | 22 |
| 2026-11-25 | 89,998 | 89,979 | 19 |

因此 `is_valid_task`、`is_success_task`、`adopt_date_task_cnt` 和 `adopt_date_output_cnt` 已在上述生产查询中成功解析。DS 已定默认必须限定有效任务；右两列只是诊断，不能把它们变成未经确认的删数规则。已将状态不一致登记为 DW-06。

另按完整表粒度检查同三个分区，额外重复行均为 0，查询与结果见 [粒度 SQL](../L5_evals/evidence/section05_adoption_grain.sql) 及 [粒度结果](../L5_evals/evidence/section05_adoption_grain_result.json)。T-012 与 M-CRE-019 据 DS 已评审定义和上述样本进入 pilot；K-103 全历史作品/任务明细对账未运行，不标为 verified。

## 修复字段的生产样本与历史限制

同日执行 [字段核验 SQL](../L5_evals/evidence/section05_creation_fields.sql)，[结果 JSON](../L5_evals/evidence/section05_creation_fields_result.json) 保存全部聚合列。首次结果读取因 PyODPS 缺 pandas 无法解码 TIMESTAMP，改为 `CAST(MAX(etl_time) AS STRING)` 后成功，未安装依赖或改服务器。

| 任务创建日 | 旧 submit_time 请求数 | 新请求标志数 | 返还积分 | 旧成功任务临时消耗 | 毛额减返还的净消耗 | 最新任务 ETL |
|---|---|---|---|---|---|---|
| 2026-10-31 | 234,363 | 0 | 41 | 3,869,181.50 | 4,882,562.47 | 2026-11-04 |
| 2026-11-24 | 234,003 | 234,217 | 908,834 | 4,006,399.06 | 3,978,654.44 | 2026-11-26 |
| 2026-11-25 | 236,453 | 236,676 | 717,304 | 3,907,495.91 | 3,891,942.34 | 2026-11-26 |

11-24/25 的成功转写数分别为 215/223，按成功标志误判的样本数均为 0；新请求标志、返还和改名后的 3 日采纳列均可查询。

**历史分区不能直接套新算法：** 10-31 最新任务 ETL 为 11-04，早于 11-25 修复，新标志统计为 0；不能将“字段存在”当作“旧分区已回刷”。因此 DW-01/04/05 更新为“近期样本已生效、历史回刷未完成核验”，本库暂保留已获 DS 批准的临时算法，后续由 Codex 核对回刷覆盖和衔接方式，不能直接用 10-31 的毛额减 41 当作已修复净消耗。
