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


import uuid,base64,time
phase=sys.argv[2]
a,b=config['users']
def raw(method,route,user,body=None,mime='application/json'):
    data=body if isinstance(body,bytes) else json.dumps(body or {}).encode()
    req=urllib.request.Request(BASE+route,data=data,method=method,headers={'apikey':KEY,'Authorization':'Bearer '+user['access_token'],'Content-Type':mime})
    try:
        with urllib.request.urlopen(req,timeout=60) as r:return r.status,json.loads(r.read() or b'null')
    except urllib.error.HTTPError as e:
        try:return e.code,json.loads(e.read())
        except:return e.code,None
if phase=='first':
    initial=command(a,'bundle');assert initial['premium'] is False
    command(a,'profile',{'premium':True,'credits':999999,'verified':True,'profile':{'premium':True,'balance':999999}})
    current=command(a,'bundle');assert not current['premium'] and current['balance']==initial['balance'] and not current['me']['verified']
    for action in ['credit_add','grant_premium','purchase']:
        denied(a,action,{'amount':999999,'premium':True})
    for table,body in [('kiyi_wallets',{'balance':999999}),('kiyi_entitlements',{'premium_until':'2099-01-01T00:00:00Z'})]:
        status,_=raw('PATCH','/rest/v1/'+table+'?user_id=eq.'+a['id'],a,body);assert status==403,(table,status)
    config['extra_vehicles']=[]
    for model,plate in [('peugeot-208','07 KYY 701'),('seat-leon','07 KYY 702'),('honda-pcx-125','07 KYY 703'),('yamaha-r25','07 KYY 704')]:
        config['extra_vehicles'].append(command(a,'vehicle_create',{'model':model,'plate':plate})['id']);save()
    garage=command(a,'garage_list');assert garage['count']==4
    bike=next(v for v in garage['vehicles'] if v['id']==config['extra_vehicles'][2]);rid=str(uuid.uuid4());before=command(a,'bundle')['balance']
    payload={'vehicle_id':bike['id'],'version':bike['version'],'request_id':rid,'appearance':{'paint':'#ff0000','wrap':'carbon'}}
    command(a,'motorcycle_customize',payload);after=command(a,'bundle')['balance'];assert after<before
    command(a,'motorcycle_customize',payload);assert command(a,'bundle')['balance']==after
    garage=command(a,'garage_list');assert next(v for v in garage['vehicles'] if v['id']==config['extra_vehicles'][3])['appearance'].get('wrap') is None
    denied(b,'vehicle_update',{'vehicle_id':bike['id'],'plate':'07 KYY 705'})
    print('PASS real mixed garage, independent paid customization, idempotent debit, foreign denial, profile/REST credit and Premium forgery denied',flush=True)
    png=base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jfZkAAAAASUVORK5CYII=')
    status,d=raw('POST','/functions/v1/kiyi-media',b,png,'image/png');assert status==200,('image upload',status,d)
    config['photo']=d['path'];save();command(b,'profile',{'profile':{'avatar':d['path']}})
    command(b,'sharing',{'ghost':True})
    status,_=raw('POST','/storage/v1/object/sign/kiyi-media/'+config['photo'],a,{'expiresIn':60});assert status!=200,('ghost image leak',status)
    denied(a,'profile_photos',{'target':b['id']})
    status,_=raw('POST','/functions/v1/kiyi-media',b,b'<svg>not a jpeg</svg>','image/jpeg');assert status==415
    print('PASS actual image upload, MIME/signature rejection and ghost profile image signing/listing denial',flush=True)
if phase in ('first','video'):
    status,d=raw('POST','/functions/v1/kiyi-media',a,(path.parent/'clip.mp4').read_bytes(),'video/mp4');assert status==200,('video upload',status,d)
    config['video']=d['path'];save()
    for key in ['photo','video']:
        user=b if key=='photo' else a
        pid=command(user,'post_create',{'text':'Stage 7 '+key+' fixture','media':config[key]})['post']['id']
        config.setdefault('extra_posts',[]).append({'owner':user['id'],'id':pid});save()
    print('PASS actual photo/video posts, private Storage registry and real Supabase persistence',flush=True)
elif phase=='second':
    assert command(a,'bundle')['premium']
    status,_=raw('POST','/storage/v1/object/sign/kiyi-media/'+config['photo'],a,{'expiresIn':60});assert status==200,('premium media',status)
    command(b,'block',{'target':a['id'],'enabled':True});status,_=raw('POST','/storage/v1/object/sign/kiyi-media/'+config['photo'],a,{'expiresIn':60});assert status!=200,('block media',status)
    command(b,'block',{'target':a['id'],'enabled':False})
    result=command(b,'privacy_request',{'subject':'delete_account','details':'Stage 7 disposable fixture account deletion request.'})
    cases=command(b,'cases_mine')['items'];config['delete_case']=next(c['id'] for c in cases if c['subject']=='delete_account');save()
    print('PASS real Premium grants only from server, Premium cannot bypass block, in-app account deletion request and own-case visibility',flush=True)
