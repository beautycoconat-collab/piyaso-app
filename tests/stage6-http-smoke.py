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


import uuid
users = config['users']
for user in users:
    status, data = request('/auth/v1/token?grant_type=password', body={'email':user['email'],'password':user['password']})
    assert status == 200, ('auth',status)
    user['access_token'] = data['access_token']
    save()
    command(user,'profile',{'username':'stage6_'+user['id'][:8],'searchable':True})
a,b=users
for pid in config.get('posts',[]):
    command(a,'post_delete',{'id':pid})
for u in users:
    command(u,'notification_settings',{'settings':{k:True for k in ['follow','like','comment','tag','badge']}})
config['posts']=[]
pid=command(a,'post_create',{'text':'Stage 6 notification fixture'})['post']['id']
config['posts'].append(pid);save()
assert any(x['code']=='first_post' for x in command(a,'badges')['badges'])
for _ in range(2):command(a,'bundle')
notes=command(a,'bundle')['notifications']
assert sum(n['kind']=='badge' and n['badge_code']=='first_post' for n in notes)==1
command(a,'like',{'id':pid,'like':True})
assert not any(n['kind']=='like' for n in command(a,'bundle')['notifications'])
print('PASS real Auth sessions, earned badge, badge dedupe, no self-like notification',flush=True)
command(b,'follow',{'target':a['id'],'enabled':True})
command(b,'like',{'id':pid,'like':True})
result=command(b,'comment',{'id':pid,'text':'Stage 6 real comment'})['post']
cid=result['comments'][0]['id'];config['comment']=cid;save()
notes=command(a,'bundle')['notifications']
assert {'follow','like','comment'} <= {n['kind'] for n in notes}
assert all(n['senderProfile']['id']==b['id'] for n in notes if n['kind'] in ('follow','like','comment'))
note=next(n for n in notes if n['kind']=='like')
command(a,'notification_open',{'id':note['id']})
assert next(n for n in command(a,'bundle')['notifications'] if n['id']==note['id'])['read_at']
denied(b,'notification_open',{'id':note['id']})
command(b,'like',{'id':pid,'like':False});command(b,'like',{'id':pid,'like':True})
assert sum(n['kind']=='like' for n in command(a,'bundle')['notifications'])==1
print('PASS follow/like/comment notices, actor identity, persisted read, cross-account denial, relike dedupe',flush=True)
command(a,'notification_settings',{'settings':{'follow':False,'like':False,'comment':False,'tag':False,'badge':False}})
assert not command(a,'notification_settings')['push_available']
for _ in range(2):assert command(a,'notification_settings')['settings']['comment'] is False
command(b,'comment',{'id':pid,'text':'Notification disabled comment'})
assert sum(n['kind']=='comment' for n in command(a,'bundle')['notifications'])==1
vid=command(b,'vehicle_create',{'model':'honda-pcx-125','plate':'07 SFD 601'})['id'];config['vehicles']=[vid];save()
assert any(x['code']=='first_vehicle' for x in command(b,'badges')['badges'])
command(b,'vehicle_update',{'vehicle_id':vid,'visibility':'public'})
command(b,'tag_settings',{'enabled':True})
post=command(a,'post_get',{'id':pid})['post']
command(a,'post_edit',{'id':pid,'version':post['version'],'vehicle_id':vid})
notes=command(b,'bundle')['notifications'];tag=next(n for n in notes if n['kind']=='tag')
opened=command(b,'notification_open',{'id':tag['id']})['notification'];assert opened['post_id']==pid
command(b,'tag_settings',{'enabled':False})
assert not any(n['kind']=='tag' for n in command(b,'bundle')['notifications'])
print('PASS independent saved in-app preferences, honest push state, vehicle badge, plate notification and consent revocation',flush=True)
x=command(b,'content_report',{'kind':'post','id':pid,'reason':'Spam'})
assert command(b,'content_report',{'kind':'post','id':pid,'reason':'Diğer'})['id']==x['id']
report=command(a,'content_report',{'kind':'comment','id':cid,'reason':'Taciz veya hakaret'})
config['report']=report['id'];config['post_report']=x['id'];save()
assert len(command(b,'my_reports')['reports'])==1
assert len(command(a,'my_reports')['reports'])==1
denied(b,'content_report',{'kind':'post','id':pid,'reason':'INVALID'})
status,data=request('/rest/v1/rpc/kiyi_admin_command',b,{'action':'ops','payload':{'page':'reports','op':'list'}})
assert status==403,('normal admin access',status,data)
for table in ['kiyi_notifications','kiyi_reports','kiyi_badges','kiyi_social_preferences']:
    req=urllib.request.Request(BASE+'/rest/v1/'+table,headers={'apikey':KEY,'Authorization':'Bearer '+b['access_token']})
    try:
        with urllib.request.urlopen(req,timeout=30) as response:assert False,(table,response.status)
    except urllib.error.HTTPError as e:assert e.code in (401,403)
command(a,'block',{'target':b['id'],'enabled':True})
assert not any(n['sender']==b['id'] for n in command(a,'bundle')['notifications'])
assert not command(a,'bundle')['followers']
denied(b,'post_get',{'id':pid});denied(a,'badges',{'target':b['id']})
command(a,'block',{'target':b['id'],'enabled':False})
assert not command(a,'bundle')['followers']
print('PASS typed/deduplicated reports, reporter isolation, normal admin denial, direct table denial, server block and unblock',flush=True)
print('PASS Stage 6 live HTTP social checks complete; fixture cleanup is required after moderation/UI checks.',flush=True)
