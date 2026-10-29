// Keep bundled legal/support pages inside the native WebView, even offline.
export function nativeLink(url, origin){
 let target;try{target=new URL(url,origin)}catch{return {kind:'blocked'}}
 if(target.username||target.password)return {kind:'blocked'};
 const base=new URL(origin);
 if(target.protocol===base.protocol&&target.host===base.host&&['/privacy.html','/terms.html','/location-privacy.html','/account-deletion.html','/support.html'].includes(target.pathname))return {kind:'local',url:target.href};
 if(target.protocol==='https:')return {kind:'external',url:target.href};
 return {kind:'blocked'};
}
