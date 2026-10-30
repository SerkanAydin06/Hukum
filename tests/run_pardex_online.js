// Real PARDEX control plane + real HÜKÜM dedicated server + three game clients.
const assert = require('assert');
const fs = require('fs');
const os = require('os');
const path = require('path');
const net = require('net');
const crypto = require('crypto');
const {spawn} = require('child_process');
const binary = process.argv[2] || 'godot';
const serverDir = path.resolve(process.argv[3] || 'tests/pardex/server');
const WebSocket = require(path.join(serverDir, 'node_modules/ws'));
const root = path.resolve(__dirname, '..');
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'hukum-online-'));
const processes = [], sockets = [], gameLogs = [];
const serverToken = crypto.randomBytes(32).toString('hex');
let officialResult;
const wait = (ms) => new Promise(resolve => setTimeout(resolve, ms));
function freePort() {
  return new Promise(resolve => {
    const server = net.createServer();
    server.listen(0, '127.0.0.1', () => {const p=server.address().port;server.close(()=>resolve(p));});
  });
}
function next(ws, predicate, timeout=10000) {
  return new Promise((resolve,reject) => {
    const timer=setTimeout(()=>{ws.off('message',handler);reject(Error('Control-plane message timeout'));},timeout);
    function handler(raw) {let msg;try{msg=JSON.parse(raw.toString());}catch{return;}
      if (predicate(msg)){clearTimeout(timer);ws.off('message',handler);resolve(msg);}}
    ws.on('message',handler);
  });
}
function start(cmd,args,options={}) {
  const p=spawn(cmd,args,{stdio:['ignore','pipe','pipe'],...options});
  p.log='';p.stdout.on('data',b=>p.log+=b);p.stderr.on('data',b=>p.log+=b);
  p.completed=new Promise(resolve=>{p.once('error',e=>{p.log+=e.message;resolve(-1);});p.once('exit',code=>resolve(code));});
  processes.push(p);return p;
}
async function until(predicate, timeout=15000) {
  const end=Date.now()+timeout;while(!predicate()){if(Date.now()>end)throw Error('Process state timeout');await wait(50);}
}
async function connect(url) {
  const ws = new WebSocket(url);sockets.push(ws);
  await new Promise((resolve,reject)=>{ws.once('open',resolve);ws.once('error',reject);});return ws;
}
async function main() {
  const controlPort=await freePort(), gamePort=await freePort();
  const onlineUrl=`ws://127.0.0.1:${controlPort}`;
  const backend=start(process.execPath,['production_server.js'],{cwd:serverDir,env:{...process.env,PORT:String(controlPort),HOST:'127.0.0.1',HUKUM_GAME_SERVER_URL:`ws://127.0.0.1:${gamePort}`,PARDEX_GAME_SERVER_TOKEN:serverToken,PARDEX_SOCIAL_DATA_PATH:path.join(tmp,'social.json')}});
  await until(()=>backend.log.includes('PARDEX Online listening'));
  const sessions=[];
  for(let role=1;role<=3;role++){
    const ws=await connect(onlineUrl);
    const welcomePromise=next(ws,m=>m.type==='welcome');
    ws.send(JSON.stringify({type:'hello',protocol:5,display_name:`OfficialTest${role}`,identity_key:crypto.randomBytes(32).toString('hex')}));
    await welcomePromise;
    ws.on('message',raw=>{const m=JSON.parse(raw.toString());if(m.type==='game_ended' && m.result?.reason==='victory')officialResult=m.result;});
    const tokenPromise=next(ws,m=>m.type==='game_session');
    ws.send(JSON.stringify({type:'get_game_session',game_id:'hukum'}));
    sessions.push((await tokenPromise).token);
  }
  const authority=start(binary,['--headless','--path',root,'--script','tests/official_network.gd','--','0','--pardex-dedicated',`--pardex-port=${gamePort}`,`--pardex-online-server=${onlineUrl}`],{env:{...process.env,PARDEX_GAME_SERVER_TOKEN:serverToken}});
  gameLogs.push(authority);
  await until(()=>authority.log.includes('HUKUM_SERVER_READY'));
  let code='';
  for(let role=1;role<=3;role++){
    const file=path.join(tmp,`session${role}.json`);
    fs.writeFileSync(file,JSON.stringify({session_token:sessions[role-1],online_url:onlineUrl,code}),{mode:0o600});
    const client=start(binary,['--headless','--path',root,'--script','tests/official_network.gd','--',String(role)],{env:{...process.env,HUKUM_TEST_SESSION:file}});
    gameLogs.push(client);
    if(role===1){await until(()=>/HUKUM_TEST_ROOM=([A-Z0-9]{5})/.test(client.log));code=client.log.match(/HUKUM_TEST_ROOM=([A-Z0-9]{5})/)[1];}
    await wait(200);
  }
  let deadline;
  let exits;
  try {
    exits=await Promise.race([Promise.all(gameLogs.map(p=>p.completed)),new Promise((_,reject)=>{deadline=setTimeout(()=>reject(Error('Official integration timeout')),100000);})]);
  } finally {clearTimeout(deadline);}
  for(let i=0;i<gameLogs.length;i++){
    const log=gameLogs[i].log;
    assert.strictEqual(exits[i],0,`Godot process ${i} failed: ${log}`);
    assert(!log.includes('ERROR:'),`Godot process ${i} engine error: ${log}`);
    assert(log.includes('PASS'),`Godot process ${i} did not finish assertions: ${log}`);
  }
  assert(gameLogs[0].log.includes('HUKUM_REJOIN_OK'),'Dropped official client did not return to the match');
  assert(officialResult,'PARDEX did not acknowledge authoritative victory');
  assert.strictEqual(officialResult.players.length,3);
  assert(officialResult.winner_user_id);
  assert(officialResult.players.every(player=>player.user_id),'Disconnected players keep their verified result identity');
  console.log('HUKUM PARDEX ONLINE: PASS (launcher session, host/code join, two-phase admission, owner authority, three-player battle, mid-match rejoin, result and recycling)');
}
main().catch(error=>{
  console.error(error.message);
  for(let i=0;i<gameLogs.length;i++)console.error(`Godot ${i}:\n${gameLogs[i].log}`);
  process.exitCode=1;
}).finally(()=>{
  for(const ws of sockets)ws.terminate();
  for(const p of processes)if(p.exitCode===null)p.kill();
  fs.rmSync(tmp,{recursive:true,force:true});
});
