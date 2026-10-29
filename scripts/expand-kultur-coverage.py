"""Extend Kültür's visual selection using the user's orange screenshot outline.
This is a visual area, not an expansion of road-only location eligibility.
"""
import json
from pathlib import Path
from shapely.geometry import Polygon
from shapely.ops import unary_union
R=Path(__file__).resolve().parents[1];p=R/'dist/road-data.js';s=p.read_text();d=json.loads(s.split('const data=',1)[1].split(';if(typeof module',1)[0])
south=[[36.9021622,30.65232],[36.90096,30.65210],[36.90094,30.6556],[36.90095,30.6609],[36.90132,30.66415],[36.9022263,30.6624784]]
east=[[36.90132,30.66415],[36.90228,30.66432],[36.90370,30.66391],[36.90595,30.66340],[36.90620,30.66236],[36.9049,30.66155],[36.9022263,30.6624784]]
poly=lambda pts:Polygon([(v[1],v[0]) for v in pts])
shape=unary_union([poly(d['kulturBoundary']),poly(south),poly(east)]).buffer(0)
assert shape.geom_type=='Polygon' and shape.is_valid
boundary=[[round(y,7),round(x,7)] for x,y in shape.exterior.coords]
d['kulturBoundary']=boundary
d['provenance']['kulturCoverageExpansion']={'source':'User orange annotated screenshot IMG_1744','approximate':True,'areas':['South blocks up to the north side of D400','Dumlupınar frontage on the east side of Kültür']}
p.write_text('(function(root){const data='+json.dumps(d,separators=(',',':'))+';if(typeof module!=="undefined")module.exports=data;else root.RoadData=data;})(globalThis);\n')
for test in [[36.9015,30.656],[36.9015,30.660],[36.9035,30.6635]]:
 from shapely.geometry import Point
 assert shape.covers(Point(test[1],test[0]))
print('Kültür: south strip and east frontage included in one connected area')
