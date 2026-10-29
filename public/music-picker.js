/* User-written song dedications. No external catalog or music playback. */
openSongGift=function(id){
 selectedGiftSong=null;
 showGiftDialog(id,`<h2 id="gift-title">Şarkı gönder</h2><p class="gift-recipient">${giftName(id)} için göndermek istediğin şarkının adını yaz.</p><form id="manual-song-form"><label class="field" for="manual-song-title">Şarkı adı<input id="manual-song-title" name="title" required maxlength="150" placeholder="Örn. Tarkan – Kuzu Kuzu" autocomplete="off"></label><p class="hint">Yazdığın şarkı adı kişiye mesaj olarak gönderilir.</p><button class="btn" type="submit" id="manual-song-send">Gönder · ${CreditEconomy.costs.song} jeton</button></form>`);
 if(giftRecipient!==id)return;
 if(window.kiyiCloud?.active)document.querySelector('#modal .gift-demo-note')?.remove();
 const form=document.getElementById('manual-song-form');
 form.onsubmit=async e=>{
  e.preventDefault();const input=document.getElementById('manual-song-title'),title=input.value.trim();
  if(!title){input.setCustomValidity('Şarkı adını yaz.');input.reportValidity();return}
  input.setCustomValidity('');const button=document.getElementById('manual-song-send');
  if(button.disabled)return;button.disabled=true;button.textContent='Gönderiliyor…';
  selectedGiftSong={source:'manual',title,artist:'',url:'',artwork:''};
  try{await recordGift({type:'song',song:{...selectedGiftSong}})}finally{if(button.isConnected){button.disabled=false;button.textContent='Gönder · '+CreditEconomy.costs.song+' jeton'}};
 };
 form.querySelector('input').oninput=e=>e.target.setCustomValidity('');
};
statusMusic=function(){
 statusSheet('<h3>Şarkı adı ekle</h3><form id="manual-status-song"><label class="field">Şarkı adı<input name="title" maxlength="150" required placeholder="Şarkı ve sanatçı adı"></label><button class="btn" type="submit">Ekle</button></form>');
 document.getElementById('manual-status-song').onsubmit=e=>{e.preventDefault();const title=e.target.elements.title.value.trim();if(!title||!statusDraft)return;statusDraft.music={id:'manual',source:'manual',title,artist:'Kullanıcı tarafından yazıldı',url:'',artwork:''};closeStatusSheet();renderStatusAttachments();statusInput()};
};
