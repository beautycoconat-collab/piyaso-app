"""Build bundled demo geometry. Requires shapely (pip install shapely).
Public OpenStreetMap geometries via OSRM/Nominatim, retained in data/.
"""
import json,math,re
from pathlib import Path
from shapely.geometry import LineString
from shapely.ops import unary_union
ROOT=Path(__file__).resolve().parents[1]
def load(name):return json.loads((ROOT/'data'/name).read_text())['routes'][0]
def latlon(points):return [[p[1],p[0]] for i,p in enumerate(points) if i==0 or p!=points[i-1]]
sx=111320*math.cos(math.radians(36.86));sy=111320
ox,oy=30.6*sx,36.8*sy
def line(points):return LineString([(p[1]*sx-ox,p[0]*sy-oy) for p in points])
def zones(name,shape,group):
    shape=shape.buffer(0)
    parts=list(shape.geoms) if shape.geom_type=='MultiPolygon' else [shape]
    return [{'name':name,'region':group,'draft':True,'points':[[round((y+oy)/sy,7),round((x+ox)/sx,7)] for x,y in p.exterior.coords],'holes':[[[round((y+oy)/sy,7),round((x+ox)/sx,7)] for x,y in ring.coords] for ring in p.interiors]} for p in parts]
coast=latlon(load('konyaalti-expanded-outbound-osrm.json')['geometry']['coordinates'])
lara=[]
for leg in load('lara-source-osrm.json')['legs']:
 for step in leg['steps']:
  if step['name'] in ['Eski Lara Yolu','Lara Caddesi']:lara+=latlon(step['geometry']['coordinates'])
lara=[p for i,p in enumerate(lara) if i==0 or p!=lara[i-1]]
kultur=latlon(json.loads((ROOT/'data/kultur-nominatim.json').read_text()))
coastloop=latlon(load('konyaalti-expanded-loop-osrm.json')['geometry']['coordinates'])
laraloop=latlon(load('lara-loop-osrm.json')['geometry']['coordinates'])
kulturloop=latlon(load('kultur-loop-osrm.json')['geometry']['coordinates'])
neighborhoodloop=latlon(load('konyaalti-neighborhood-loop-osrm.json')['geometry']['coordinates'])
# Road-only eligibility corridors. Keep interior holes: residential blocks
# inside a road loop must not become eligible simply because they are enclosed.
network=json.loads((ROOT/'data/konyaalti-street-network.json').read_text())
coastshape=unary_union([line(road['points']) for road in network['roads']]+[line(coast)]).buffer(15)
kulturshape=line(kulturloop).buffer(15)
allzones=zones('Konyaaltı yol güzergâhları',coastshape,'konyaalti')+zones('Lara yol güzergâhları',line(laraloop).buffer(15),'lara')+zones('Kültür yol güzergâhları',kulturshape,'kultur')
d={'provenance':{'source':'OpenStreetMap / OSRM Route Service / Nominatim','retrieved':'2026-10-21','license':'ODbL 1.0','demoOnly':True,'draftBoundaries':True,'displayMode':'road-lines-only','roadToleranceMeters':15,'limanParkingEndpointConfirmed':False},'centerlines':[{'name':'Akdeniz Bulvarı · Liman yönü','points':coast},{'name':'Eski Lara Yolu / Lara Caddesi','points':lara},{'name':'3805. Sokak · Kafeler Caddesi','points':kultur}],'displayRoutes':[{'region':'konyaalti','name':'Konyaaltı · Ana sahil güzergâhı','points':coast},{'region':'lara','name':'Lara · Eski Lara Yolu ve dönüş bağlantıları','points':laraloop},{'region':'kultur','name':'Kültür · 3805. Sokak ve dönüş bağlantıları','points':kulturloop}],'secondaryRoads':[r for r in network['roads'] if re.search(r'cadde|bulvar',r['name'],re.I)],'selectionBoundary':network['boundary'],'networkTestHousePoint':network['testHousePoint'],'zones':allzones,'routes':{'d1':coastloop,'d2':laraloop,'d3':neighborhoodloop,'d4':kulturloop},'offsets':{'d1':3500,'d2':2700,'d3':800,'d4':400},'centers':{'konyaalti':[36.863,30.638],'lara':[36.8589,30.7365],'kultur':[36.9028,30.6573]},'zooms':{'konyaalti':14,'lara':14.5,'kultur':15},'bounds':{'konyaalti':[[36.844,30.603],[36.886,30.665]],'lara':[[36.853,30.725],[36.866,30.745]],'kultur':[[36.899,30.649],[36.908,30.665]]}}
(ROOT/'dist'/'road-data.js').write_text('(function(root){const data='+json.dumps(d,separators=(',',':'))+';if(typeof module!=="undefined")module.exports=data;else root.RoadData=data;})(globalThis);\n')
print('Road vertices:',len(coast),len(lara),len(kultur),'Zones:',len(allzones))

# Apply the later screenshot-selected Kültür network after the baseline build.
import subprocess,sys
subprocess.run([sys.executable,str(ROOT/"scripts/update-kultur-route.py")],check=True)

subprocess.run([sys.executable,str(ROOT/"scripts/update-konyaalti-coverage.py")],check=True)

subprocess.run([sys.executable,str(ROOT/"scripts/expand-kultur-coverage.py")],check=True)

subprocess.run([sys.executable,str(ROOT/"scripts/apply-lara-network.py")],check=True)

subprocess.run([sys.executable,str(ROOT/"scripts/add-station-areas.py")],check=True)
