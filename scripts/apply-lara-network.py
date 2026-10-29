"""Publish the researched full Eski Lara / Lara Caddesi network to the demo."""
import json,math
from pathlib import Path
from shapely.geometry import LineString,Point,Polygon,shape as geo_shape
from shapely.ops import unary_union
from shapely.affinity import scale
R=Path(__file__).resolve().parents[1];source=json.loads((R/'data/lara-complete-network.json').read_text());path=R/'dist/road-data.js';s=path.read_text();d=json.loads(s.split('const data=',1)[1].split(';if(typeof module',1)[0]);sx=89100;sy=111320
xy=lambda pts:[(p[1]*sx,p[0]*sy) for p in pts]
ll=lambda pts:[[round(y/sy,7),round(x/sx,7)] for x,y in pts]
loop=source['demoLoop'];end=loop.index(source['end']);outbound=loop[:end+1]
roads=[LineString(xy(r['points'])) for r in source['roads']];roads.append(LineString(xy(loop)))
bozkan_path=R/'data/lara-bozkan.json';bozkan=json.loads(bozkan_path.read_text()) if bozkan_path.exists() else None

shape=unary_union(roads)
# Fill the corridor around every road segment, rather than drawing a dark line.
coverage=shape.buffer(85)

between_path=R/'data/lara-between-streets.json'
if between_path.exists():
 between=json.loads(between_path.read_text())
 area=unary_union([Polygon(xy(p)) for p in between['polygons']])
 excluded=unary_union([Polygon(xy(p)) for p in between['exclusion']])
 coverage=coverage.union(area).difference(excluded.difference(shape.buffer(12)))
 d['provenance']['laraBetweenStreets']={'source':'OpenStreetMap road geometry and user requested boundary','roadCount':len(between['roads']),'excluded':'İsmet Gökşen Caddesi','boundaryOsmName':between['boundaryName']}
extra_path=R/'data/lara-screenshot-areas.geojson'
if extra_path.exists():
 extra=json.loads(extra_path.read_text())
 additions=unary_union([scale(geo_shape(f['geometry']),xfact=sx,yfact=sy,origin=(0,0)) for f in extra['features']])
 coverage=coverage.union(additions)
 d['provenance']['laraScreenshotExpansion']=extra['provenance']
excluded_path=R/'data/lara-excluded-avenues.json'
if excluded_path.exists():
 excluded_roads=json.loads(excluded_path.read_text())
 exclusions=unary_union([LineString(xy(r['points'])).buffer(24) for r in excluded_roads])
 # Retain only Lara's crossing itself, never the excluded avenue corridor.
 lara_streets=unary_union([LineString(xy(r['points'])) for r in source['roads']])
 exclusions=exclusions.difference(lara_streets.buffer(5))
 coverage=coverage.difference(exclusions)
 d['provenance']['laraExcludedAvenues']={'names':['Barınaklar Bulvarı','Havaalanı Caddesi'],'roadPieces':len(excluded_roads),'clearanceMeters':24}
parts=[coverage] if coverage.geom_type=='Polygon' else list(coverage.geoms)
d['laraCoverage']= {'type':'FeatureCollection','features':[{'type':'Feature','properties':{'region':'lara'},'geometry':{'type':'Polygon','coordinates':[[[lon,lat] for lat,lon in ll(ring.coords)] for ring in [p.exterior,*p.interiors]]}} for p in parts]}
d['laraCoveragePolygons']=[ll(p.exterior.coords) for p in parts]
d['zones']=[v for v in d['zones'] if v['region']!='lara'];zone=shape.buffer(15)
for p in ([zone] if zone.geom_type=='Polygon' else zone.geoms):d['zones'].append({'name':'Eski Lara Yolu / Lara Caddesi tam güzergâh','region':'lara','draft':True,'points':ll(p.exterior.coords),'holes':[ll(r.coords) for r in p.interiors]})
d['routes']['d2']=loop;d['offsets']['d2']=2700
for line in d['centerlines']:
 if 'Lara' in line['name']:line['points']=outbound;line['name']='Eski Lara Yolu / Lara Caddesi · Tam güzergâh'
for line in d['displayRoutes']:
 if line['region']=='lara':line['points']=loop;line['name']='Lara · Eski Lara Yolu ve Lara Caddesi tam güzergâh'
d['laraPlaces']=[]
d['laraEndpoints']=[{'label':'Başlangıç','name':source['startLabel'],'pos':source['start']},{'label':'Bitiş','name':source['endLabel'],'pos':source['end']}]
minx,miny,maxx,maxy=coverage.bounds;d['bounds']['lara']=[[miny/sy,minx/sx],[maxy/sy,maxx/sx]];d['centers']['lara']=[(miny+maxy)/2/sy,(minx+maxx)/2/sx];d['zooms']['lara']=12.5
km=round(LineString(xy(outbound)).length/1000,2);d['provenance']['laraComplete']={'source':'OpenStreetMap API 0.6, named public drivable ways','retrieved':'2026-10-21','osmWayCount':len(source['roads']),'outboundKm':km,'start':source['start'],'end':source['end'],'coverageBufferMeters':85,'demoRespectsOneWay':True}
path.write_text('(function(root){const data='+json.dumps(d,separators=(',',':'))+';if(typeof module!=="undefined")module.exports=data;else root.RoadData=data;})(globalThis);\n')
print('Full Lara route:',km,'km; coverage polygons:',len(parts),'road pieces:',len(source['roads']))
