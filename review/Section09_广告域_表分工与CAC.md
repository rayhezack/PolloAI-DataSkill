# Section 09：广告域——表分工与 CAC 默认分母

创建：2026-11-26。评审完成：2026-11-27。本节对应 OQ-13、OQ-15，已按 DS 回复落地；广告全域尚未批准 pilot。

**已确认：两表都收、默认 T-010；CAC 的 Web 分母固定 D0 注册，App 分母固定安装数。下文保留评审前建议与 DS 原始回复，冲突以原始回复及文末落地记录为准。**

## 当前现状

广告域已切换到投放日主表 `mc_prd.ads_pollo_ad_attribution_delivery_daily_hip`，旧表 `mc_prd.ads_pollo_ad_attribution_daily_dip` 不再作为默认主表。两张表含义不同：

| 表 | 适用问题 | GMV 窗口 | 可用窗口/下钻 |
|---|---|---|---|
| 投放日主表 T-010 | 默认按投放日看消耗、注册、GMV、CAC、ROAS 趋势 | 从投放日起算 | D0/D14/D30/D60/D90/D180/D360/all；不能提供 D3/D7；不能完整下钻 campaign |
| 注册日 cohort 表 T-008 | 明确问注册 cohort、D3/D7 或 campaign 下钻时使用 | 从注册日起算 | D0/D3/D7/D14/D30/D60/D90/D180；不替代投放日主表的日趋势 |

当前指标卡已有这套分工的生产依据，但 M-AD-005 仍保留 OQ-15，M-AD-006~008 仍保留 OQ-13，广告域整体未进入 pilot。

## 你现在要做什么

### 1. 确认两表分工

**建议：两张表都收，默认 T-010。**

- 用户问“广告消耗、投放注册、投放日 D14/D30 GMV、按日 CAC/ROAS”时，使用 T-010。
- 用户问“注册 cohort、D3/D7、campaign/adgroup 下钻”时，使用 T-008，并在结果里写明这是注册日起算口径。
- 两张表的 D0/D14 等数字不能直接横比；回答时必须写窗口起点、数据截至日和表名。

**你的结论：** 同意两表分工、默认 T-010 。

### 2. 确认 CAC 默认分母（评审前方案，已被 DS 回复替代）

已有生产文档定义：

`CAC_N = SUM(cost_usd) / SUM(reg_user_cnt_dN)`，LTV_N 使用同一个 N 的注册用户数；看至今累计时使用 `_all`。因此 ROI/ROAS 在同一个 N 下等于归因 GMV ÷ 消耗。

**建议：默认使用与 LTV/GMV 相同窗口的注册用户数；只有用户明确问“看至今累计 CAC”时使用 `_all`。**

这会让 D0 CAC、D14 CAC、D30 CAC 分别使用 D0、D14、D30 注册用户分母，避免成本使用一个窗口、注册用户使用另一个窗口。

**你的结论：** CAC分母需要分端定，其中Web端用 `reg_user_cnt_d0`	App端用 `install_cnt`。

## 现有硬限制

- 只统计成熟窗口：`stat_date + N ≤ 昨日`；主表统计截到 T-2，不能把未结清的 App 花费混入。
- 先汇总到投放端 × 广告平台，再计算 LTV/CAC/ROAS；不能在国家、设备等细粒度直接相除。
- 回本和 CAC 只纳入人钱能对上的平台范围，具体见 P-41；APP 的 `channel='汇总'` 是明细取值，不是汇总行。
- T-008 重新纳入后，专属规则 P-33/P-34 恢复：总产品/总首购主行，平台总量不筛 match_level；不能把该规则套到 T-010。两表不能因字段名相似而混加。

## 评审后我会完成什么

1. 按结论更新 T-008/T-010 的路由规则、M-AD-004~008 的来源、窗口、分母和状态。
2. 写广告域核验 SQL，对账 T-010 的成熟窗口、T-008 的 D3/D7 和平台过滤；未成熟日期返回 NULL 或不纳入对应成熟汇总。
3. 新 CAC 与旧 LTV 分母不一致，先进入 Section10 评审 LTV/ROI 的衔接，再收口广告 pilot 范围及旧口径差异。

关联文件：[广告域原评审包](R1_广告域.md)、[广告指标](../L2_metrics/ads.yaml)、[广告表卡 T-008](../L1_datasets/T-008_ads_pollo_ad_attribution_daily_dip.yaml)、[广告表卡 T-010](../L1_datasets/T-010_ads_pollo_ad_attribution_delivery_daily_hip.yaml)。

## 本次落地与核验（2026-11-27）

- T-010 为默认投放日主表；T-008 恢复为注册日 cohort 补充表。明确问“投放日 D3/D7”时不能静默切到注册日起算；须说明不可提供该窗口或确认改用注册 cohort。
- M-AD-007：Web `SUM(cost_usd)/SUM(reg_user_cnt_d0)`；App `SUM(cost_usd)/SUM(install_cnt)`，固定分母、分端单位，不再默认把“注册成本/CPA”映射为所有端 CAC。
- 广告卡片统一 T-2，恢复 T-008 主行/匹配层级规则；all 用 `_all` 字段且仅表示截至观测日累计，首购 GMV 仅支持 D0/D14/all。
- CNB 最新 main 经核对为 `29f97589bc61d7537844958bb646ea4e9fd4b052`；生产来源与本库 DS 算法不同之处已登记，未修改生产 SQL。
- [CAC 查询样本](../L5_evals/evidence/section09_cac.sql)实跑 8 行：[结果](../L5_evals/evidence/section09_cac_result.json)。10 月 Web Google 为 $415,168.4037 ÷ 432,457 = $0.9600/注册用户；App Meta 为 $200,766.562 ÷ 156,449 = $1.2833/安装。
- [注册日 D3/D7 查询样本](../L5_evals/evidence/section09_registration_cohort.sql)实跑 17 行：[结果](../L5_evals/evidence/section09_registration_cohort_result.json)。全部 10 月 cohort 已满 D7；不代表全历史或 campaign 归因已验收。
- 表和 CAC 的业务结论已记录 DS 评审元数据，但状态维持 `pending_review`，等待广告域 pilot 范围确认。LTV/ROI 保持 `draft`，不再把旧恒等式当作已确认口径。

**下一节：** [Section10：广告域——LTV 与 ROI 的衔接](Section10_广告域_LTV与ROI衔接.md)。只评新分母带来的语义问题，无需重评本节已确认的两表分工和 CAC。
