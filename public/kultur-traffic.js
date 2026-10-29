/* Existing OSM-sourced 3805 and northern streets; exclude the library car loop. */
const kulturStreetRoutes=RoadData.centerlines.filter(r=>r.name.startsWith('Kültür ·')&&!r.name.includes('Kütüphanesi'));
for(let i=0;i<kulturStreetRoutes.length;i++){const points=kulturStreetRoutes[i].points,key='kultur-street-'+i;demoRoutes[key]=RoadEngine.prepare([...points,...points.slice(0,-1).reverse()])}
const kulturCars=['d4','traffic-0','traffic-1','traffic-2','traffic-3','traffic-4','fenomen-1786'];
kulturCars.forEach((id,i)=>{const p=profiles.find(p=>p.id===id);if(!p||!kulturStreetRoutes.length)return;const order=[3,3,0,1,2,0,3],index=order[i]%kulturStreetRoutes.length;p.routeSource='kultur-street-'+index;p.motion=TrafficMotion.settings(i+31,demoRoutes[p.routeSource].length)});
