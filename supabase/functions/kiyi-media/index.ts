const object=(x:unknown):Record<string,unknown>=>{if(x===null||typeof x!=='object'||Array.isArray(x))throw Error('Invalid service response');return x as Record<string,unknown>};
const base=Deno.env.get('SUPABASE_URL')!;
const key=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const cors={'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization, apikey, content-type','Access-Control-Allow-Methods':'POST, OPTIONS'};
const response=(data:unknown,status=200)=>new Response(JSON.stringify(data),{status,headers:{...cors,'Content-Type':'application/json','Cache-Control':'no-store'}});
async function api(path:string,options:RequestInit={}){const r=await fetch(base+path,{...options,headers:{apikey:key,Authorization:'Bearer '+key,...options.headers}});if(!r.ok)throw Error('Medya işlemi tamamlanamadı.');return r.status===204?{}:object(await r.json());}
const rpc=(action:string,payload:unknown)=>api('/rest/v1/rpc/kiyi_media_worker',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({action,payload})});
export function validSignature(b:Uint8Array,mime:string){const ascii=(n:number,s:string)=>[...s].every((c,i)=>b[n+i]===c.charCodeAt(0));if(mime==='image/jpeg')return b[0]===255&&b[1]===216&&b[2]===255;if(mime==='image/png')return b.length>=24&&[137,80,78,71,13,10,26,10].every((v,i)=>b[i]===v);if(mime==='image/webp')return ascii(0,'RIFF')&&ascii(8,'WEBP');if(mime.endsWith('/webm'))return [26,69,223,163].every((v,i)=>b[i]===v);if(mime.endsWith('/mp4'))return b.length>=16&&ascii(4,'ftyp');return false;}
Deno.serve(async(req:Request)=>{
 if(req.method==='OPTIONS')return new Response(null,{headers:cors});if(req.method!=='POST')return response({message:'Yöntem desteklenmiyor.'},405);
 try{
 if(req.headers.get('Content-Type')?.startsWith('application/json')){
 const body=object(await req.json());if(body.action!=='cleanup'||typeof body.secret!=='string'||body.secret.length!==64)return response({message:'Yetkisiz işlem.'},403);
 const result=await rpc('cleanup',{secret:body.secret});if(!Array.isArray(result.paths)||result.paths.some(p=>typeof p!=='string'))throw Error('Invalid cleanup paths');const paths=result.paths as string[];let deleted=0;
 for(const path of paths){try{await api('/storage/v1/object/kiyi-media',{method:'DELETE',headers:{'Content-Type':'application/json'},body:JSON.stringify({prefixes:[path]})});await rpc('ack',{path});deleted++;}catch{ /* Registry stays deleting and the next scheduled run retries. */ }}
 return response({deleted,pending:paths.length-deleted});
 }
 const token=req.headers.get('Authorization');if(!token?.startsWith('Bearer '))return response({message:'Giriş yapmalısın.'},401);
 const userResponse=await fetch(base+'/auth/v1/user',{headers:{apikey:key,Authorization:token}});if(!userResponse.ok)return response({message:'Oturum geçersiz.'},401);const user=object(await userResponse.json());if(typeof user.id!=='string')return response({message:'Oturum geçersiz.'},401);
 const mime=(req.headers.get('Content-Type')||'').split(';')[0];const limit=mime.startsWith('video/')?20971520:5242880;
 if(!['image/jpeg','image/png','image/webp','audio/webm','audio/mp4','video/mp4','video/webm'].includes(mime))return response({message:'Dosya türü desteklenmiyor.'},415);
 const reader=req.body?.getReader();if(!reader)return response({message:'Dosya boş.'},400);const chunks:Uint8Array[]=[];let size=0;
 while(true){const {done,value}=await reader.read();if(done)break;size+=value.length;if(size>limit){await reader.cancel();return response({message:'Dosya boyutu sınırı aşıldı.'},413);}chunks.push(value);}
 const bytes=new Uint8Array(size);let offset=0;for(const c of chunks){bytes.set(c,offset);offset+=c.length;}
 if(!validSignature(bytes,mime))return response({message:'Dosya içeriği ve türü uyuşmuyor.'},415);
 const permission=await fetch(base+'/rest/v1/rpc/kiyi_command',{method:'POST',headers:{apikey:key,Authorization:token,'Content-Type':'application/json'},body:JSON.stringify({action:'__stage7_guard',payload:{}})});
 if(!permission.ok)return response({message:'Oturum geçersiz veya hesap kullanıma kapalı.'},401);
 const {path}=await rpc('reserve',{owner:user.id,mime,bytes:size});if(typeof path!=='string')throw Error('Invalid media path');
 await api('/storage/v1/object/kiyi-media/'+path,{method:'POST',headers:{'Content-Type':mime,'x-upsert':'false'},body:bytes});
 await rpc('confirm',{path});return response({path});
 }catch{return response({message:'Medya işlemi tamamlanamadı; dosya sınırını veya hesap durumunu kontrol et.'},400);}
});
