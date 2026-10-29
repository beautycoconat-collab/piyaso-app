process.on('uncaughtException',e=>{console.error(e.message,e.detail||'',e.where||'',e.position||'');process.exit(1)});
