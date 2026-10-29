// Separate admin origin. No service-role key; every RPC uses the caller's JWT.
const COOKIE='__Host-kiyi_admin';
const encoder=new TextEncoder();
function b64(bytes){let s='';for(const v of bytes)s+=String.fromCharCode(v);return btoa(s).replace(/\+/g,'-').replace(/\//g,'_').replace(/=+$/,'');}
function bytes(value){return Uint8Array.from(atob(value.replace(/-/g,'+').replace(/_/g,'/')),c=>c.charCodeAt(0));}
async function key(env){if(!env.ADMIN_COOKIE_SECRET||env.ADMIN_COOKIE_SECRET.length<32)throw Object.assign(Error('CONFIG_REQUIRED'),{status:503});return crypto.subtle.importKey('raw',await crypto.subtle.digest('SHA-256',encoder.encode(env.ADMIN_COOKIE_SECRET)),'AES-GCM',false,['encrypt','decrypt']);}
export async function seal(value,env){const iv=crypto.getRandomValues(new Uint8Array(12));return b64(iv)+'.'+b64(new Uint8Array(await crypto.subtle.encrypt({name:'AES-GCM',iv,additionalData:encoder.encode(COOKIE)},await key(env),encoder.encode(JSON.stringify(value)))));}
export async function unseal(value,env){try{const [iv,data]=value.split('.');return JSON.parse(new TextDecoder().decode(await crypto.subtle.decrypt({name:'AES-GCM',iv:bytes(iv),additionalData:encoder.encode(COOKIE)},await key(env),bytes(data))));}catch{return null;}}
const cookie=value=>COOKIE+'='+value+'; Path=/; HttpOnly; Secure; SameSite=Strict; Max-Age=28800';
const clearCookie=()=>COOKIE+'=; Path=/; HttpOnly; Secure; SameSite=Strict; Max-Age=0';
function failure(code,status=400){return Object.assign(Error(code),{status});}
function config(env){if(!/^https:\/\/[-a-z0-9]+\.supabase\.co$/.test(env.SUPABASE_URL||'')||!env.SUPABASE_PUBLISHABLE_KEY||!env.ADMIN_COOKIE_SECRET)throw failure('CONFIG_REQUIRED',503);}
const messages={ADMIN_STATISTICS_NOT_READY:'İstatistik özeti hazırlanıyor. Birkaç dakika sonra yenileyin.',CONFIG_REQUIRED:'Güvenli kurulum henüz tamamlanmadı.',ADMIN_PROVIDER_REQUIRED:'Bu işlem için doğrulanmış mağaza/ödeme bağlantısı gerekiyor.',ADMIN_DELETION_WORKFLOW_REQUIRED:'Önce bekleyen medya silme işini tamamla.',ADMIN_INSUFFICIENT_BALANCE:'Bu düzeltme bakiyeyi sıfırın altına düşürüyor.',ADMIN_INVALID_INPUT:'Alanları ve işlem gerekçesini kontrol et.',ADMIN_UNKNOWN_ACTION:'Bu işlem henüz desteklenmiyor.',ADMIN_DENIED:'Bu panel için yetkin bulunmuyor.',ADMIN_MFA_REQUIRED:'Doğrulama uygulamasındaki kodla devam et.',ADMIN_REAUTH_REQUIRED:'Güvenli oturumun sona erdi. Yeniden giriş yap.',ADMIN_VERSION_CONFLICT:'Kayıt başka bir yetkili tarafından değiştirildi. Listeyi yenile.',ADMIN_REQUEST_CONFLICT:'İşlem kimliği farklı bir istek için kullanılmış.',ADMIN_OWNER_PROTECTED:'Sahip hesabı bu ekrandan değiştirilemez.',LOGIN_FAILED:'Giriş tamamlanamadı. Hesabını ve yetkini kontrol et.',MFA_FAILED:'Doğrulama kodu kabul edilmedi. Yeniden dene.',RATE_LIMITED:'Çok fazla deneme yapıldı. Biraz sonra yeniden dene.',INVALID_REQUEST:'İstek tamamlanamadı.',SESSION_REQUIRED:'Devam etmek için giriş yap.',UPSTREAM_UNAVAILABLE:'Hesap hizmetine şu an ulaşılamıyor.'};
const headers={'Cache-Control':'no-store, private','Referrer-Policy':'no-referrer','X-Content-Type-Options':'nosniff','X-Frame-Options':'DENY','Permissions-Policy':'geolocation=(),camera=(),microphone=()'};
function json(data,status=200,setCookie){return new Response(JSON.stringify(data),{status,headers:{...headers,'Content-Type':'application/json; charset=utf-8',...(setCookie?{'Set-Cookie':setCookie}:{})}});}
async function upstream(env,path,{token,body,method='POST',fetcher=fetch}={}){
 let r;try{r=await fetcher(env.SUPABASE_URL+path,{method,headers:{apikey:env.SUPABASE_PUBLISHABLE_KEY,'Content-Type':'application/json',...(token?{Authorization:'Bearer '+token}:{})},...(body!==undefined?{body:JSON.stringify(body)}:{}),signal:AbortSignal.timeout(12000)});}catch{throw failure('UPSTREAM_UNAVAILABLE',503);}
 const d=await r.json().catch(()=>({}));if(!r.ok){if(r.status===429)throw failure('RATE_LIMITED',429);const code=Object.keys(messages).find(c=>d.message===c);throw failure(code||(path.includes('/factors')?'MFA_FAILED':path.includes('/rpc/')?'ADMIN_DENIED':'LOGIN_FAILED'),r.status>=500?503:403);}return d;
}
const rpc=(env,token,action,payload={},fetcher)=>upstream(env,'/rest/v1/rpc/kiyi_admin_command',{token,body:{action,payload},fetcher});
function sessionFrom(d,start=Date.now()){if(!d.access_token||!d.refresh_token)throw failure('SESSION_REQUIRED',401);return {access:d.access_token,refresh:d.refresh_token,start};}
function claims(token){try{return JSON.parse(new TextDecoder().decode(bytes(token.split('.')[1])))}catch{return {};}}
async function session(request,env,fetcher){const value=(request.headers.get('Cookie')||'').split(';').map(x=>x.trim()).find(x=>x.startsWith(COOKIE+'='))?.slice(COOKIE.length+1);let s=value?await unseal(value,env):null;if(!s||Date.now()-s.start>8*3600000||s.start>Date.now()+30000)throw failure('SESSION_REQUIRED',401);
 // Claims only schedule refresh; /user and PostgREST verify authenticity/authorization.
 if((Number(claims(s.access).exp)||0)*1000<Date.now()+60000){const d=await upstream(env,'/auth/v1/token?grant_type=refresh_token',{body:{refresh_token:s.refresh},fetcher});s=sessionFrom(d,s.start);}
 await upstream(env,'/auth/v1/user',{token:s.access,method:'GET',fetcher});return s;
}
const attempts=new Map();
function throttle(request){const ip=request.headers.get('CF-Connecting-IP')||'local';const now=Date.now();if(attempts.size>5000)for(const [k,v]of attempts)if(v.until<now)attempts.delete(k);let a=attempts.get(ip);if(!a||a.until<now)a={count:0,until:now+60000};a.count++;attempts.set(ip,a);if(a.count>20)throw failure('RATE_LIMITED',429);}
export async function api(request,env,fetcher=fetch){let s;const url=new URL(request.url);try{
 config(env);if(request.method!=='POST'||request.headers.get('Origin')!==url.origin||!/^application\/json(?:;|$)/i.test(request.headers.get('Content-Type')||'')||['cross-site','none'].includes(request.headers.get('Sec-Fetch-Site')))throw failure('INVALID_REQUEST',403);
 if(Number(request.headers.get('Content-Length')||0)>12000)throw failure('INVALID_REQUEST',413);const reader=request.body?.getReader();let chunks=[],size=0;if(reader){while(true){const part=await reader.read();if(part.done)break;size+=part.value.byteLength;if(size>12000){await reader.cancel();throw failure('INVALID_REQUEST',413);}chunks.push(part.value);}}const all=new Uint8Array(size);let offset=0;for(const chunk of chunks){all.set(chunk,offset);offset+=chunk.byteLength;}const raw=new TextDecoder().decode(all);let body;try{body=JSON.parse(raw)}catch{throw failure('INVALID_REQUEST');}if(!body||typeof body!=='object'||Array.isArray(body))throw failure('INVALID_REQUEST');
 if(url.pathname==='/api/login'){
  throttle(request);if(typeof body.email!=='string'||body.email.length>254||typeof body.password!=='string'||body.password.length>128)throw failure('LOGIN_FAILED',403);
  s=sessionFrom(await upstream(env,'/auth/v1/token?grant_type=password',{body:{email:body.email.trim(),password:body.password},fetcher}));
  await rpc(env,s.access,'probe',{},fetcher);return json({ok:true},200,cookie(await seal(s,env)));
 }
 if(url.pathname==='/api/logout'){
  try{s=await session(request,env,fetcher);await rpc(env,s.access,'logout',{},fetcher);await upstream(env,'/auth/v1/logout?scope=local',{token:s.access,fetcher});}catch{}return json({ok:true},200,clearCookie());
 }
 s=await session(request,env,fetcher);
 if(url.pathname.startsWith('/api/mfa/')){
  await rpc(env,s.access,'probe',{},fetcher);throttle(request);
  if(url.pathname==='/api/mfa/factors'){
   const user=await upstream(env,'/auth/v1/user',{token:s.access,method:'GET',fetcher});return json({factors:(user.factors||[]).filter(x=>x.factor_type==='totp').map(x=>({id:x.id,status:x.status,friendly_name:x.friendly_name}))},200,cookie(await seal(s,env)));
  }
  if(url.pathname==='/api/mfa/enroll'){
   const user=await upstream(env,'/auth/v1/user',{token:s.access,method:'GET',fetcher});
   if((user.factors||[]).some(f=>f.status==='verified'))throw failure('MFA_FAILED',403);
   const d=await upstream(env,'/auth/v1/factors',{token:s.access,body:{factor_type:'totp',friendly_name:'Piyaso Admin '+new Date().toISOString().slice(0,16)},fetcher});return json({id:d.id,totp:d.totp},200,cookie(await seal(s,env)));
  }
  if(url.pathname==='/api/mfa/verify'){
   if(!/^[a-f0-9-]{36}$/i.test(body.factor_id||'')||!/^\d{6}$/.test(body.code||''))throw failure('MFA_FAILED',403);
   const c=await upstream(env,'/auth/v1/factors/'+body.factor_id+'/challenge',{token:s.access,body:{},fetcher});const d=await upstream(env,'/auth/v1/factors/'+body.factor_id+'/verify',{token:s.access,body:{challenge_id:c.id,code:body.code},fetcher});s=sessionFrom(d,s.start);const me=await rpc(env,s.access,'session',{},fetcher);return json({me},200,cookie(await seal(s,env)));
  }
  throw failure('INVALID_REQUEST',404);
 }
 if(url.pathname==='/api/media'){
  if(typeof body.path!=='string'||body.path.length>150)throw failure('INVALID_REQUEST');
  await rpc(env,s.access,'media',{op:'sign',path:body.path},fetcher);
  const d=await upstream(env,'/storage/v1/object/sign/kiyi-media/'+body.path.split('/').map(encodeURIComponent).join('/'),{token:s.access,body:{expiresIn:60},fetcher});
  if(!d.signedURL?.startsWith('/object/sign/kiyi-media/'))throw failure('INVALID_REQUEST');
  return json({url:env.SUPABASE_URL+'/storage/v1'+d.signedURL},200,cookie(await seal(s,env)));
 }
 if(url.pathname==='/api/erase'){
  const batch=await rpc(env,s.access,'media',{op:'batch',job_id:body.job_id},fetcher);
  if(batch.paths?.length)await upstream(env,'/storage/v1/object/kiyi-media',{token:s.access,method:'DELETE',body:{prefixes:batch.paths},fetcher});
  const remaining=await rpc(env,s.access,'media',{op:'batch',job_id:body.job_id},fetcher);
  if(!remaining.paths?.length)await rpc(env,s.access,'media',{op:'finish',job_id:body.job_id},fetcher);
  return json({completed:!remaining.paths?.length,removed:batch.paths?.length||0},200,cookie(await seal(s,env)));
 }
 if(url.pathname==='/api/command'){
  if(!['session','summary','users','audit','staff','staff_grant','staff_revoke','ops'].includes(body.action))throw failure('INVALID_REQUEST',404);
  const d=await rpc(env,s.access,body.action,body.payload||{},fetcher);return json(d,200,cookie(await seal(s,env)));
 }
 throw failure('INVALID_REQUEST',404);
 }catch(e){const code=messages[e.message]?e.message:'INVALID_REQUEST';return json({error:code,message:messages[code]},e.status||400,['SESSION_REQUIRED','ADMIN_DENIED','LOGIN_FAILED'].includes(code)?clearCookie():undefined);}
}
/* UI injected below by the source generator. All data use textContent. */
const PAGE=__PAGE__;
export default {async fetch(request,env){const path=new URL(request.url).pathname;if(path.startsWith('/api/'))return api(request,env);if(request.method!=='GET'||!['/','/app.js','/style.css'].includes(path))return new Response('Bulunamadı',{status:404,headers});if(path==='/app.js')return new Response(CLIENT,{headers:{...headers,'Content-Type':'text/javascript; charset=utf-8'}});if(path==='/style.css')return new Response(STYLE,{headers:{...headers,'Content-Type':'text/css; charset=utf-8'}});return new Response(PAGE,{headers:{...headers,'Content-Type':'text/html; charset=utf-8','Content-Security-Policy':"default-src 'none'; script-src 'self'; style-src 'self'; connect-src 'self'; img-src 'self' data:; base-uri 'none'; form-action 'self'; frame-ancestors 'none'"}});}};
const CLIENT=__CLIENT__;
const STYLE=__STYLE__;
