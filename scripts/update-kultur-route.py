"""Retain OSM road geometry; west library link is aligned to the user's sketch."""
import json,math,xml.etree.ElementTree as E
from pathlib import Path
from shapely.geometry import LineString,Point,MultiPoint
from shapely.ops import substring,unary_union
R=Path(__file__).resolve().parents[1]
xscale=111320*math.cos(math.radians(36.905));yscale=111320
def xy(p):return (p[0]*xscale,p[1]*yscale)
def ll(p):return [round(p[1]/yscale,7),round(p[0]/xscale,7)]
r=E.parse(R/'data/kultur-map.osm').getroot();nodes={n.attrib['id']:(float(n.attrib['lon']),float(n.attrib['lat'])) for n in r.findall('node')}
ways={w.attrib['id']:LineString([xy(nodes[n.attrib['ref']]) for n in w.findall('nd')]) for w in r.findall('way') if len(w.findall('nd'))>1}
def cut(w,a,b):
 l=ways[w];return substring(l,l.project(Point(xy(a))),l.project(Point(xy(b))))
west75=cut('127312917',(30.64785,36.909),(30.6520564,36.9021324))
east75=cut('127312944',(30.65232,36.9021622),(30.6480507,36.9090073))
top=ways['91383049'];bottom=ways['127312949']
libtop=ways['209348760'];bottomroad=ways['653109419'];libSW=bottomroad.interpolate(bottomroad.project(Point(xy((30.64759,36.90187)))))
libbottom=substring(bottomroad,bottomroad.project(libSW),0)
# OSM lacks 3710's north/south link here. Keep this short screenshot-aligned
# connection explicit in provenance rather than claiming it is OSM geometry.
libwest=LineString([list(libtop.coords)[0],libSW.coords[0]])
libeast=cut('127312917',(30.6520564,36.9021324),(30.6513693,36.9034169))
loop=[]
for part in [LineString(list(libtop.coords)[::-1]),libwest,libbottom,libeast]:
 for p in part.coords:
  v=ll(p)
  if not loop or loop[-1]!=v:loop.append(v)
loop[-1]=loop[0]
roads=[('Kültür · Ulusoy Caddesi',top),('Kültür · 75. Yıl Caddesi, güney yönü',west75),('Kültür · 75. Yıl Caddesi, kuzey yönü',east75),('Kültür · 3805. Sokak bağlantısı',bottom),('Kültür · Antalya Kütüphanesi çevresi',LineString([xy((p[1],p[0])) for p in loop]))]
path=R/'dist/road-data.js';s=path.read_text();d=json.loads(s.split('const data=',1)[1].split(';if(typeof module',1)[0])
d['displayRoutes']=[v for v in d['displayRoutes'] if v['region']!='kultur']+[{'region':'kultur','name':n,'points':[ll(p) for p in l.coords]} for n,l in roads]
d['centerlines']=[v for v in d['centerlines'] if '3805' not in v['name'] and not v['name'].startswith('Kültür ·')]+[{'name':n,'points':[ll(p) for p in l.coords]} for n,l in roads]
d['routes']['d4']=loop;d['offsets']['d4']=100;d['centers']['kultur']=[36.9053,30.655];d['zooms']['kultur']=15;d['bounds']['kultur']=[[36.9013,30.6469],[36.9096,30.6634]]
d['zones']=[z for z in d['zones'] if z['region']!='kultur']
shape=unary_union([l for _,l in roads]).buffer(15)
for p in ([shape] if shape.geom_type=='Polygon' else shape.geoms):
 d['zones'].append({'name':'Kültür seçili yol güzergâhları','region':'kultur','draft':True,'points':[ll(v) for v in p.exterior.coords],'holes':[[ll(v) for v in ring.coords] for ring in p.interiors]})
d['provenance']['kulturUpdate']={'source':'OpenStreetMap API 0.6 map; user annotated screenshots','retrieved':'2026-10-21','libraryWestLink':'Approximate 3710 connection aligned to screenshot; not present in OSM extract','streets':['Ulusoy Caddesi','75. Yıl Caddesi','3805. Sokak','Antalya Kütüphanesi çevresi']}
hull=MultiPoint([(p[1],p[0]) for _,l in roads for p in [ll(v) for v in l.coords]]).convex_hull
d['kulturBoundary']=[[y,x] for x,y in hull.exterior.coords]
path.write_text('(function(root){const data='+json.dumps(d,separators=(',',':'))+';if(typeof module!=="undefined")module.exports=data;else root.RoadData=data;})(globalThis);\n')
(R/'data/kultur-loop-osrm.json').write_text(json.dumps({'source':'OSM geometry and user sketch; west library link approximate','routes':[{'geometry':{'coordinates':[[p[1],p[0]] for p in loop]}}]}))
(R/'data/kultur-selected-roads.json').write_text(json.dumps({'roads':[{'name':n,'points':[ll(p) for p in l.coords]} for n,l in roads],'provenance':d['provenance']['kulturUpdate']},ensure_ascii=False))
print('Kültür segments:',len(roads),'Library loop:',round(sum(LineString([xy((p[1],p[0])) for p in loop]).length for _ in [0])),'m')
