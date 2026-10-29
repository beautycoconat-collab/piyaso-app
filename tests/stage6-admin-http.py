import os
"""Run with two disposable confirmed Auth accounts, never real customer credentials.
python tests/stage6-http-smoke.py /tmp/accounts.json
JSON users need id/email/password; owner removes only these fixtures after logout.
"""
import json
import sys
import urllib.error
import urllib.request
from pathlib import Path

BASE = 'https://oswpkwwbjwyktuqcakhr.supabase.co'
KEY = os.environ['SUPABASE_PUBLISHABLE_KEY']
path = Path(sys.argv[1])
config = json.loads(path.read_text())


def request(route, user=None, body=None):
    headers = {'apikey': KEY, 'Content-Type': 'application/json'}
    if user:
        headers['Authorization'] = 'Bearer ' + user['access_token']
    req = urllib.request.Request(BASE + route, data=json.dumps(body or {}).encode(), headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=60) as response:
            raw = response.read()
            return response.status, json.loads(raw) if raw else None
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read())
        except ValueError:
            return e.code, None


def command(user, action, payload=None):
    status, data = request('/rest/v1/rpc/kiyi_command', user, {'action': action, 'payload': payload or {}})
    assert status == 200, (action, status, data)
    return data


def denied(user, action, payload):
    status, data = request('/rest/v1/rpc/kiyi_command', user, {'action': action, 'payload': payload})
    assert status in (400, 401, 403, 409, 429), (action, status, data)


def save():
    path.write_text(json.dumps(config))


import time,base64,hmac,hashlib,struct,uuid
# The owner grants ONLY this disposable fixture a temporary moderator membership.
# A real Auth TOTP challenge is used. No AAL claims/JWT are forged.
a,b=config['users']
def admin(user,action,payload=None,expected=200):
    status,data=request('/rest/v1/rpc/kiyi_admin_command',user,{'action':action,'payload':payload or {}})
    assert status==expected,('admin',action,status,data)
    return data

def op(page,operation='list',data=None):
    return admin(a,'ops',{'page':page,'op':operation,'data':data or {}})

def write(page,operation,data):
    return op(page,operation,{**data,'reason':'Stage 6 disposable moderation verification','request_id':str(uuid.uuid4())})
admin(a,'ops',{'page':'reports'},403)
status,factor=request('/auth/v1/factors',a,{'factor_type':'totp','friendly_name':'Stage 6 disposable test'})
assert status==200,('mfa enroll',status,factor.get('msg'))
secret=factor['totp']['secret'];padded=secret+'='*((8-len(secret)%8)%8)
raw=hmac.new(base64.b32decode(padded),struct.pack('>Q',int(time.time())//30),hashlib.sha1).digest();offset=raw[-1]&15
code=str((struct.unpack('>I',raw[offset:offset+4])[0]&0x7fffffff)%1000000).zfill(6)
status,challenge=request('/auth/v1/factors/'+factor['id']+'/challenge',a,{})
assert status==200,('mfa challenge',status)
status,verified=request('/auth/v1/factors/'+factor['id']+'/verify',a,{'challenge_id':challenge['id'],'code':code})
assert status==200,('mfa verify',status)
a['access_token']=verified['access_token'];save()
admin(a,'session')
print('PASS real moderator membership, AAL1 denial, real TOTP AAL2 and admin lease',flush=True)
reports=op('reports')['items'];report=next(r for r in reports if r['id']==config['report'])
detail=op('reports','detail',{'id':report['id']});assert detail['content']['id']==config['comment']
write('reports','decide',{'id':report['id'],'version':report['version'],'status':'in_review'})
report=op('reports','detail',{'id':report['id']})['report'];assert report['status']=='in_review'
write('content','moderate',{'id':config['comment'],'kind':'comment','hidden':True})
post=command(a,'post_get',{'id':config['posts'][0]})['post'];assert post['commentCount']==1
assert not any(n['kind']=='comment' for n in command(a,'bundle')['notifications'])
write('content','moderate',{'id':config['posts'][0],'kind':'post','hidden':True})
denied(b,'post_get',{'id':config['posts'][0]})
write('reports','decide',{'id':report['id'],'version':report['version'],'status':'resolved'})
detail=op('reports','detail',{'id':report['id']});assert detail['report']['status']=='resolved';assert any(h['action']=='ops.content.moderate' for h in detail['history'])
status,data=request('/rest/v1/rpc/kiyi_admin_command',b,{'action':'ops','payload':{'page':'content','op':'moderate','data':{'id':config['posts'][0],'kind':'post','hidden':False,'reason':'Unauthorized attempt fixture','request_id':str(uuid.uuid4())}}})
assert status==403,('normal moderation denial',status)
write('users','sanction',{'user_id':b['id'],'kind':'suspend','until_at':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime(time.time()+3600))})
denied(b,'post_create',{'text':'Suspension bypass'})
print('PASS real admin report details/status, comment/post hiding, correct counts, suppressed hidden notifications, audit history, normal-user denial, suspension enforced',flush=True)
# Restore test content, but leave fixture restriction for owner cleanup (moderators cannot restore).
write('content','moderate',{'id':config['posts'][0],'kind':'post','hidden':False})
write('content','moderate',{'id':config['comment'],'kind':'comment','hidden':False})
print('PASS Stage 6 real MFA moderation checks complete; exact fixture cleanup required.',flush=True)
