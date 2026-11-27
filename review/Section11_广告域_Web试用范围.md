# Section 11：Web 广告域有限试用范围

日期：2026-11-27。状态：待 DS 评审。本节只确认开放范围，已定的CAC、LTV、ROAS公式不再重评。

**建议先开放已具生产样本的 Web 广告成本和大盘 CAC；LTV/ROAS 继续由 Codex 补远程核验。App 本次不包含。**

## 当前现状

| 指标 | 已确认口径 | 核验状态 |
|---|---|---|
| Web广告成本 M-AD-001 | 全部Web广告平台的成本合计 | Section10两个业务日已实跑；保留成本源账户时区说明 |
| Web大盘CAC M-AD-007 | 当天Web全部广告成本/当天Web全部注册；包含自然和广告渠道，排除内部账号 | K-107两个业务日及期间合计已实跑、重算一致 |
| Web LTV M-AD-006 | 投放日起算GMV_N/D0广告归因注册数；固定D0分母 | K-109已写，本地逻辑检查通过；本轮远程连接超时，无新生产结果 |
| Web ROAS M-AD-013 | 同批成熟投放日期的GMV_N/成本 | 同K-109，远程核验未完成 |
| ROI | 已删除 | 原M-AD-008编号不复用，检索时说明已删除，不自动替换成ROAS |

CAC样本：2026-10-31 Web成本 $19,774.8916 / Web注册30,014人 = **$0.6589/注册用户**。10-30/31两日合计CAC为 $37,032.2346 / 59,093 = $0.6267，不取两天CAC的算术平均。

## 建议你批准的范围

| 对象 | 本次建议进入pilot的用途 | 限制 |
|---|---|---|
| T-010 `mc_prd.ads_pollo_ad_attribution_delivery_daily_hip` | 仅Web广告成本字段及日期、source_end过滤用途 | 表的GMV/LTV/ROAS等其他字段不因本次批准自动进入pilot |
| M-AD-001、M-AD-007 | 仅Web每日/期间总广告成本和大盘注册CAC | CAC含全部Web广告平台成本；不套ROAS平台白名单、不做按平台归因CAC |
| K-107 | 已确认算法的Web大盘CAC模板 | 成本与注册先各自按日聚合后关联；期间用总成本/总注册 |
| T-009 `mc_prd.ads_pollo_user_profile_dfp` | 已有注册用途pilot，使用 `reg_platform='WEB'` 限定分母 | 昨日快照、已注册、排除内部用户、user_id去重；不得将快照缺失填成0 |

pilot表示可按上述限定用途试用，不表示所有历史日期都已对账，也不代表整个问数Agent通过R3验收。两个样本日验证算法与字段可执行，分区缺失和历史回刷仍须在实际取数时检查。

以下保持pending_review：LTV、ROAS、其他广告指标、注册日补充表T-008、K-108/K-109；App全部排除在本轮范围。已确认的两表分工保留，不等于补充表已经获准对外试用。

## 你现在只需评审这一项

**是否同意上述Web成本与大盘CAC进入有限pilot，LTV/ROAS继续等待远程核验？**

**你的结论：**

可以写：“同意按上述范围进入pilot。”如有例外，只写具体条目与原因。

这只是状态与试用范围批准；CAC、LTV、ROAS的业务公式以及ROI删除无需再次确认。

## 后续由 Codex 完成

1. 按回复更新限定用途的状态与评审元数据；不扩大到广告全域。
2. 数仓连接恢复后，按K-109执行Web成熟窗口核验，核对同批日期的固定D0分母与零分母处理。只有拿到结果才记录为生产核验通过；不使用本地模拟替代。
3. 继续支付域剩余增量评审，再补黄金题集与Agent验收资产。

文件：[Section10最新结论](Section10_广告域_LTV与ROI衔接.md)、[CAC模板](../L4_verified_queries/K-107.sql)、[CAC生产结果](../L5_evals/evidence/section10_web_cac_result.json)、[LTV/ROAS模板](../L4_verified_queries/K-109.sql)、[本轮核验状态](../L5_evals/evidence/section11_web_ltv_roas_check.json)、[广告指标](../L2_metrics/ads.yaml)。
