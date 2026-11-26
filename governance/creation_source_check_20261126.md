# 创作域生产代码核查记录

核查日期：2026-11-26。远程仓库：`awesomeaicode/pollo/bigdata_etl`。分支：main。固定提交：`29f97589bc61d7537844958bb646ea4e9fd4b052`。

获取方式：CNB CLI 的 `git get-branch` 读取提交；`git get-archive` 下载固定提交归档。技能脚本的 Git 访问仍报 Repository Not Found，API 返回 200。读取在独立临时目录完成，未改动生产仓库。

**本记录证明代码中存在以下实现，不证明生产字段已同步、调度已生效或历史已回刷。未执行 MaxCompute 查询。**

## 当天采纳链路

| 生产文件 | 已查明的内容 |
|---|---|
| `pollo/02_数仓/DWD/Sq_dwd_pollo_behavior_base_content_dip.sql` | 行为属性位于 properties JSON；content_click 的作品为 content_id，content_download 为 video_id；行为事件 record_id 不能当作任务 ID |
| `bigdata_dw/02_DWD/creation/Sq_dwd_pollo_creation_adopt_event_dip.sql` | 统一采纳识别；`is_app_click = 0` 排除 App 的重复点击事件；事件自带 task_record_id 不用于最终任务归属 |
| `bigdata_dw/03_DWS/creation/Sq_dws_pollo_creation_user_adopt_daily_dip.sql` | 事件 video_id 关联作品事实 `dwd_pollo_creation_work_dip.video_id`，取 record_id 再关任务；按采纳日聚合，不要求任务当天创建，不要求作品成功或限制采纳距创建的时间 |

DWS 的粒度为：采纳日 × 用户 × 登录状态 × 任务端 × Web 子端 × 请求国家 × 任务类型 × 有效标记 × 成功标记。`adopt_date_task_cnt` 为任务去重数；`adopt_date_output_cnt` 为作品去重数。

DWS 可按 `is_valid_task`、`is_success_task` 筛选。宽口径包含内部/无效任务，且剔除任务 user_id 为空的记录；默认过滤由 Section 05 DS 裁决。生产代码称作品事实从 20260101 起收录有完成时间的作品，因此仍存在关联缺口，不可将代码中的历史估算率当本次核验率。

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
