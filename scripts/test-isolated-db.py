"""Never run fixture tests against production. Required secrets hold an isolated DB."""
import os,sys,subprocess
from urllib.parse import urlparse,unquote
from pathlib import Path
u=urlparse(os.environ.get('KIYI_TEST_DATABASE_URL',''));allowed=os.environ.get('KIYI_TEST_ALLOWED_HOST','')
if not u.hostname or not allowed or u.hostname!=allowed or 'oswpkwwbjwyktuqcakhr' in u.geturl():sys.exit('REFUSED: explicitly allowlisted isolated database required')
env=dict(os.environ,PGHOST=u.hostname,PGPORT=str(u.port or 5432),PGDATABASE=u.path.lstrip('/'),PGUSER=unquote(u.username or ''),PGPASSWORD=unquote(u.password or ''),PGSSLMODE='require' if u.hostname not in ['localhost','127.0.0.1'] else 'prefer')
for name in ['stage3-garage','stage4-social','stage5-social','stage5-privacy-pagination','stage6-social','stage6-milestones','stage6-notification-privacy','domain-integration','domain-location','stage7-security','stage8-access','stage8-review','stage8-delivery','stage8-delivery-erasure','stage8-delivery-retention','loyalty-rewards','loyalty-eligibility','loyalty-thresholds','loyalty-vehicle-identity','loyalty-settlement','loyalty-config','badge-levels','referral-plate','manual-song-dedications']:
 subprocess.run(['psql','-X','-v','ON_ERROR_STOP=1','-f',str(Path('tests')/(name+'.sql'))],env=env,check=True)
