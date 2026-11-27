# 支付金额字段来源核查（2026-11-27）

已通过CNB API确认最新main仍为`29f97589bc61d7537844958bb646ea4e9fd4b052`，使用该固定提交的生产代码；本记录不构成税务含义判断。

| 代码来源 | 已确认的实现 | 不能据此推断什么 |
|---|---|---|
| `bigdata_dw/02_DWD/transaction/Sq_dwd_pollo_transaction_order_dip.sql` 第362、367~369行 | amount_received_original直接来自业务amount_received；美元实付金额为amount_received/100×汇率；规范字段缺汇率置NULL，legacy缺汇率按1 | 没有提供业务amount_received税款组成的明确说明，不能断言含税/不含税 |
| `bigdata_dw/02_DWD/transaction/ddl_dwd_pollo_transaction_order_detail_view.sql` 第34、40、73~75、112~113行 | 视图使用实付美元字段；退款换算按本单支付日汇率；revenue_usd_amount为实付美元减退款 | 扣退款不等于扣税、扣佣金或净利润 |

Section13只补充源金额的含税说明，暂不改变M-PAY-001/002已评审算法。订单视图/底表按此来源更新producer，历史查询证据保留原核查日期。
