import {writeFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';

// Only the browser publishable key may enter this generated, ignored file.
// Service-role/secret credentials belong exclusively in the server secret store.
const key=process.env.SUPABASE_PUBLISHABLE_KEY||'';
if(key&&!/^sb_publishable_[A-Za-z0-9_-]+$/.test(key)){
  throw new Error('SUPABASE_PUBLISHABLE_KEY must be a publishable key; server secrets are rejected.');
}
const target=fileURLToPath(new URL('../public/supabase-config.local.js',import.meta.url));
await writeFile(target,'/* Generated locally. Do not commit. */\nglobalThis.PIYASO_SUPABASE_PUBLISHABLE_KEY='+JSON.stringify(key)+';\n');
console.log(key?'Prepared local Supabase browser configuration.':'Prepared unconfigured Supabase placeholder; set SUPABASE_PUBLISHABLE_KEY before building for actual accounts.');
