"""Trace every drivable Eski Lara Yolu / Lara Caddesi OSM segment.
The demo's closed traversal respects one-way and private-access tags.
"""
import json,math,heapq,xml.etree.ElementTree as E
from pathlib import Path
from shapely.geometry import LineString,Point
from shapely.ops import unary_union
R=Path(__file__).resolve().parents[1];nodes={};ways={}
for p in (R/'data').glob('lara-*.osm'):
 root=E.parse(p).getroot();nodes.update({n.attrib['id']:[float(n.attrib['lat']),float(n.attrib['lon'])] for n in root.findall('node')});ways.update({w.attrib['id']:w for w in root.findall('way')})
allowed={'primary','primary_link','secondary','secondary_link','tertiary','tertiary_link','residential','unclassified','living_street','service','trunk','trunk_link'}
roads=[]
for wid,w in ways.items():
 t={e.attrib['k']:e.attrib['v'] for e in w.findall('tag')};refs=[n.attrib['ref'] for n in w.findall('nd')]
 if t.get('highway') not in allowed or any(t.get(k) in {'private','no'} for k in ['access','vehicle','motor_vehicle','motorcar']) or not all(v in nodes for v in refs):continue
 roads.append({'id':wid,'name':t.get('name',''),'kind':t['highway'],'oneway':t.get('oneway','yes' if t.get('junction')=='roundabout' else ''),'refs':refs})
selected=[r for r in roads if r['name'] in ['Eski Lara Yolu','Lara Caddesi']]
def meters(a,b):return math.hypot((a[1]-b[1])*89100,(a[0]-b[0])*111320)
graph={}
for r in roads:
 for a,b in zip(r['refs'],r['refs'][1:]):
  weight=meters(nodes[a],nodes[b])*(1 if r in selected else 4)
  if r['oneway']!='-1':graph.setdefault(a,[]).append((b,weight))
  if r['oneway'] not in ['yes','1','true']:graph.setdefault(b,[]).append((a,weight))
def nearest(point):return min((v for r in selected for v in r['refs']),key=lambda v:meters(nodes[v],point))
def path(a,b):
 dist={a:0};prev={};q=[(0,a)]
 while q:
  cost,u=heapq.heappop(q)
  if cost!=dist[u]:continue
  if u==b:
   chain=[u]
   while u!=a:u=prev[u];chain.append(u)
   return chain[::-1]
  for v,w in graph.get(u,[]):
   n=cost+w
   if n<dist.get(v,float('inf')):dist[v]=n;prev[v]=u;heapq.heappush(q,(n,v))
 raise RuntimeError('No drivable connection: '+a+' -> '+b)
waypoints=[[36.8644798,30.7277036],[36.848807,30.7527884],[36.8511967,30.7809638],[36.8532729,30.8038042],[36.8486805,30.8084467],[36.8614088,30.8485557]]
refs=[nearest(p) for p in waypoints];sequence=refs+refs[-2::-1];loop=[]
for a,b in zip(sequence,sequence[1:]):
 for v in path(a,b):
  p=nodes[v]
  if not loop or p!=loop[-1]:loop.append(p)
sx=89100;sy=111320
xy=lambda pts:[(p[1]*sx,p[0]*sy) for p in pts]
ll=lambda pts:[[round(y/sy,7),round(x/sx,7)] for x,y in pts]
source={'source':'OpenStreetMap API 0.6 map, 2026-10-21','license':'ODbL 1.0','start':nodes[refs[0]],'end':nodes[refs[-1]],'startLabel':'Akra / Metin Kasapoğlu kavşağı','endLabel':'Lara Caddesi doğu bağlantısı','roads':[{'osmWayId':r['id'],'name':r['name'],'oneway':r['oneway'],'points':[nodes[v] for v in r['refs']]} for r in selected],'demoLoop':loop}
(R/'data/lara-complete-network.json').write_text(json.dumps(source,separators=(',',':'),ensure_ascii=False))
# Source fragments are reproducible from the OSM snapshot, not a route-service response.
(R/'data/lara-loop-osrm.json').write_text(json.dumps({'source':'OSM directed drivable graph','routes':[{'geometry':{'coordinates':[[p[1],p[0]] for p in loop]}}]},separators=(',',':')))
print('Named road segments:',len(selected),'Start:',source['start'],'End:',source['end'],'Demo loop km:',round(sum(meters(a,b) for a,b in zip(loop,loop[1:]))/1000,2))
