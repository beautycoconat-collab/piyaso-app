import os
"""Run with two disposable confirmed Auth accounts, never real customer credentials.
python tests/stage5-http-smoke.py /tmp/accounts.json
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


users = config['users']
for i, user in enumerate(users):
    status, data = request('/auth/v1/token?grant_type=password', body={'email': user['email'], 'password': user['password']})
    assert status == 200, ('auth', status)
    user['access_token'] = data['access_token']
    save()
    command(user, 'profile', {'username': 'stage5_' + user['id'][:8], 'searchable': True})
a, b = users
config['posts'] = []
save()
pid = command(a, 'post_create', {'text': 'Stage 5 public fixture'})['post']['id']
config['posts'].append(pid)
save()
v = command(b, 'vehicle_create', {'model': 'honda-pcx-125', 'plate': '07 SOC 591'})['id']
config['vehicles'] = [v]
save()
command(b, 'vehicle_update', {'vehicle_id': v, 'visibility': 'public'})
print('PASS two real Auth sessions, post and owned vehicle', flush=True)
for _ in range(2):
    result = command(b, 'like', {'id': pid, 'like': True, 'person': a['id']})['post']
    assert result['likes'] == 1 and result['liked']
assert command(b, 'post_get', {'id': pid})['post']['liked']
assert not command(a, 'post_get', {'id': pid})['post']['liked']
assert command(b, 'like', {'id': pid, 'like': False})['post']['likes'] == 0
denied(b, 'comment', {'id': pid, 'text': ' \n\t '})
result = command(b, 'comment', {'id': pid, 'text': 'First comment'})['post']
cid = result['comments'][0]['id']
denied(b, 'comment', {'id': pid, 'text': ' FIRST COMMENT '})
result = command(b, 'comment_edit', {'comment_id': cid, 'version': 1, 'text': 'Edited comment'})['post']
assert result['comments'][0]['text'] == 'Edited comment'
denied(a, 'comment_edit', {'comment_id': cid, 'version': 2, 'text': 'Owner cannot rewrite'})
denied(b, 'comment_edit', {'comment_id': cid, 'version': 1, 'text': 'Stale'})
assert command(a, 'comment_delete', {'comment_id': cid})['post']['commentCount'] == 0
cid = command(a, 'comment', {'id': pid, 'text': 'Author comment'})['post']['comments'][0]['id']
denied(b, 'comment_delete', {'comment_id': cid})
assert command(a, 'comment_delete', {'comment_id': cid})['post']['commentCount'] == 0
cid = command(b, 'comment', {'id': pid, 'text': 'My removable comment'})['post']['comments'][0]['id']
assert command(b, 'comment_delete', {'comment_id': cid})['post']['commentCount'] == 0
print('PASS like/unlike/reload/spoof isolation, comments/edit/delete, moderation, blank/spam/stale guards', flush=True)
private = command(a, 'post_create', {'text': 'Follower fixture', 'visibility': 'followers'})['post']['id']
config['posts'].append(private)
save()
denied(b, 'post_get', {'id': private})
command(b, 'follow', {'target': a['id'], 'enabled': True})
assert len(command(b, 'posts', {'filter': 'following', 'author': a['id']})['posts']) == 2
assert command(b, 'post_get', {'id': private})['post']['id'] == private
command(b, 'follow', {'target': a['id'], 'enabled': False})
assert len(command(b, 'posts', {'filter': 'following', 'author': a['id']})['posts']) == 0
denied(b, 'post_get', {'id': private})
assert not command(a, 'tag_search', {'plate': '07soc591'})['vehicles']
denied(a, 'post_edit', {'id': pid, 'version': 1, 'vehicle_id': v})
command(b, 'tag_settings', {'enabled': True})
assert command(a, 'tag_search', {'plate': '07 SOC 591'})['vehicles'][0]['id'] == v
result = command(a, 'post_edit', {'id': pid, 'version': 1, 'vehicle_id': v})['post']
assert result['vehicle']['plate'] == '07 SOC 591'
assert command(b, 'tagged_posts')['posts'][0]['canUntag']
command(b, 'post_untag', {'id': pid})
result = command(a, 'post_get', {'id': pid})['post']
assert result['vehicle'] is None
command(a, 'post_edit', {'id': pid, 'version': result['version'], 'vehicle_id': v})
command(b, 'tag_settings', {'enabled': False})
command(b, 'tag_settings', {'enabled': True})
result = command(a, 'post_get', {'id': pid})['post']
assert result['vehicle'] is None
command(a, 'post_edit', {'id': pid, 'version': result['version'], 'vehicle_id': v})
command(b, 'vehicle_update', {'vehicle_id': v, 'visibility': 'private'})
assert not command(a, 'tag_search', {'plate': '07soc591'})['vehicles']
assert not command(a, 'directory', {'plate': '07soc591'})['profiles']
assert command(a, 'post_get', {'id': pid})['post']['vehicle'] is None
print('PASS real follow/unfollow feed, private links, consent/search/untag/revocation/private plate', flush=True)
command(b, 'block', {'target': a['id'], 'enabled': True})
assert not command(b, 'posts', {'author': a['id']})['posts']
denied(b, 'post_get', {'id': pid})
denied(b, 'like', {'id': pid, 'like': True})
denied(b, 'comment', {'id': pid, 'text': 'Blocked comment'})
denied(b, 'post_delete', {'id': pid})
for post_id in config['posts']:
    command(a, 'post_delete', {'id': post_id})
assert not command(a, 'posts', {'author': a['id']})['posts']
for user in users:
    assert request('/auth/v1/logout', user)[0] in (200, 204)
print('PASS blocked links/interactions, unauthorized deletion, post cleanup, Auth logout', flush=True)
