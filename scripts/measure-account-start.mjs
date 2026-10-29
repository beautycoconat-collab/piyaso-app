import fs from 'node:fs';import vm from 'node:vm';import {execFileSync} from 'node:child_process';import {performance} from 'node:perf_hooks';
const test=fs.readFileSync('tests/supabase-account.test.mjs','utf8');const helper=test.slice(test.indexOf('async function app()'),test.indexOf("test('account hydration"));
const sources={stage7:execFileSync('git',['show','ea941bb3464e99f73a18985fb8a81b2076fa4f5b:public/supabase-account.js'],{encoding:'utf8'}),stage8:fs.readFileSync('public/supabase-account.js','utf8')};
const output={method:'20 sequential mock-HTTP hydration runs, no real network/device/LCP claim',results:{}};
for(const [name,source]of Object.entries(sources)){const app=new Function('source','vm',helper+';return app;')(source,vm);let requests=0;const start=performance.now();for(let i=0;i<20;i++){const a=await app();requests+=a.calls.length}output.results[name]={meanMockRequests:requests/20,meanCpuMs:(performance.now()-start)/20}}
console.log(JSON.stringify(output,null,2));
