/* Account deletion result must come from the server; requests are not completion. */
(()=>{
'use strict';
const account=openKiyiAccount;openKiyiAccount=function(...args){account(...args);if(kiyiCloud.supportActive)document.querySelector('.kiyi-account-dialog')?.insertAdjacentHTML('beforeend','<button class="textbtn" onclick="kiyiSignOutOthers()">Diğer cihazlardan çıkış yap</button><button class="textbtn" onclick="openKiyiDeleteAccount()">Hesabımı sil ›</button>')};
window.openKiyiDeleteAccount=()=>{
 if(!kiyiCloud.supportActive){openKiyiAccount();return}
 membershipDialog('<section class="kiyi-delete-account"><h2>Piyaso hesabını sil</h2><p>Hesabın, profilin, garajın, paylaşımların, medyan ve ücretsiz jetonların kalıcı olarak silinir. Bu işlem geri alınamaz. Yasal saklama veya ortak giriş kimliği nedeniyle işlem yapılamıyorsa tamamlandı bilgisi gösterilmez.</p><form id="kiyi-delete-request"><label class="field">Güncel şifren<input name="password" type="password" autocomplete="current-password" minlength="8" maxlength="128" required></label><label class="field">Onaylamak için SİL yaz<input name="confirmation" autocomplete="off" required></label><button class="btn danger">Hesabımı kalıcı olarak sil</button><p role="status" aria-live="polite"></p></form><button class="textbtn" onclick="openKiyiAccount()">Vazgeç</button></section>');
 document.getElementById('kiyi-delete-request').onsubmit=async e=>{
  e.preventDefault();const f=e.target,b=f.querySelector('button'),message=f.querySelector('[role="status"]');
  if(b.disabled)return;
  if(f.elements.confirmation.value.trim()!=='SİL'){message.textContent='Onay için SİL yazmalısın.';return}
  const password=f.elements.password.value;
  if(password.length<8){message.textContent='Güncel şifreni gir.';return}
  b.disabled=true;message.textContent='Hesabın doğrulanıyor ve siliniyor…';
  try{const result=await window.PiyasoAuth.deleteAccount(password,'SİL');if(result?.status!=='deleted'||result.authDeleted!==true)throw Error('Silme tamamlanmadı.');membershipDialog('<section class="kiyi-delete-account"><h2>Hesabın silindi</h2><p>Giriş kimliğin ve hesabına bağlı verilerin silindi. Oturumun kapatıldı.</p><button class="btn" onclick="closeModal()">Tamam</button></section>')}
  catch(error){message.textContent=error.message;b.disabled=false}
  finally{f.elements.password.value=''}
 };
};
})();
