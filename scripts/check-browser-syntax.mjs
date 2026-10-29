import {readdirSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
for(const file of readdirSync('public').filter(f=>f.endsWith('.js'))){const r=spawnSync(process.execPath,['--check',`public/${file}`],{encoding:'utf8'});if(r.status!==0){process.stderr.write(r.stderr);process.exit(1)}}
console.log('PASS browser JavaScript syntax');
