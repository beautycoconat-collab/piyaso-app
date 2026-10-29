import {test,after} from 'node:test';
import fs from 'node:fs/promises';
import {createMobileDB} from './testing/mobile-db.mjs';
const db=await createMobileDB();
after(()=>db.close());
const suites=['stage3-garage','stage4-social','stage5-social','stage5-privacy-pagination','stage6-social','stage6-milestones','stage6-notification-privacy','domain-integration','domain-location','stage7-security','stage8-access','stage8-review','stage8-delivery','stage8-delivery-erasure','stage8-delivery-retention','loyalty-rewards','loyalty-eligibility','loyalty-thresholds','loyalty-vehicle-identity','loyalty-settlement','loyalty-config','badge-levels','referral-plate','manual-song-dedications'];
for(const name of suites)test(name,async()=>{
 try{await db.exec(await fs.readFile(new URL('../tests/'+name+'.sql',import.meta.url),'utf8'));}
 finally{await db.exec('rollback;reset role;');}
});
