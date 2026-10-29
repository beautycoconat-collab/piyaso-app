"""Extract public drivable OSM ways inside the user's screenshot outline.
Input: OSM map extracts retained in scratch. Output: compact reproducible snapshot.
Does not infer individual traffic lanes when OSM provides only road centre lines.
"""
import json,xml.etree.ElementTree as ET,sys
from pathlib import Path
from shapely.geometry import LineString,Polygon
ROOT=Path(__file__).resolve().parents[1]
# Approximate georeferencing of the user's yellow sketch. North edge follows
# Atatürk Bulvarı; east edge follows Dumlupınar's coastal connection.
boundary=[[36.84625,30.6047],[36.84755,30.6114],[36.8520,30.6161],[36.86115,30.6269],[36.8654,30.6334],[36.86855,30.6384],[36.8726,30.6414],[36.8750,30.64255],[36.8800,30.6500],[36.88525,30.66225],[36.8849,30.6636],[36.8770,30.6621],[36.8740,30.6581],[36.8690,30.6506],[36.8625,30.6404],[36.8520,30.6256],[36.8471,30.6185],[36.8461,30.6115],[36.8460,30.6050]]
polygon=Polygon([(p[1],p[0]) for p in boundary]);assert polygon.is_valid
nodes={};ways={}
for path in sys.argv[1:]:
 r=ET.parse(path).getroot()
 for n in r.findall('node'):nodes[n.attrib['id']]=[float(n.attrib['lon']),float(n.attrib['lat'])]
 for w in r.findall('way'):ways[w.attrib['id']]=w
allowed={'primary','primary_link','secondary','secondary_link','tertiary','tertiary_link','residential','unclassified','living_street','service'}
roads=[];excluded=0
for wid,w in ways.items():
 tags={t.attrib['k']:t.attrib['v'] for t in w.findall('tag')}
 if tags.get('highway') not in allowed:continue
 if any(tags.get(k) in {'no','private'} for k in ['access','vehicle','motor_vehicle','motorcar']):excluded+=1;continue
 refs=[n.attrib['ref'] for n in w.findall('nd')]
 if not all(n in nodes for n in refs):continue
 geometry=LineString([nodes[n] for n in refs]);clipped=geometry.intersection(polygon)
 parts=list(clipped.geoms) if clipped.geom_type in ['MultiLineString','GeometryCollection'] else [clipped]
 for part in parts:
  if part.geom_type!='LineString' or part.length<.000025:continue
  points=[[round(lat,7),round(lon,7)] for lon,lat in part.coords]
  roads.append({'osmWayId':int(wid),'name':tags.get('name','Bağlantı yolu'),'kind':tags['highway'],'points':points})
roads.sort(key=lambda r:(r['osmWayId'],r['points'][0]))
# Retain a test house centroid away from drivable centre lines, within outline.
from shapely.ops import unary_union
roadshape=unary_union([LineString([(p[1],p[0]) for p in r['points']]) for r in roads])
house=None
for w in ways.values():
 tags={t.attrib['k']:t.attrib['v'] for t in w.findall('tag')}
 if not tags.get('building'):continue
 refs=[n.attrib['ref'] for n in w.findall('nd')]
 if len(refs)<4 or not all(n in nodes for n in refs):continue
 shape=Polygon([nodes[n] for n in refs]);p=shape.centroid
 if shape.is_valid and polygon.contains(p) and p.distance(roadshape)>.0004:
  house=[round(p.y,7),round(p.x,7)];break
result={'source':'OpenStreetMap API 0.6 map extracts','license':'ODbL 1.0','retrieved':'2026-10-21','boundaryApproximation':'User yellow screenshot, aligned with Atatürk Bulvarı and coastal connection','boundary':boundary,'roads':roads,'privateWaysExcluded':excluded,'testHousePoint':house}
(ROOT/'data/konyaalti-street-network.json').write_text(json.dumps(result,separators=(',',':')))
print('Public road pieces:',len(roads),'Private/no-access ways excluded:',excluded,'House test:',house)
