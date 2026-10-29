// Dedicated account-deletion request page, not the mobile application's web version.
const base='https://oswpkwwbjwyktuqcakhr.supabase.co';
const key=(globalThis.PIYASO_SUPABASE_PUBLISHABLE_KEY||'YOUR_SUPABASE_PUBLISHABLE_KEY');
export async function requestAccountDeletion({email,password,details,fetcher=fetch}){
 let token;
 const call=(path,body,auth)=>fetcher(base+path,{method:'POST',signal:globalThis.AbortSignal?.timeout?.(15000),headers:{apikey:key,'Content-Type':'application/json',...(auth?{Authorization:'Bearer '+auth}:{})},body:JSON.stringify(body)});
 try{
  const login=await call('/auth/v1/token?grant_type=password',{email:String(email).trim(),password},null);
  if(!login.ok)throw Error(login.status===429?'Çok fazla deneme yapıldı. Biraz sonra yeniden dene.':'Giriş doğrulanamadı. Bilgilerini ve e-posta doğrulamanı kontrol et.');
  const session=await login.json();token=session?.access_token;
  if(typeof token!=='string'||!session?.user?.id)throw Error('Giriş doğrulanamadı.');
  const response=await call('/rest/v1/rpc/kiyi_command',{action:'privacy_request',payload:{subject:'delete_account',details:String(details||'Hesabımın ve ilişkili Piyaso verilerimin silinmesini istiyorum.').slice(0,1000)}},token);
  if(!response.ok)throw Error('Talep kaydedilemedi. Daha sonra yeniden dene veya uygulama içi destek bölümünü kullan.');
 }finally{
  // Close only the temporary session used here; never sign out the other devices.
  if(token)try{await call('/auth/v1/logout?scope=local',{},token)}catch{/* Token is never persisted on this page. */}
  token=null;
 }
}
if(typeof document!=='undefined'){
 const form=document.getElementById('deletion-request-form'),status=document.getElementById('deletion-request-status');
 if(form)form.addEventListener('submit',async event=>{
  event.preventDefault();const button=form.querySelector('button[type="submit"]');button.disabled=true;status.textContent='Talebin kaydediliyor…';
  try{await requestAccountDeletion({email:form.elements.email.value,password:form.elements.password.value});form.reset();status.textContent='Silme talebin kaydedildi. Bu, silme işleminin tamamlandığı anlamına gelmez. Talebinin durumunu uygulamadaki Destek ve hesap talepleri bölümünden izleyebilirsin.';}
  catch(error){status.textContent=error instanceof TypeError||error.name==='TimeoutError'?'Bağlantı kurulamadı. İnternetini kontrol edip yeniden dene.':error.message;}
  finally{form.elements.password.value='';button.disabled=false;}
 });
}
