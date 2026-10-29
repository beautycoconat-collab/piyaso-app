(function(root){
'use strict';
const clean=(v,max)=>String(v??'').trim().slice(0,max);
function validateMeetup(input,now=Date.now()){
 const title=clean(input.title,70),place=clean(input.place,120),description=clean(input.description,500),region=clean(input.region,20),startsAt=Number(input.startsAt),capacity=Number(input.capacity);
 if(title.length<3||place.length<3)return {error:'Başlık ve buluşma yeri en az 3 karakter olmalı.'};
 if(!['Konyaaltı','Lara','Kültür','Bozkan'].includes(region))return {error:'Bir bölge seç.'};
 if(!Number.isFinite(startsAt)||startsAt<=now+5*60000||startsAt>now+180*86400000)return {error:'Buluşma zamanını 5 dakika ile 180 gün sonrası arasında seç.'};
 if(!Number.isInteger(capacity)||capacity<2||capacity>100)return {error:'Katılımcı sınırı 2–100 kişi olmalı.'};
 return {value:{title,place,description,region,startsAt,capacity}};
}
function rsvp(meetup,userId='me',now=Date.now()){
 if(meetup.status==='cancelled'||meetup.startsAt<=now)return {error:'Bu buluşma için katılım kapalı.'};
 const attendees=[...new Set(meetup.attendees||[])];
 if(attendees.includes(userId)){if(meetup.creatorId===userId)return {error:'Düzenlediğin buluşmadan ayrılmak yerine buluşmayı iptal edebilirsin.'};return {value:{...meetup,attendees:attendees.filter(x=>x!==userId)}}}
 if(attendees.length>=meetup.capacity)return {error:'Buluşmanın kontenjanı doldu.'};return {value:{...meetup,attendees:[...attendees,userId]}};
}
function verification(input,profile,now=Date.now()){
 const plate=clean(input.plate,18).toLocaleUpperCase('tr-TR').replace(/\s/g,''),current=clean(profile.plate,18).toLocaleUpperCase('tr-TR').replace(/\s/g,'');
 if(!plate||plate!==current)return {error:'Başvuru plakası profilindeki plakayla aynı olmalı.'};
 if(input.consent!==true)return {error:'İnceleme koşullarını kabul etmelisin.'};
 const note=clean(input.note,500);if(note.length<10)return {error:'Araçla ilişkini en az 10 karakterle açıkla.'};
 return {value:{status:'draft',plate:clean(profile.plate,18),note,createdAt:now,profileName:clean(profile.ownerName||profile.name,60)}};
}
function giftDirection(g){return g.recipient==='me'?'received':'sent'}
const api={validateMeetup,rsvp,verification,giftDirection};if(typeof module!=='undefined'&&module.exports)module.exports=api;else root.CommunityCore=api;
})(globalThis);
