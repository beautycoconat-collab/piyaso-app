// Provider acceptance is not proof of email/device delivery.
export async function runDelivery(channel,{backend,transport}={}){
 if(!['email','push'].includes(channel))throw Error('Invalid channel');
 if(typeof transport!=='function')return {status:'pending_configuration',accepted:0};
 const batch=await backend('claim',{channel});if(batch.status!=='claimed')return {status:batch.status,accepted:0};
 const result={status:'processed',accepted:0,retry:0,failed:0,cancelled:0,ackPending:0};
 for(const job of batch.jobs){const item=await backend('resolve',job);if(item.status!=='ready'){result.cancelled++;continue}let outcome;try{const r=await transport(item);outcome=r?.accepted===true?'accepted':r?.retryable===false?'rejected':'retry'}catch{outcome='retry'}try{await backend('ack',{...job,outcome});result[outcome==='accepted'?'accepted':outcome==='retry'?'retry':'failed']++}catch{result.ackPending++}}
 return result;
}
export function webhookTransport(url,token,allowedHosts,fetcher=fetch){
 if(!url||!token)return null;const u=new URL(url);if(u.protocol!=='https:'||(u.port&&u.port!=='443')||u.username||u.password||u.hash||u.search||!allowedHosts.includes(u.hostname))throw Error('Untrusted delivery endpoint');
 return async item=>{const r=await fetcher(u.href,{method:'POST',redirect:'error',signal:AbortSignal.timeout(15000),headers:{Authorization:'Bearer '+token,'Content-Type':'application/json','Idempotency-Key':item.idempotency_key},body:JSON.stringify({eventId:item.id,kind:item.kind,channel:item.channel,email:item.email,tokens:item.tokens,template:item.kind==='account_deletion'?'deletion':item.kind==='security'?'security':'activity'})});return {accepted:r.ok,retryable:r.status===408||r.status===429||r.status>=500}};
}
