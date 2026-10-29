import os
"""Only disposable owner-provisioned accounts. No signup/recovery email is sent."""
import json,sys,urllib.request,urllib.error
A,B=json.load(open(sys.argv[1]));BASE='https://oswpkwwbjwyktuqcakhr.supabase.co';KEY=os.environ['SUPABASE_PUBLISHABLE_KEY']
def call(path,body=None,token=None):
 h={'apikey':KEY,'Content-Type':'application/json'}
 if token:h['Authorization']='Bearer '+token
 try:
  with urllib.request.urlopen(urllib.request.Request(BASE+path,data=json.dumps(body).encode() if body is not None else None,headers=h),timeout=30) as r:
   raw=r.read();return r.status,json.loads(raw) if raw else None
 except urllib.error.HTTPError as e:return e.code,None
def login(u):
 status,data=call('/auth/v1/token?grant_type=password',{'email':u['email'],'password':u['password']});assert status==200,'Auth login failed';return data
one=login(A);two=login(A);other=login(B)
def rpc(token,action,payload={}):return call('/rest/v1/rpc/kiyi_command',{'action':action,'payload':payload},token)
for s in [one,two,other]:assert rpc(s['access_token'],'bundle')[0]==200
status,refreshed=call('/auth/v1/token?grant_type=refresh_token',{'refresh_token':two['refresh_token']});assert status==200
assert rpc(refreshed['access_token'],'security_notice')[0]==403,'Other session still active'
assert call('/auth/v1/logout?scope=others',{},refreshed['access_token'])[0] in [200,204]
assert rpc(refreshed['access_token'],'security_notice')[0]==200
assert rpc(refreshed['access_token'],'security_notice')[0]==200
status,check=rpc(refreshed['access_token'],'bundle');assert status==200 and len([n for n in check['notifications'] if n['kind']=='security'])==1
assert rpc(one['access_token'],'bundle')[0]==403,'Other session survived revoke'
assert rpc(refreshed['access_token'],'bundle')[0]==200,'Current device was revoked'
assert rpc(other['access_token'],'bundle')[0]==200,'Unrelated account revoked'
status,rows=call('/rest/v1/kiyi_wallets?select=*',token=other['access_token']);assert status==200 and all(r['user_id']==B['id'] for r in rows),'Foreign wallet exposed'
assert call('/rest/v1/kiyi_entitlements',{'user_id':B['id'],'premium_until':'2099-01-01'},other['access_token'])[0]==403
for s in [refreshed,other]:
 assert call('/auth/v1/logout?scope=global',{},s['access_token'])[0] in [200,204]
 assert rpc(s['access_token'],'bundle')[0]==403
print('PASS two real Auth accounts; two devices; refresh; revoke others; current/foreign isolation; wallet/Premium direct denial; global logout token replay denial')
