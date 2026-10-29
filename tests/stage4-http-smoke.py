import os
"""Real Auth/REST/Storage test. Supply TWO disposable, confirmed test accounts only.
Run: python tests/stage4-http-smoke.py /tmp/accounts.json /tmp/valid.mp4
Config: {"users":[{"id":"uuid","email":"...@example.invalid","password":"..."}, ...]}.
Owner must remove fixture Auth accounts and run existing media worker afterwards.
Never use an existing customer's credentials. Tokens stay in the private config.
"""
import base64
import json
import sys
import urllib.error
import urllib.request
import uuid
from pathlib import Path

BASE = 'https://oswpkwwbjwyktuqcakhr.supabase.co'
KEY = os.environ['SUPABASE_PUBLISHABLE_KEY']
config_path = Path(sys.argv[1])
config = json.loads(config_path.read_text())


def request(path, user=None, body=None, method='POST', mime='application/json'):
    headers = {'apikey': KEY, 'Content-Type': mime}
    if user:
        headers['Authorization'] = 'Bearer ' + user['access_token']
    data = json.dumps(body).encode() if mime == 'application/json' and body is not None else body
    req = urllib.request.Request(BASE + path, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=60) as response:
            raw = response.read()
            return response.status, json.loads(raw) if 'json' in response.headers.get('Content-Type', '') else raw
    except urllib.error.HTTPError as error:
        raw = error.read()
        try:
            return error.code, json.loads(raw)
        except ValueError:
            return error.code, raw


def command(user, action, payload=None):
    status, data = request('/rest/v1/rpc/kiyi_command', user, {'action': action, 'payload': payload or {}})
    assert status == 200, (action, status, data)
    return data


def denied(user, action, payload):
    status, _ = request('/rest/v1/rpc/kiyi_command', user, {'action': action, 'payload': payload})
    assert status in (400, 401, 403, 409), (action, status)


def save():
    config_path.write_text(json.dumps(config))


users = config['users']
for user in users:
    status, data = request('/auth/v1/token?grant_type=password', body={'email': user['email'], 'password': user['password']})
    assert status == 200, ('sign-in', status)
    user['access_token'] = data['access_token']
    assert data['user']['id'] == user['id']
    save()
    command(user, 'bundle')
a, b = users
print('PASS real Auth sign-in and bootstrap for two disposable accounts', flush=True)
command(a, 'profile', {'username': 'http4_' + a['id'][:8], 'searchable': True})
car = command(a, 'vehicle_create', {'model': 'peugeot-208', 'plate': '07 SCL 491'})['id']
bike = command(a, 'vehicle_create', {'model': 'honda-pcx-125', 'plate': '07 SCL 492'})['id']
for vehicle in [car, bike]:
    command(a, 'vehicle_update', {'vehicle_id': vehicle, 'visibility': 'public'})
config.update(vehicles=[car, bike], posts=[], paths=[])
save()
png = base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aX1sAAAAASUVORK5CYII=')
for mime, raw in [('image/png', png), ('video/mp4', Path(sys.argv[2]).read_bytes())]:
    status, upload = request('/functions/v1/kiyi-media', a, raw, mime=mime)
    assert status == 200, ('upload', mime, status)
    config['paths'].append(upload['path'])
    save()
image, video = config['paths']
status, _ = request('/storage/v1/object/sign/kiyi-media/' + image, b, {'expiresIn': 60})
assert status in (400, 403), ('unpublished media leak', status)
for mime, raw in [('image/png', b'not an image'), ('image/svg+xml', b'<svg/>')]:
    assert request('/functions/v1/kiyi-media', a, raw, mime=mime)[0] == 415
print('PASS binary uploads, magic/type guard, unpublished-media authorization', flush=True)
for payload in [{'text': 'Stage 4 HTTP fixture', 'request_id': str(uuid.uuid4())}, {'media': image, 'vehicle_id': car}, {'media': video, 'vehicle_id': bike}]:
    config['posts'].append(command(a, 'post_create', payload)['post']['id'])
    save()
text_id, photo_id, video_id = config['posts']
for category, expected in [('photo', photo_id), ('video', video_id), ('car', photo_id), ('motorcycle', video_id)]:
    assert any(p['id'] == expected for p in command(b, 'posts', {'filter': category})['posts']), category
status, signed = request('/storage/v1/object/sign/kiyi-media/' + video, b, {'expiresIn': 60})
assert status == 200
status, downloaded = request('/storage/v1' + signed['signedURL'], method='GET')
assert status == 200 and downloaded[4:8] == b'ftyp'
print('PASS real posts, tags, four content filters and signed video retrieval', flush=True)
denied(b, 'post_edit', {'id': text_id, 'version': 1, 'text': 'attack'})
denied(b, 'post_delete', {'id': text_id})
denied(b, 'post_create', {'text': 'attack', 'vehicle_id': car})
denied(b, 'post_create', {'media': image})
edited = command(a, 'post_edit', {'id': text_id, 'version': 1, 'text': 'Edited HTTP fixture'})['post']
assert edited['version'] == 2 and edited['text'] == 'Edited HTTP fixture'
denied(a, 'post_edit', {'id': text_id, 'version': 1, 'text': 'stale'})
command(a, 'post_edit', {'id': photo_id, 'version': 1, 'visibility': 'followers'})
denied(b, 'post_get', {'id': photo_id})
assert request('/storage/v1/object/sign/kiyi-media/' + image, b, {'expiresIn': 60})[0] in (400, 403)
command(b, 'follow', {'target': a['id'], 'enabled': True})
assert len(command(b, 'posts', {'filter': 'following'})['posts']) == 3
assert len(command(b, 'posts', {'author': a['id']})['posts']) == 3
command(b, 'like', {'id': text_id, 'like': True})
assert command(b, 'comment', {'id': text_id, 'text': 'Smoke comment'})['post']['commentCount'] == 1
command(a, 'vehicle_update', {'vehicle_id': car, 'visibility': 'private'})
tagged = command(b, 'post_get', {'id': photo_id})['post']
assert tagged['vehicle'] is None and tagged['vehicleHidden'] and 'vehicle_id' not in tagged
command(a, 'post_edit', {'id': photo_id, 'version': 2, 'media': None, 'text': 'Photo removed'})
command(b, 'block', {'target': a['id'], 'enabled': True})
assert len(command(b, 'posts', {'author': a['id']})['posts']) == 0
print('PASS ownership, edits/conflict, follower media, profile, likes/comments, private tags, block', flush=True)
for pid in config['posts']:
    command(a, 'post_delete', {'id': pid})
assert len(command(a, 'posts', {'author': a['id']})['posts']) == 0
print('PASS deletion; files queued for worker cleanup', flush=True)
save()
