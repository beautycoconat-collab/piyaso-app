import {Capacitor} from '@capacitor/core';
import {App} from '@capacitor/app';
import {Browser} from '@capacitor/browser';
import {Share} from '@capacitor/share';
import {nativeLink} from './link-policy.js';
import {handleNativeBack,handleNativeState} from './lifecycle.js';
if(Capacitor.isNativePlatform()){
 window.KiyiNativePlatform=Capacitor.getPlatform();
 window.KiyiPublicOrigin='https://kiyi-antalya-tur.modesttuna8.chatgpt.site';
 window.KiyiAPIOrigin=window.KiyiPublicOrigin;
 document.documentElement.classList.add(Capacitor.getPlatform()==='ios'?'native-ios':'native-android');
 App.addListener('appStateChange',({isActive})=>handleNativeState({isActive,doc:document,refresh:()=>window.kiyiCloud?.active?window.kiyiCloud.refresh():undefined}));
 if(Capacitor.getPlatform()==='android')App.addListener('backButton',({canGoBack})=>{
  Promise.resolve(handleNativeBack({doc:document,win:window,app:App,canGoBack})).catch(()=>{
   document.dispatchEvent(new CustomEvent('kiyi:native-error',{detail:'Geri dönülemedi. Yeniden dene.'}));
  });
 });
 // Open external content in the system browser, never inside the app's trusted view.
 document.addEventListener('click',event=>{const anchor=event.target.closest?.('a[target="_blank"]');if(!anchor)return;const link=nativeLink(anchor.href,location.href);event.preventDefault();if(link.kind==='local'){location.assign(link.url);return}if(link.kind==='blocked')return;Browser.open({url:link.url}).catch(()=>{document.dispatchEvent(new CustomEvent('kiyi:native-error',{detail:'Bağlantı açılamadı. İnternet bağlantını kontrol et.'}))})},true);
 if(!navigator.share)navigator.share=async data=>{const args={title:String(data.title||'Piyaso'),text:String(data.text||'')};if(data.url){const url=new URL(data.url);if(url.protocol!=='https:')throw Error('Geçersiz paylaşım bağlantısı');args.url=url.href}await Share.share(args)};
}
