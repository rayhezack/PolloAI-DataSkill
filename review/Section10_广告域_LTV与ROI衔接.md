# Section 10：广告域——Web CAC、ROAS 与 ROI 删除

日期：2026-11-27。状态：DS评审完成，业务裁决已确认并落地，广告全域 pilot 尚未批准。本次范围仅 Web，App 暂不包含。

**最终结论：删除内部 ROI；Web 大盘 CAC = 当天 Web 全部广告成本 ÷ 当天 Web 总注册用户数。**

## 当前生效的口径

| 项目 | 结论与落地 |
|---|---|
| CAC（M-AD-007） | 分子为T-010的 `source_end='WEB'` 全广告平台成本；分母为T-009的 `reg_platform='WEB'` 当天总注册。含自然及广告渠道，排除内部账号，按user_id去重。不是广告归因注册，也不是安装。 |
| 时间与汇总 | 广告成本按成本日、注册按注册日对齐；先各自聚合再关联。期间CAC=期间成本合计/期间注册合计，不平均每日CAC；默认截到T-2。 |
| ROAS（M-AD-013） | 保留 `SUM(GMV_N)/SUM(cost_usd)`，本轮只记录Web；成本与GMV取同批成熟投放日期及可比平台，窗口从投放日算。 |
| ROI | 内部指标删除。原M-AD-008编号退休，不复用，不再计算LTV/CAC，也不把ROI自动映射到ROAS。 |
| LTV（M-AD-006） | DS最新原文明确定义为 `SUM(GMV_N)/SUM(D0注册数)`；本轮仅Web，投放日表分母固定 `reg_user_cnt_d0`，不随N变化。已按该公式更新指标卡与K-109，不再将严格注册cohort适配作为这项已确认公式的前置。 |
| App | 不纳入本轮CAC、ROAS/LTV实施与验收；不自动套用Web定义。 |

DS 后续原始指令：

> 那就在内部删除ROI指标。
> 然后口径已经确认了，CAC的分母用的注册用户数，比如当天大盘的总CAC = 大盘总广告成本 / 当天总注册用户数。

> 注意这里是看的Web，不是全站。
> App本次先不包含在内。

以上新裁决覆盖 Section09 的“Web D0归因注册/App安装”CAC方案，以及下方历史回复中的ROI保留建议。无需重评这些已确认口径。

## 核验结果与文件

[当前CAC模板K-107](../L4_verified_queries/K-107.sql)、[实跑SQL](../L5_evals/evidence/section10_web_cac.sql)、[聚合结果](../L5_evals/evidence/section10_web_cac_result.json)。画像快照20261126，观察日20261127，成本/注册范围均为Web。

| 业务日 | Web广告成本USD | Web注册用户数 | CAC（USD/注册用户） |
|---|---:|---:|---:|
| 2026-10-30 | 17,257.3430 | 29,079 | 0.5935 |
| 2026-10-31 | 19,774.8916 | 30,014 | 0.6589 |
| 两日合计 | 37,032.2346 | 59,093 | 0.6267 |

本次只证明两个样本日算法与生产字段可执行，尚不代表全历史、分端或全域pilot验收。旧Section09样本保留为历史证据，不能用于当前CAC。

本次补充：[K-109](../L4_verified_queries/K-109.sql)已按LTV=GMV_N/D0注册及ROAS=GMV_N/成本编写；[本地边界检查](../L5_evals/evidence/section11_web_ltv_roas_logic_check.py)通过。生产查询及单独重试均连接超时，尚无本轮LTV/ROAS结果；[核验记录](../L5_evals/evidence/section11_web_ltv_roas_check.json)明确标记未完成。

**最新补充：** [Section11：范围说明与渠道CAC分母](Section11_广告域_Web试用范围.md)。大盘总CAC保留本页定义；渠道CAC另用该渠道注册人数，不能用大盘注册作分母。原有限试用审批建议已撤回，LTV/ROAS技术核验由Codex继续完成。

相关文件：[广告指标卡](../L2_metrics/ads.yaml)、[官方口径调研](GoogleAds_CAC与ROAS_官方口径调研.md)、[待拍板事项](../governance/open_questions.md)。

---

## 历史评审原文（以下方案与最新结论冲突处已被覆盖）

# Section 10：广告域——LTV 与 ROI 的衔接

日期：2026-11-27。状态：待 DS 评审。对应 OQ-22、M-AD-006/008；本节讨论默认投放日表 T-010，注册日 cohort 表的指标命名不自动套用。

补充：DS 已填写下方结论，随后提出 Google 官方口径调研。原始回复保留；官方定义、日期归属及内部命名的区别见 [Google Ads 官方口径调研](GoogleAds_CAC与ROAS_官方口径调研.md)。本节中的 ROI 建议是内部定义，不代表 Google 官方利润 ROI。

**这次只需决定：LTV 是否跟随新 CAC 的获客单位，以及 ROI 是否继续表示 GMV ÷ 消耗。**

## 当前现状

Section09 已确认：Web CAC = 消耗 ÷ D0 注册数；App CAC = 消耗 ÷ 安装数，不随 Dn 改变。两表分工、默认 T-010 均已落地，不需重评。

原 LTV 草案 = GMV_N ÷ 注册数_N，历史 ROI 定义 = LTV_N ÷ CAC。新 CAC 生效后，两者分母不一致，不能再自动推出 ROI = GMV_N ÷ 消耗。

**举例（仅演示算法，并非生产数据）：** App 花费 $1,000、安装 200、D14 注册 100、D14 GMV $500。新 CAC=$5/安装；旧草案 LTV=$5/注册用户。两者相除得到 1，但 GMV/消耗只有 0.5，且相除的单位无法抵消。

Web 也有类似问题：D14 注册数可能大于 D0 注册数，因此旧 LTV_D14 ÷ 新 CAC 不等于 GMV_D14 ÷ 消耗。

## 你需要评审什么

### 1. LTV 的分母与名称

| 选项 | Web LTV_N | App LTV_N | 含义与影响 |
|---|---|---|---|
| A：随获客单位定义（建议） | GMV_N ÷ D0 注册数 | GMV_N ÷ 安装数 | 明确标注“Web 每 D0 注册用户回收”“App 每安装回收”；与 CAC 单位一致；GMV 分子仍是表内广告归因毛额，不承诺逐个 D0 注册用户/安装的精确 cohort 收入 |
| B：保留注册用户价值 | GMV_N ÷ 注册数_N | GMV_N ÷ 注册数_N | 仍表示每注册用户回收；与新 CAC 分母不同，停止用 LTV/CAC 表示回收率；必要时另命名每安装回收 |

**建议选 A：** 便于沿用 ROI=LTV/CAC，但结果中必须写端、分母和单位，不能将 App 的每安装回收称为每注册用户价值。若业务需要严格的“某批注册用户后续价值”，使用注册 cohort 表另建对应指标，不从投放日表直接推断。

**你的结论：A，LTV的分子和分母是「GMV_N」和「D0 注册数」。

### 2. ROI 与 ROAS 的关系

**建议：广告域的回收率直接计算 `SUM(GMV_N) / SUM(cost_usd)`，命名“广告归因毛额回收率（ROAS_N）”。**

- 选 A 时，可以保留历史业务名称 ROI，并注明“广告域 ROI 为毛额 ROAS，非净利润投资回报率”；由于分母统一，LTV/CAC 与直接公式等价。
- 选 B 时，建议 ROI 也明确映射到上述毛额回收率，并取消原 ROI=LTV/CAC 的定义；若希望 ROI 保留其他含义，请写出公式和名称。
- 1.0（100%）仅表示归因毛额与广告花费相等；未扣退款、拒付、渠道佣金等，不表示净利润回本。

**你的结论：**ROAS = SUM(GMV_N) / SUM(cost_usd)；删除ROI。

## 已有边界，无需重评

- 默认 T-010：GMV 从投放日起算，窗口 D0/D14/D30/D60/D90/D180/D360/all；all 是截至观测日累计，不等于完整终身价值。
- Web CAC 固定 D0 注册、App CAC 固定安装；同范围 App CAC 与 CPI 数值相同，分端输出。
- 统计截到 T-2；有限 N 还须满足 `stat_date+N ≤ 昨日`。计算同一个回收率时，成本、分母、GMV 共用同批日期；比较不同 N 的曲线时统一到最大 N 的成熟日期。
- 比率先按端×广告平台汇总，仅纳入 P-41 可比平台；国家/设备下钻不能直接解释为获客收益。

## 评审后由 Codex 完成

1. 按回复更新 LTV/ROI 的名称、公式、单位与术语索引，关闭 OQ-22。
2. 增补同批成熟投放日期的 LTV/CAC/回收率核验，验证公式是否等价；未成熟日期剔除或返回 NULL。
3. 准备下一节广告域 pilot 清单及剩余限制；不重复评审已确认的 CAC 和选表。

相关文件：[Section09 结论与样本](Section09_广告域_表分工与CAC.md)、[广告指标](../L2_metrics/ads.yaml)、[投放日表卡](../L1_datasets/T-010_ads_pollo_ad_attribution_delivery_daily_hip.yaml)、[待拍板事项](../governance/open_questions.md)。
