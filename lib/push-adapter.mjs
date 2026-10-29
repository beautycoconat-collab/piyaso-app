// Server-side integration boundary; no permission prompt or network delivery here.
const events=new Set(['follow','like','comment','gift','song','verification','security','admin']);
export async function deliverPush(event,{transport,consented=false,preferences={},claim}={}){
 if(!events.has(event?.kind)||typeof event.id!=='string')throw Error('Invalid notification event');
 if(!consented||preferences[event.kind]===false)return {status:'disabled'};
 if(typeof transport!=='function')return {status:'pending_credentials'};
 if(typeof claim!=='function')throw Error('Durable idempotency claim required');
 // claim must be a durable delivery lease; failures must remain retryable.
 return claim(event.id,async()=>{await transport({id:event.id,kind:event.kind,targetId:event.targetId});return {status:'accepted'}});
}
