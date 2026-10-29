// Server-only coordinator. Adapters must never be supplied by the caller.
// Default disabled: shared Auth and retention policy need operator approval.
export class ErasureError extends Error {
 constructor(code,status=409){super(code);this.code=code;this.status=status;}
}
export async function eraseAccount({token,password,confirmation}, services, config={}){
 if(config.enabled!==true||config.authScope!=='exclusive'||config.policy!=='free-account-erasure-v1')throw new ErasureError('DELETION_NOT_CONFIGURED',503);
 if(confirmation!=='SİL'||typeof password!=='string'||password.length<8||password.length>128)throw new ErasureError('CONFIRMATION_REQUIRED',400);
 if(typeof token!=='string'||!token.startsWith('Bearer '))throw new ErasureError('AUTH_REQUIRED',401);
 const user=await services.currentUser(token);
 if(!user?.id||!user.email)throw new ErasureError('AUTH_REQUIRED',401);
 // Email is obtained from validated Auth, never from the request body.
 const fresh=await services.reauthenticate(user.email,password);
 if(fresh?.user?.id!==user.id||!fresh.access_token)throw new ErasureError('REAUTH_FAILED',401);
 // Preflight rejects shared-domain references, admins and real paid orders.
 // Prepare fences uploads and all normal RPC operations before object deletion.
 const prepared=await services.prepare(user.id);
 if(prepared.status!=='prepared'||!Array.isArray(prepared.paths)||prepared.paths.some(p=>typeof p!=='string'||!p.startsWith(user.id+'/')))throw new ErasureError('UNSAFE_DELETION_SCOPE');
 await services.signOutAll('Bearer '+fresh.access_token);
 // Partial failures never produce a completed result. A fresh password retry
 // resumes the same fenced account and deletes the same objects idempotently.
 for(let i=0;i<prepared.paths.length;i+=100)await services.removeObjects(prepared.paths.slice(i,i+100));
 await services.purgePersonalData(user.id);
 await services.deleteAuthUser(user.id);
 if(await services.authUserExists(user.id))throw new ErasureError('AUTH_DELETION_UNCONFIRMED',502);
 return {status:'deleted',authDeleted:true};
}
