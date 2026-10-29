"""Named station areas: separate Bozkan, plus Kültür Shell and Erasta PO."""
import json
from pathlib import Path
from shapely.geometry import Point,Polygon,mapping
R=Path(__file__).resolve().parents[1];p=R/'dist/road-data.js';s=p.read_text();d=json.loads(s.split('const data=',1)[1].split(';if(typeof module',1)[0]);sx=89100;sy=111320
stations=[dict(region='bozkan',label='Bozkan',name='Shell · Metin Kasapoğlu Caddesi No:55',pos=[36.8676136,30.7253111],osmNodeId='4887536598'),dict(region='kultur',label='Kültür Shell',name='75. Yıl Caddesi No:60',pos=[36.9069077,30.6496525],osmNodeId='6036984726'),dict(region='kultur',label='Erasta Petrol Ofisi',name='Dumlupınar Bulvarı No:83 · Otogar PO',pos=[36.9112514,30.6648566],osmNodeId='6036984851')]
features=[]
for st in stations:
 lat,lon=st['pos'];a=Point(lon*sx,lat*sy).buffer(85)
 ring=[[round(x/sx,7),round(y/sy,7)] for x,y in a.exterior.coords]
 features.append(dict(type='Feature',properties={'region':st['region'],'label':st['label']},geometry={'type':'Polygon','coordinates':[ring]}))
d['stationAreas']={'type':'FeatureCollection','features':features};d['stations']=stations;d['centers']['bozkan']=stations[0]['pos'];d['zooms']['bozkan']=17
pts=d['kulturBoundary']+[x['pos'] for x in stations if x['region']=='kultur'];d['bounds']['kultur']=[[min(x[0] for x in pts)-.001,min(x[1] for x in pts)-.001],[max(x[0] for x in pts)+.001,max(x[1] for x in pts)+.001]]
d['provenance']['stations']={'retrieved':'2026-10-21','sources':['OpenStreetMap nodes','https://mevlanapetrol.com.tr/faaliyet-alanlarimiz/tunel-yikama','https://pilotgarage.com/en/dealers/antalya-kepez'],'note':'Erasta Otogar PO: former BP site, confirmed current operator address. Visual 85m surroundings.'}
p.write_text('(function(root){const data='+json.dumps(d,separators=(',',':'))+';if(typeof module!=="undefined")module.exports=data;else root.RoadData=data;})(globalThis);\n')
