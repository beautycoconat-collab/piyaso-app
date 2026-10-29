"""Visible selection area includes the full Konyaaltı demo routes and their edges."""
import json,math
from pathlib import Path
from shapely.geometry import Polygon,LineString
from shapely.ops import unary_union
R=Path(__file__).resolve().parents[1];p=R/'dist/road-data.js';s=p.read_text();d=json.loads(s.split('const data=',1)[1].split(';if(typeof module',1)[0])
sx=111320*math.cos(math.radians(36.86));sy=111320
xy=lambda v:(v[1]*sx,v[0]*sy)
shape=unary_union([Polygon([xy(v) for v in d['selectionBoundary']])]+[LineString([xy(v) for v in d['routes'][id]]).buffer(35) for id in ['d1','d3']]).buffer(8)
assert shape.geom_type=='Polygon',shape.geom_type
d['konyaaltiCoverageBoundary']=[[round(y/sy,7),round(x/sx,7)] for x,y in shape.exterior.coords]
p.write_text('(function(root){const data='+json.dumps(d,separators=(',',':'))+';if(typeof module!=="undefined")module.exports=data;else root.RoadData=data;})(globalThis);\n')
print('Konyaaltı coverage includes both complete routes with a soft margin')
