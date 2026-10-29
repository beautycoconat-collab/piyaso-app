import os
"""Two disposable confirmed test accounts only. Never pass customer accounts.
Run after owner-provisioning Auth fixtures; no emails, real money or gifts are sent.
Credentials read from a 0600 scratch file, never printed. Owner cleans exact fixture IDs.
"""
import json,sys,urllib.request,urllib.error,concurrent.futures
from pathlib import Path
BASE='https://oswpkwwbjwyktuqcakhr.supabase.co';KEY=os.environ['SUPABASE_PUBLISHABLE_KEY']
a,b=json.loads(Path(sys.argv[1]).read_text())
def call(route,body=None,token=None,method='POST'):
 h={'apikey':KEY,'Content-Type':'application/json'}
 if token:h['Authorization']='Bearer '+token
 try:
  with urllib.request.urlopen(urllib.request.Request(BASE+route,data=json.dumps(body).encode() if body is not None else None,headers=h,method=method),timeout=45)as r:return r.status,json.loads(r.read()or b'null')
 except urllib.error.HTTPError as e:return e.code,None
def login(u):
 status,result=call('/auth/v1/token?grant_type=password',{'email':u['email'],'password':u['password']});assert status==200,('fixture login',status);return result['access_token']
def rpc(token,action,payload={}):return call('/rest/v1/rpc/kiyi_command',{'action':action,'payload':payload},token)
A=login(a);A2=login(a);B=login(b)
for token in [A,B]:assert rpc(token,'bundle')[0]==200
_,one=rpc(A,'rewards');_,two=rpc(B,'rewards');assert one['code']!=two['code']
assert rpc(B,'reward_referral',{'code':one['code'].lower()})[0]==200
assert rpc(B,'reward_referral',{'code':one['code']})[0]==200
assert rpc(A,'reward_referral',{'code':one['code']})[0]in(400,403)
with concurrent.futures.ThreadPoolExecutor(max_workers=8)as pool:results=list(pool.map(lambda n:rpc(A if n%2 else A2,'reward_daily'),range(8)))
assert all(status==200 for status,_ in results)
assert sum(1 for _,r in results if r.get('amount')==5)==1,'Double credit under concurrent devices'
_,one=rpc(A,'bundle');_,two=rpc(B,'bundle');assert one['balance']==5 and two['balance']==0
assert len([r for r in one['ledger']if r['kind']=='reward'])==1
assert rpc(A,'reward_daily',{'owner':b['id'],'amount':999999})[0]==200
_,two=rpc(B,'bundle');assert two['balance']==0,'Foreign wallet changed'
_,own=rpc(A,'rewards',{'target':b['id']});assert own['balance']==5 and own['invites'][0]['days']==0
assert rpc(B,'reward_daily')[0]==200
_,own=rpc(A,'rewards');assert own['referral_earned']==0 and own['invites'][0]['days']==1
assert rpc(B,'reward_admin',{'referral_amount':500,'reason':'unauthorized fixture attempt'})[0]in(400,403)
assert call('/rest/v1/kiyi_wallets',{'user_id':b['id'],'balance':999999},B)[0]in(400,403)
assert call('/rest/v1/rpc/reward_pay',{'u':b['id'],'k':'fake','coins':500},B)[0]in(400,403,404)
Path('/tmp/kiyi-rewards-ui-fixture.json').write_text(json.dumps(own))
for token in[A,B]:assert call('/auth/v1/logout?scope=global',{},token)[0]in(200,204)
assert rpc(A,'reward_daily')[0]==403
print('PASS: two real Auth accounts, two concurrent devices, 8 claims = one 5-jeton ledger entry, foreign-wallet isolation, referral binding/replay, 1 active day not sufficient, admin/credit forgery denied, revoked token denied')
