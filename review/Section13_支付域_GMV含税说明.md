# Section 13：支付域——GMV 是否含税

日期：2026-11-27。状态：待 DS 补充。对应OQ-04。

**这一节只确认现有实付金额是否包含税款，不重新选择GMV算法。**

## 当前现状

支付GMV已按你确认的定义：有效订单的 `amount_received_usd` 求和，不扣退款，包含API；扣退款后的实收GMV使用 `revenue_usd_amount`。

生产代码已确认：`amount_received_usd = amount_received / 100 × 汇率`，`revenue_usd_amount = amount_received_usd − refund_usd_amount`。这两条公式本身不能说明业务源字段 `amount_received` 是否已包含税款，也不能因为代码未单独扣税就断言含税或不含税。

当前指标卡已声明“是否含税尚未确认”。这一项从初版清单保留至今，目的只是让不同团队对“收入是否含税”使用同一个说明，不阻止继续使用已确认GMV。

## 你现在需要补充什么

**业务源字段 amount_received 的实付金额，是否包含向用户收取的税款？**

**你的结论：**

可直接写“含税”“不含税”，或“目前不确定，先保留未确认说明”。如果不同支付渠道不同，请说明已知范围即可；未知部分由Codex继续追查来源，不猜测。

## 我会据此更新什么

只更新支付GMV/实收GMV的含税说明与OQ-04状态。不会擅自扣税、估算税率，也不会改变现有有效订单、API、退款和日期口径。若以后需要单独的税额或不含税收入，再另建指标。

来源证据：[金额字段来源核查](../governance/payment_amount_source_check_20261127.md)、[订单表卡](../L1_datasets/T-001_dwd_pollo_transaction_order_detail_view.yaml)、[支付指标](../L2_metrics/payment.yaml)。
