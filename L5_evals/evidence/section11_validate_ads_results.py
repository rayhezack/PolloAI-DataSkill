# -*- coding: utf-8 -*-
"""复核已保存的生产聚合结果；无需联网，不用本地模拟替代生产样本。"""
import json
import math
from decimal import Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parent

def read(name):
    return json.loads((ROOT / (name + '_result.json')).read_text())['data']

total_rows = read('section11_paid_cac_total')
channels = read('section11_paid_cac_channels')
total = next(x for x in total_rows if x['row_type'] == 'period_total')
assert sum(Decimal(x['cost_usd']) for x in channels if x['cost_usd'] is not None) == Decimal(total['cost_usd'])
assert sum(x['channel_signup_uv'] for x in channels) == total['paid_signup_uv']
daily = [x for x in total_rows if x['row_type'] == 'daily']
assert sum(Decimal(x['cost_usd']) for x in daily) == Decimal(total['cost_usd'])
assert sum(x['paid_signup_uv'] for x in daily) == total['paid_signup_uv']
for x in total_rows:
    assert math.isclose(float(x['cost_usd']) / x['paid_signup_uv'], float(x['cac_usd']), rel_tol=1e-12)
for x in channels:
    if x['cost_usd'] is None:
        assert x['channel_cac_usd'] is None
    else:
        assert math.isclose(float(x['cost_usd']) / x['channel_signup_uv'], float(x['channel_cac_usd']), rel_tol=1e-12)
windows = [{x['ad_platform']: x for x in read('section11_web_ltv_roas_d' + n)} for n in ['0', '14', '30']]
assert all(set(w) == set(windows[0]) for w in windows)
for platform in windows[0]:
    rows = [w[platform] for w in windows]
    assert len({x['cost_usd'] for x in rows}) == len({x['reg_user_cnt_d0'] for x in rows}) == 1
    assert all(x['source_end'] == 'WEB' and x['first_delivery_date'] == '20261001'
               and x['last_delivery_date'] == '20261027' and x['delivery_day_count'] == 27 for x in rows)
    assert [float(x['gmv_usd_n']) for x in rows] == sorted(float(x['gmv_usd_n']) for x in rows)
    for x in rows:
        assert math.isclose(float(x['gmv_usd_n']) / x['reg_user_cnt_d0'], float(x['ltv_usd']), rel_tol=1e-12)
        assert math.isclose(float(x['gmv_usd_n']) / float(x['cost_usd']), float(x['roas']), rel_tol=1e-12)
quality = read('section11_paid_signup_source_quality')
assert sum(x['attributed_signup_uv'] for x in quality) == total['paid_signup_uv']
assert all(x['profile_missing_uv'] == x['internal_uv'] == x['non_web_profile_uv'] == 0 for x in quality)
print('生产样本复核通过：大盘/渠道成本及注册加总一致；D0/D14/D30同批日期、固定D0分母；LTV/ROAS重算一致；样本注册均匹配Web画像且无内部账号。成本缺失仍按证据说明。')
