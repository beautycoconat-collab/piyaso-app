import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import {readFileSync} from 'node:fs';
test('manual song form sends trimmed text once and never queries a catalog',async()=>{
 let sent=[],html='';const input={value:'  Sezen Aksu – Gülümse  ',setCustomValidity(){},reportValidity(){}};
 const button={disabled:false,isConnected:true,textContent:''};const form={querySelector:()=>input};
 const context={openSongGift:null,statusMusic:null,selectedGiftSong:null,giftRecipient:null,CreditEconomy:{costs:{song:60}},giftName:()=> 'Alıcı',window:{},document:{getElementById:id=>({'manual-song-form':form,'manual-song-title':input,'manual-song-send':button}[id])},showGiftDialog(id,body){context.giftRecipient=id;html=body},async recordGift(data){sent.push(data)}};
 vm.createContext(context);vm.runInContext(readFileSync('public/music-picker.js','utf8'),context);
 context.openSongGift('recipient');assert.match(html,/Şarkı adı/);assert.doesNotMatch(html,/Apple|Spotify|katalog|musicresults/);
 await form.onsubmit({preventDefault(){}});assert.equal(sent.length,1);assert.equal(sent[0].song.title,'Sezen Aksu – Gülümse');assert.equal(sent[0].song.url,'');assert.equal(sent[0].song.source,'manual');
 input.value='   ';await form.onsubmit({preventDefault(){}});assert.equal(sent.length,1);
});
