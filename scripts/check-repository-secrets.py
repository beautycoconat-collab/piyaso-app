import base64, json, re, subprocess, sys
from pathlib import Path

root = Path(sys.argv[1])
rows = subprocess.check_output(['git','rev-list','--objects','HEAD'],cwd=root).decode().splitlines()
names = {row.split(' ',1)[0]:row.split(' ',1)[1] if ' ' in row else '' for row in rows}
p = subprocess.Popen(['git','cat-file','--batch'],cwd=root,stdin=subprocess.PIPE,stdout=subprocess.PIPE)
rules = {
 'supabase_publishable_key': rb'\bsb_publishable_[A-Za-z0-9_-]{16,}',
 'openai_key': rb'\bsk-(?:proj-|svcacct-)?[A-Za-z0-9_-]{32,}',
 'supabase_secret': rb'\bsb_secret_[A-Za-z0-9_-]{16,}',
 'github_token': rb'\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,})',
 'private_key': rb'-----BEGIN (?:RSA |EC |OPENSSH |ENCRYPTED )?PRIVATE KEY-----',
 'aws_access_key': rb'\b(?:AKIA|ASIA)[A-Z0-9]{16}\b',
 'credential_url': rb'(?:postgres(?:ql)?|https?)://[^\s/<>"\x27:]+:[^\s/<>"\x27@]{8,}@',
 'sites_token': rb'\bart_v2_[A-Za-z0-9_]{16,}',
}
findings=[]; blobs=0; total=0
for oid in names:
 p.stdin.write((oid+'\n').encode()); p.stdin.flush()
 header=p.stdout.readline().decode().split()
 if len(header)!=3: raise RuntimeError('Invalid Git object response')
 size=int(header[2]); data=p.stdout.read(size); p.stdout.read(1)
 if header[1]!='blob': continue
 blobs+=1; total+=size
 for kind, pattern in rules.items():
  if re.search(pattern,data): findings.append({'object':oid,'path':names[oid],'kind':kind})
 for m in re.finditer(rb'eyJ[A-Za-z0-9_-]+\.([A-Za-z0-9_-]+)\.[A-Za-z0-9_-]+',data):
  try: payload=json.loads(base64.urlsafe_b64decode(m[1]+b'='*((-len(m[1]))%4)))
  except Exception: continue
  if payload.get('role') in ('service_role','anon'): findings.append({'object':oid,'path':names[oid],'kind':payload['role']+'_jwt'})
p.stdin.close(); p.wait()
result={'scope':'all blobs reachable from HEAD, including administration history','blobs_scanned':blobs,'bytes_scanned':total,'findings':findings,'limit':'Pattern scan does not prove absence of every credential format.'}
print(json.dumps(result,indent=2))
sys.exit(bool(findings))
