import test from 'node:test';
import assert from 'node:assert/strict';
import {statusAPI} from '../lib/status-api.mjs';
function env(searchable=true){const log=[];return {log,BUCKET:{},DB:{prepare(sql){return {bind(...values){return {async first(){log.push({sql,values});return {profile:JSON.stringify({searchable})}},async all(){log.push({sql,values});return {results:[]}},async run(){log.push({sql,values});return {}}}}}}}}
}
const req=(method='GET',uid='viewer',body)=>new Request('https://example.com/api/status/visits?owner=someone-else',{method,headers:{...(uid?{'oai-authenticated-user-id':uid}:{}),'Content-Type':'application/json'},...(body?{body:JSON.stringify(body)}:{})});
test('visitors require authenticated account',async()=>{assert.equal((await statusAPI(req('GET',null),env())).status,401)});
test('visitor list is bound to authenticated owner, never supplied query',async()=>{const e=env();await statusAPI(req(),e);const query=e.log.find(q=>q.sql.includes('JOIN status_people'));assert.deepEqual(query.values,['viewer'])});
test('self visits do not insert records',async()=>{const e=env();await statusAPI(req('POST','viewer',{target:'viewer'}),e);assert.equal(e.log.some(q=>q.sql.startsWith('INSERT')),false)});
test('visits use authenticated viewer and valid target',async()=>{const e=env();await statusAPI(req('POST','viewer',{target:'owner',visitor:'forged'}),e);const query=e.log.find(q=>q.sql.startsWith('INSERT'));assert.deepEqual(query.values.slice(0,2),['owner','viewer'])});
test('closed profile receives no visit',async()=>{const e=env(false);assert.equal((await statusAPI(req('POST','viewer',{target:'owner'}),e)).status,404);assert.equal(e.log.some(q=>q.sql.startsWith('INSERT')),false)});
