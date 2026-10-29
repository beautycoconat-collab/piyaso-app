import {test} from 'node:test';import assert from 'node:assert/strict';
import {requestAccountDeletion} from '../public/deletion-request.mjs';
test('external deletion page requests only own deletion and closes only its temporary session',async()=>{
 const calls=[];await requestAccountDeletion({email:'test@example.invalid',password:'test-only-password',fetcher:async(url,options)=>{calls.push({url,options});return new Response(JSON.stringify(calls.length===1?{access_token:'test-token',user:{id:'fixture-user'}}:{}),{status:200})}});
 assert.equal(calls.length,3);assert.match(calls[0].url,/grant_type=password$/);assert.equal(calls[0].options.headers.Authorization,undefined);
 const body=JSON.parse(calls[1].options.body);assert.deepEqual(Object.keys(body.payload).sort(),['details','subject']);assert.equal(body.payload.subject,'delete_account');assert.equal(body.action,'privacy_request');assert.equal(calls[1].options.headers.Authorization,'Bearer test-token');assert.match(calls[2].url,/logout\?scope=local$/);
});
test('failed authentication cannot enqueue a deletion request',async()=>{let count=0;await assert.rejects(requestAccountDeletion({email:'test@example.invalid',password:'wrong',fetcher:async()=>{count++;return new Response('{}',{status:401})}}),/Giriş doğrulanamadı/);assert.equal(count,1);});
test('failed request is not reported as successful and temporary session is still closed',async()=>{const calls=[];await assert.rejects(requestAccountDeletion({email:'test@example.invalid',password:'test',fetcher:async url=>{calls.push(url);return calls.length===1?Response.json({access_token:'test-token',user:{id:'fixture'}}):new Response('{}',{status:calls.length===2?403:200})}}),/Talep kaydedilemedi/);assert.equal(calls.length,3);assert.match(calls[2],/scope=local$/);});
