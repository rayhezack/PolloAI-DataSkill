import sqlite3,datetime
from pathlib import Path
con=sqlite3.connect(':memory:');con.row_factory=sqlite3.Row
con.execute("ATTACH DATABASE ':memory:' AS mc_prd")
con.create_function('TO_DATE',2,lambda s,f:datetime.datetime.strptime(s,'%Y%m%d').date().isoformat() if s else None)
con.create_function('TO_CHAR',2,lambda s,f:str(s).replace('-','')[:8] if s else None)
con.create_function('DATEADD',3,lambda s,n,u:(datetime.date.fromisoformat(s)+datetime.timedelta(days=n)).isoformat() if s and n is not None else None)
fields='p_date TEXT,stat_date TEXT,source_end TEXT,ad_platform TEXT,cost_usd REAL,reg_user_cnt_d0 INT,gmv_usd_d0 REAL,gmv_usd_d14 REAL,gmv_usd_d30 REAL,gmv_usd_d60 REAL,gmv_usd_d90 REAL,gmv_usd_d180 REAL,gmv_usd_d360 REAL,gmv_usd_all REAL'
t='mc_prd.ads_pollo_ad_attribution_delivery_daily_hip';con.execute('CREATE TABLE '+t+'('+fields+')')
def add(day,end,platform,cost,regs):
 con.execute('INSERT INTO '+t+' VALUES('+','.join('?'*14)+')',(day,datetime.datetime.strptime(day,'%Y%m%d').date().isoformat(),end,platform,cost,regs,40,100,120,130,140,150,155,160))
for d in ['20261111','20261112','20261113','20261125','20261126']:add(d,'WEB','google',100,10)
add('20261111','APP','google',999,99);add('20261111','WEB','meta',999,99);add('20261111','WEB','bing',0,0)
template=(Path(__file__).resolve().parents[2]/'L4_verified_queries/K-109.sql').read_text()
def query(w,end='20261126'):
 s=template
 for k,v in [('start_date','20261111'),('end_date',end),('as_of_date','20261127'),('window',w)]:s=s.replace('${'+k+'}',v)
 return [dict(x) for x in con.execute(s)]
a={x['ad_platform']:x for x in query('0')};b={x['ad_platform']:x for x in query('14')}
assert a['google']['last_delivery_date']=='20261125' and a['google']['delivery_day_count']==4
assert b['google']['last_delivery_date']=='20261112' and b['google']['delivery_day_count']==2
assert set(a)=={'bing','google'} and set(b)=={'bing','google'}
assert b['bing']['ltv_usd'] is None and b['bing']['roas'] is None
c={x['ad_platform']:x for x in query('0','20261112')};assert c['google']['reg_user_cnt_d0']==b['google']['reg_user_cnt_d0']==20
assert c['google']['ltv_usd']==4 and b['google']['ltv_usd']==10 and b['google']['roas']==1
assert not query('30') and not query('7')
assert {x['ad_platform']:x for x in query('all')}['google']['last_delivery_date']=='20261125'
print('本地逻辑检查通过：成熟边界、T-2、仅Web、平台过滤、零分母、同批日期固定D0分母、all、不支持窗口。采用SQLite替代日期函数执行同一SQL；不替代MaxCompute实跑。')
