/* Remove the redundant profile drawer while preserving its real controls in Settings. */
let kiyiProfileSettingsStore=null;
const beforeCleanProfile=renderProfile;
renderProfile=function(){beforeCleanProfile();const drawer=document.querySelector('.wall-settings');if(!drawer)return;const store=document.createElement('div');store.className='profile-settings-content';drawer.querySelector(':scope>summary')?.remove();while(drawer.firstChild)store.append(drawer.firstChild);kiyiProfileSettingsStore=store;drawer.remove();if(document.querySelector('.profile-settings-dialog'))closeModal();};
window.openProfileAccountSettings=function(){if(!kiyiProfileSettingsStore){if(location.hash!=='#profile'){location.hash='profile';return;}renderProfile();}membershipDialog('<section class="profile-settings-dialog"><h2>Hesap ve görünürlük</h2><div class="profile-settings-mount"></div></section>');const mount=document.querySelector('.profile-settings-mount');if(mount&&kiyiProfileSettingsStore)mount.append(kiyiProfileSettingsStore);};
openProfileEditor=function(){if(globalThis.kiyiCloud?.active){openKiyiAccount();return;}openProfileAccountSettings();const details=document.querySelector('.profile-edit-details');if(details)details.open=true;document.querySelector('#profileform input')?.focus();};
const beforeCleanSettings=privacySupportDialog;
privacySupportDialog=function(){beforeCleanSettings();document.querySelector('#modal .dialog')?.insertAdjacentHTML('beforeend','<button class="btn secondary" onclick="openProfileAccountSettings()">Hesap ve görünürlük ayarları</button>');};
window.addEventListener('DOMContentLoaded',()=>{if(location.hash==='#profile')renderProfile();});
