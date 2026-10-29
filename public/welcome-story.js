/* Compositor-only welcome animation with an autoplay attempt and a gesture fallback. */
(()=>{
 'use strict';
 const audioUrl='assets/welcome-story/music-v1.mp3';
 let stage=null,world=null,observer=null,animations=[],cues=[],clock=0,elapsed=0,paused=false,manuallyPaused=false;
 let music=null,context=null,musicGain=null,fxGain=null,enabled=false,userMuted=false,inIntro=false,session=0,playAttempt=0,playing=false;
 const voices=new Set();
 const now=()=>performance.now();
 const reduced=()=>typeof matchMedia==='function'&&matchMedia('(prefers-reduced-motion: reduce)').matches;
 function buttons(){
  for(const b of document.querySelectorAll('[data-story-pause]')){b.setAttribute('aria-pressed',String(manuallyPaused));b.setAttribute('aria-label',manuallyPaused?'Hikâyeyi sürdür':'Hikâyeyi duraklat');}
  for(const b of document.querySelectorAll('[data-story-sound]')){b.setAttribute('aria-pressed',String(enabled&&playing));b.setAttribute('aria-label',enabled?'Sesi kapat':'Sesi aç');const label=b.querySelector('span');if(label)label.textContent=playing&&enabled?'Ses açık':'Ses kapalı';}
 }
 function ensureAudio(){
  if(!music){const media=document.createElement('audio');music=media;media.id='welcome-story-music';media.src=audioUrl;media.loop=true;media.autoplay=true;media.preload='auto';media.volume=.24;media.hidden=true;media.dataset.playback='pending';media.addEventListener?.('playing',()=>{if(media===music){playing=true;media.dataset.playback='playing';delete media.dataset.playbackError;buttons();}});media.addEventListener?.('pause',()=>{if(media===music){playing=false;buttons();}});document.body.append(media);}
  if(!context){const AudioEngine=window.AudioContext||window.webkitAudioContext;if(AudioEngine){try{context=new AudioEngine();fxGain=context.createGain();fxGain.gain.value=.18;fxGain.connect(context.destination);}catch{context=null;fxGain=null;}}}
 }
 function connectMusic(){
  // A suspended Web Audio context must never swallow otherwise permitted HTML audio.
  if(!music||!context||context.state!=='running'||musicGain)return;
  musicGain=context.createGain();musicGain.gain.value=.24;context.createMediaElementSource(music).connect(musicGain).connect(context.destination);music.volume=1;
 }
 function playMusic(){
  if(!enabled||!inIntro||document.hidden)return;
  ensureAudio();const token=session,request=++playAttempt,media=music;
  context?.resume()?.then(connectMusic).catch(()=>{});connectMusic();
  if(fxGain)fxGain.gain.value=.18;
  const result=media.play();result?.then(()=>{if(token!==session||!enabled||!inIntro){media.pause();return;}if(request===playAttempt){playing=!media.paused;media.dataset.playback=playing?'playing':'paused';delete media.dataset.playbackError;buttons();}}).catch(error=>{if(token===session&&request===playAttempt){enabled=false;playing=false;media.dataset.playback=error.name==='NotAllowedError'?'blocked':'error';media.dataset.playbackError=error.name||'Error';buttons();}});
 }
 function prepareAudio(){inIntro=true;if(userMuted)return;enabled=true;playMusic();buttons();}
 function setSound(value){enabled=value;userMuted=!value;if(value)playMusic();else{playAttempt++;playing=false;music?.pause();if(fxGain)fxGain.gain.value=0;}buttons();}
 function unlockAudio(event){if(!inIntro||userMuted||event.target?.closest?.('[data-story-sound]'))return;if(!enabled||music?.paused||context?.state==='suspended'){enabled=true;playMusic();buttons();}}
 function tone(frequency,offset=.0,duration=.22,type='sine',volume=.25,endFrequency=frequency){
  if(!enabled||!context||context.state!=='running'||!fxGain)return;
  const t=context.currentTime+offset,osc=context.createOscillator(),gain=context.createGain();
  osc.type=type;osc.frequency.setValueAtTime(frequency,t);if(endFrequency!==frequency)osc.frequency.exponentialRampToValueAtTime(endFrequency,t+duration);
  gain.gain.setValueAtTime(.0001,t);gain.gain.exponentialRampToValueAtTime(volume,t+.018);gain.gain.exponentialRampToValueAtTime(.0001,t+duration);
  osc.connect(gain).connect(fxGain);voices.add(osc);osc.onended=()=>{voices.delete(osc);osc.disconnect();gain.disconnect();};osc.start(t);osc.stop(t+duration+.02);
 }
 function effect(name){
  if(name==='horn'){for(const offset of [0,.24]){tone(349,offset,.16,'sawtooth',.13);tone(440,offset,.16,'triangle',.24);}}
  else if(name==='gift'){tone(900,0,.13,'sine',.4,440);for(const [i,f] of [880,1175,1480].entries())tone(f,.09+i*.08,.24,'sine',.2);}
  else if(name==='smile'){for(const [i,f] of [784,1047,1319].entries())tone(f,i*.12,.3,'sine',.22);}
  else if(name==='reply'){tone(587,0,.28,'sine',.16);tone(784,.11,.32,'sine',.14);}
  else if(name==='brand'){tone(523,0,.5,'sine',.12);tone(784,.08,.55,'sine',.1);}
 }
 function stopCues(){for(const cue of cues)clearTimeout(cue.timer);}
 function scheduleCues(){clock=now();for(const cue of cues)if(!cue.done)cue.timer=setTimeout(()=>{cue.done=true;if(stage?.isConnected)cue.run();},Math.max(0,cue.at-elapsed));}
 function cue(at,run){cues.push({at,run,done:false,timer:0});}
 function phase(name,sound){if(stage){stage.dataset.phase=name;if(sound)effect(sound);}}
 function animate(selector,frames,options){const el=stage?.querySelector(selector);if(!el?.animate)return;animations.push(el.animate(frames,{fill:'both',...options}));}
 function suspend(){if(!stage||paused)return;elapsed+=now()-clock;paused=true;stopCues();for(const animation of animations)animation.pause();}
 function resume(){if(!stage||!paused||document.hidden)return;paused=false;for(const animation of animations)animation.play();scheduleCues();}
 function leavePage(){stopCues();for(const animation of animations)animation.cancel();animations=[];cues=[];observer?.disconnect();observer=null;stage=null;world=null;elapsed=0;paused=false;}
 function run(){
  if(!stage)return;stopCues();for(const a of animations)a.cancel();animations=[];cues=[];elapsed=0;paused=false;manuallyPaused=false;buttons();stage.dataset.phase='approach';
  stage.classList.remove('story-cta-ready');const bottom=stage.querySelector('.dream-welcome-bottom');if(bottom)bottom.setAttribute('inert','');
  const showContinue=()=>{bottom?.removeAttribute('inert');stage?.classList.add('story-cta-ready');};
  const pose=(x,y)=>`translate3d(${x}px,${y}px,0)`;
  if(reduced()){
   for(const [selector,transform] of [['.story-black',pose(480,1030)],['.story-white',pose(620,970)]]){const el=stage.querySelector(selector);el.style.transform=transform;}
   stage.classList.add('story-reduced');stage.dataset.phase='complete';showContinue();return;
  }
  stage.classList.remove('story-reduced');
  animate('.story-black',[{transform:pose(-180,1640),offset:0},{transform:pose(480,1030),offset:.30},{transform:pose(480,1030),offset:.66},{transform:pose(1130,380),offset:1}],{duration:11000,easing:'linear'});
  animate('.story-white',[{transform:pose(1130,460),offset:0},{transform:pose(620,970),offset:.30},{transform:pose(620,970),offset:.66},{transform:pose(-200,1750),offset:1}],{duration:11000,easing:'linear'});
  animate('.story-horn',[{opacity:0,transform:'scale(.5)'},{opacity:1,transform:'scale(1)',offset:.22},{opacity:0,transform:'scale(1.7)'}],{delay:2600,duration:650});
  animate('.story-tulip',[{opacity:0,transform:pose(480,930)+' scale(.2)',offset:0},{opacity:1,transform:pose(480,890)+' scale(1)',offset:.22},{opacity:1,transform:pose(480,890)+' scale(1)',offset:.42},{opacity:1,transform:pose(555,775)+' scale(.87)',offset:.7},{opacity:1,transform:pose(620,845)+' scale(.8)',offset:.88},{opacity:0,transform:pose(620,845)+' scale(.35)',offset:1}],{delay:3400,duration:1600,easing:'ease-in-out'});
  animate('.story-girl',[{opacity:0,transform:'translate(-50%,-100%) scale(.3)'},{opacity:1,transform:'translate(-50%,-100%) scale(1.13)',offset:.6},{opacity:1,transform:'translate(-50%,-100%) scale(1)'}],{delay:4800,duration:700,easing:'cubic-bezier(.2,.8,.3,1)'});
  animate('.story-boy',[{opacity:0,transform:'translate(-50%,-100%) scale(.3)'},{opacity:1,transform:'translate(-50%,-100%) scale(1.1)',offset:.6},{opacity:1,transform:'translate(-50%,-100%) scale(1)'}],{delay:5550,duration:500,easing:'cubic-bezier(.2,.8,.3,1)'});
  animate('.story-heart',[{opacity:0,transform:'translateY(0) scale(.5)'},{opacity:1,transform:'translateY(-15px) scale(1.15)',offset:.35},{opacity:0,transform:'translateY(-65px) scale(.8)'}],{delay:5000,duration:1100});
  animate('.dream-welcome-center .dream-welcome-logo-group',[{opacity:0,transform:'translateY(-95px) scale(.86)',filter:'blur(7px)'},{opacity:1,transform:'translateY(7px) scale(1.025)',filter:'blur(0)',offset:.78},{opacity:1,transform:'translateY(0) scale(1)',filter:'blur(0)'}],{delay:6100,duration:1000,easing:'cubic-bezier(.16,1,.3,1)'});
  animate('.story-tagline>span:first-child',[{opacity:0,transform:'translateY(6px)'},{opacity:1,transform:'translateY(0)'}],{delay:6650,duration:460,easing:'ease-out'});
  animate('.story-tagline>span:last-child',[{opacity:0,transform:'translateY(6px)'},{opacity:1,transform:'translateY(0)'}],{delay:6770,duration:460,easing:'ease-out'});
  animate('.dream-welcome-bottom',[{opacity:0,transform:'translateY(34px)',visibility:'hidden'},{opacity:1,transform:'translateY(0)',visibility:'visible'}],{delay:7000,duration:700,easing:'cubic-bezier(.16,1,.3,1)'});
  cue(2600,()=>phase('horn','horn'));cue(3400,()=>phase('gift','gift'));cue(4800,()=>phase('smile','smile'));cue(5550,()=>phase('boy-smile','reply'));cue(6100,()=>phase('brand','brand'));cue(7000,showContinue);cue(11000,()=>phase('complete'));
  scheduleCues();if(document.hidden)suspend();
 }
 function mount(root){
  leavePage();inIntro=true;stage=root.querySelector('.dream-welcome-story');if(!stage)return;world=stage.querySelector('.story-world');
  const measure=()=>{world?.style.setProperty('--story-scale',String(Math.max(stage.clientWidth/864,stage.clientHeight/1536)));};measure();
  if(typeof ResizeObserver==='function'){observer=new ResizeObserver(measure);observer.observe(stage);}
  stage.querySelector('[data-story-sound]')?.addEventListener('click',event=>{event.stopPropagation();if(enabled)setSound(false);else setSound(true);});
  stage.querySelector('[data-story-replay]')?.addEventListener('click',()=>run());
  stage.querySelector('[data-story-pause]')?.addEventListener('click',()=>{manuallyPaused=!manuallyPaused;if(manuallyPaused)suspend();else resume();buttons();});
  prepareAudio();buttons();run();
 }
 function stop(){leavePage();inIntro=false;enabled=false;userMuted=false;session++;playAttempt++;playing=false;music?.pause();if(music){music.removeAttribute('src');music.load();music.remove();music=null;}for(const voice of voices){try{voice.stop();}catch{}}voices.clear();context?.close()?.catch(()=>{});context=null;musicGain=null;fxGain=null;}
 for(const eventName of ['pointerdown','pointerup','touchend','keydown'])document.addEventListener(eventName,unlockAudio,{capture:true,passive:true});
 document.addEventListener('visibilitychange',()=>{if(document.hidden){suspend();music?.pause();}else{if(!manuallyPaused)resume();playMusic();}});
 window.PiyasoWelcome={prepareAudio,mount,suspend,leavePage,stop};
})();
