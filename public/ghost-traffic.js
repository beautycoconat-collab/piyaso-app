/* Synthetic traffic, using existing road geometry. No real users or live locations. */
const extraTrafficNames=['Ada','Ece','Defne','Selin','İpek','Bora','Can','Deniz','Eren','Mert'];
for(let i=0;i<10;i++){
 const kultur=i<5,routeSource=kultur?'d4':'d2';
 profiles.push({id:'traffic-'+i,name:extraTrafficNames[i],ownerName:extraTrafficNames[i],plate:'07 DEM '+String(110+i),car:['Volkswagen Golf','BMW 3 Serisi','Audi A3','MINI Cooper','Peugeot 208'][i%5],year:'2023',color:i%2?'Siyah':'Beyaz',paint:i%2?'#3b4347':'#edece4',area:kultur?'Kültür':'Lara',bio:'Kurgusal demo araç. Hareket mevcut yol geometrisinde simüle edilir.',instagram:'',tiktok:'',searchable:true,sharing:true,visibility:'all',approved:[],premium:true,ghost:true,routeSource,demoOffset:(i%5+1)*520,updated:Date.now()});
}
