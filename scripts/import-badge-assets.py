"""Optimize supplied badges without cropping or recoloring. Source ZIP is not committed."""
import json,sys,zipfile,pathlib
from PIL import Image
z=zipfile.ZipFile(sys.argv[1]);dest=pathlib.Path('public/assets/badges');dest.mkdir(parents=True,exist_ok=True);mapping={}
for name in z.namelist():
 if not name.lower().endswith('.png'):continue
 stem=pathlib.Path(name).stem;out=stem.lower()+'.webp';image=Image.open(z.open(name));image.thumbnail((320,320));image.save(dest/out,quality=88,method=6);mapping[stem]='assets/badges/'+out
(dest/'source-map.json').write_text(json.dumps(mapping,ensure_ascii=False,indent=2));print(f'Imported {len(mapping)} badge assets')
