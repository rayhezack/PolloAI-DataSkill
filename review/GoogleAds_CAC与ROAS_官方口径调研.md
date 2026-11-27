# Google Ads：CAC、CPA 与 ROAS 官方口径调研

> 调研后的内部裁决：ROI指标已删除；当前CAC仅Web，采用当天Web全部广告成本/当天Web总注册；App本轮不包含。以下“注册/安装CAC”和ROI讨论为调研时的历史对照，以[Section10最终结论](Section10_广告域_LTV与ROI衔接.md)为准。


调研日期：2026-11-27。性质：Google 官方资料与本库口径的对照证据，不自动修改 DS 已确认的业务定义。

**核心结论：Google Ads 的 CPA 取决于配置的转化动作；新客户获取报告中的 CAC 针对新购买客户。投放回报通常把窗口内后续转化记回广告互动日，不要求转化和花费发生在同一天。**

## 获客到底指什么

- 官方 CPA 是费用除以转化次数，动作可以是注册、购买等，不等于去重新客户数。[Average CPA](https://support.google.com/google-ads/answer/6396841?hl=en)、[Target CPA](https://support.google.com/google-ads/answer/6268632?hl=en)
- 生命周期目标报告中的 CAC，是分配给新客户的广告消耗除以去重新客户数；此报告针对购买转化，注册和访客不能直接等同为这里的新客户。新老客识别受客户名单、标签、自动识别等配置影响，并非必然是内部全历史首购。[Lifecycle goals reporting](https://support.google.com/google-ads/answer/15597581?hl=en)
- 因此，Pollo 现有 Web 消耗/D0注册应明确标成“D0注册获客成本”，App 消耗/安装为“安装获客成本/CPI”；可以保留内部 CAC 名称，但不能说是 Google 官方 CAC 的同一指标。总广告消耗也不能无说明地替换官方指标中的“分配给新客户的消耗”。这是命名建议，非已采纳变更。

## 花费日期与转化日期

Google Ads 默认转化列按广告点击日期回记，另提供 by conv. time 列按实际转化时间展示。后者与同日花费相除时，可能混入过去广告带来的转化。[Conversion tracking data — Time of conversion](https://support.google.com/google-ads/answer/6270625?hl=en)

转化窗口决定互动之后多长时间内的转化可计入；例如搜索/展示未自定义的点击转化窗口通常为30天，允许范围依来源而异。窗口变长可能增加转化数量和价值，不只是收入受影响。[Conversion windows](https://support.google.com/google-ads/answer/3123169?hl=en)

**示意公式（用于说明时间对齐，不代表 Google 账户所有计费/归因细节）：**

`注册CPA(t,W) = t日广告消耗 / 归因给t日广告互动、在W窗口内完成的注册转化`

`收入ROAS(t,W) = 归因给t日广告互动、在W窗口内发生的收入 / t日广告消耗`

## ROAS 的价值与窗口

Google 的目标 ROAS 围绕转化价值与广告花费衡量；转化价值可由业务上报收入、利润或赋值。只有上报口径是交易收入时，才能直接解释成收入回收率。[Target ROAS](https://support.google.com/google-ads/answer/6268637?hl=en)、[Conversion values](https://support.google.com/google-ads/answer/13064207?hl=en)

以下为假设例子：11月1日花费1,000美元，同日互动带来的用户当日注册20人，之后7天内另有30人注册；同批互动带来的累计收入在D7为400美元、D30为1,200美元。假设均全额归因此批广告、无其他触点分摊：

| 指标 | 计算 | 结果 |
|---|---|---|
| D0注册成本 | 1,000 / 20 | 50美元/注册 |
| 7日注册转化成本 | 1,000 / 50 | 20美元/注册 |
| D7收入ROAS | 400 / 1,000 | 40% |
| D30收入ROAS | 1,200 / 1,000 | 120% |

各项花费都属于11月1日，但收入与注册可在后续发生；窗口未成熟时结果还会变化。以上 Dn 为示意，实际需固定时间边界、时区、转化事件与归因方式。

## 与 Pollo LTV 的衔接

DS 在 Section10 选择固定首次安装/注册 cohort 分母，并分别定义 ROAS=GMV_N/消耗、ROI=LTV/CAC。应区分：

1. **获客转化窗口**：多久内的安装/注册/首购算该批广告获得的用户。
2. **价值观察窗口**：已固定 cohort 后，观察其之后多久的收入；延长价值观察窗口时，同一 cohort 的人数固定。
3. **窗口起点**：Google 广告点击/互动日、内部首次访问日、安装日、注册日，不能互相替代。现有 T-010 的 GMV 从投放日算；不能仅更换分母就认定它等于严格注册 cohort 的生命周期收入。

Google 官方 ROI 是净利润相对成本的比率；LTV/CAC 作为内部回收倍数需要显式标注业务定义，不能宣称是官方利润 ROI。我上一节建议沿用 ROI 名称时，这个区别说明得不够充分。[About ROI](https://support.google.com/google-ads/answer/1722066?hl=en)

本库进一步采用哪些名称与窗口，以 DS 决定为准；对账 Google 后台还需核对实际转化动作、计数规则、价值上报、归因模型、窗口和账户时区。官方文档不能证明当前 Google Ads 账户已按同样方式配置。
