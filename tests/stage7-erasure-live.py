import os
"""Run with two disposable confirmed Auth accounts, never real customer credentials.
See stage7-report.md; supply a private JSON file for disposable fixtures.
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


import uuid
a,b=config['users']
def admin(user,action,payload=None):
 status,data=request('/rest/v1/rpc/kiyi_admin_command',user,{'action':action,'payload':payload or {}})
 assert status==200,('admin',action,status,data)
 return data
case=config['delete_case']
result=admin(a,'ops',{'page':'privacy','op':'erase','data':{'id':case,'reason':'Stage 7 disposable account deletion authorized by fixture user','request_id':str(uuid.uuid4())}})
assert result['status']=='storage_erasure_pending'
denied(b,'post_create',{'text':'Deleted account bypass'})
denied(b,'garage_list',{})
jobs=admin(a,'ops',{'page':'privacy'})['jobs'];job=next(x for x in jobs if x['subject']==b['id'])
batch=admin(a,'media',{'op':'batch','job_id':job['id']})
assert all(p.startswith(b['id']+'/') for p in batch['paths'])
if batch['paths']:
 req=urllib.request.Request(BASE+'/storage/v1/object/kiyi-media',method='DELETE',data=json.dumps({'prefixes':batch['paths']}).encode(),headers={'apikey':KEY,'Authorization':'Bearer '+a['access_token'],'Content-Type':'application/json'})
 with urllib.request.urlopen(req,timeout=60) as response:assert response.status==200
assert not admin(a,'media',{'op':'batch','job_id':job['id']})['paths']
admin(a,'media',{'op':'finish','job_id':job['id']})
assert next(x for x in command(b,'cases_mine')['items'] if x['id']==case)['status']=='completed'
print('PASS actual user deletion request -> MFA admin erasure -> Storage API cleanup -> completed status; deleted-account writes denied',flush=True)
# Clean only A-owned temporary content before logging out.
for item in config.get('extra_posts',[]):
 if item['owner']==a['id']:command(a,'post_delete',{'id':item['id']})
for pid in config.get('posts',[]):command(a,'post_delete',{'id':pid})
if config.get('video'):
 req=urllib.request.Request(BASE+'/storage/v1/object/kiyi-media',method='DELETE',data=json.dumps({'prefixes':[config['video']]}).encode(),headers={'apikey':KEY,'Authorization':'Bearer '+a['access_token'],'Content-Type':'application/json'})
 with urllib.request.urlopen(req,timeout=60) as response:assert response.status==200
status,_=request('/auth/v1/logout',a,{})
assert status in (200,204)
status,data=request('/rest/v1/rpc/kiyi_command',a,{'action':'bundle','payload':{}})
assert status in (401,403),('logged out replay',status,data)
print('PASS logged-out access token replay rejected before JWT expiry',flush=True)
