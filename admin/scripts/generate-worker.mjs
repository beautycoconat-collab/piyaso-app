import {readFile,writeFile} from 'node:fs/promises';
const base=new URL('../',import.meta.url);
let source=await readFile(new URL('worker/server.template.mjs',base),'utf8');
for(const [marker,path] of [['__PAGE__','src/index.html'],['__CLIENT__','src/app.js'],['__STYLE__','src/style.css']]){let value=await readFile(new URL(path,base),'utf8');if(marker==='__CLIENT__')value+='\n'+await readFile(new URL('src/operations.js',base),'utf8');source=source.replace(marker,()=>JSON.stringify(value));}
await writeFile(new URL('worker/index.js',base),source);
