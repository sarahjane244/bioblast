// Local network proof of concept. Use a real hosted database and managed identity
// before any production deployment involving student personal information.
'use strict';
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const PORT = Number(process.env.PORT || 8080);
const EMAIL = (process.env.TEACHER_EMAIL || '').toLowerCase();
const PASSWORD = process.env.TEACHER_PASSWORD || '';
const JOIN_CODE = process.env.CLASS_JOIN_CODE || '';
const KEY = process.env.TOKEN_SECRET || '';
const ORIGIN = process.env.CORS_ORIGIN || ''; // http://localhost:port during Edge testing
const DB = path.join(__dirname, 'student_records.json');
if (!EMAIL || PASSWORD.length < 12 || JOIN_CODE.length < 12 || KEY.length < 32) {
  console.error('Set TEACHER_EMAIL, TEACHER_PASSWORD (12+), CLASS_JOIN_CODE (12+), TOKEN_SECRET (32+).');
  process.exit(1);
}
let records = {};
if (fs.existsSync(DB)) { try { records = JSON.parse(fs.readFileSync(DB, 'utf8')); } catch { console.error('Invalid data file.'); process.exit(1); } }
function persist() { const t = `${DB}.tmp`; fs.writeFileSync(t, JSON.stringify(records,null,2),{mode:0o600}); fs.renameSync(t,DB); }
function sign(data) {
  const b=Buffer.from(JSON.stringify({...data, exp:Date.now()+7*86400000})).toString('base64url');
  return b+'.'+crypto.createHmac('sha256',KEY).update(b).digest('base64url');
}
function verify(token,role) {
  if(!token || !token.includes('.')) return null;
  const [b,s]=token.split('.');
  const expected=crypto.createHmac('sha256',KEY).update(b).digest('base64url');
  const a=Buffer.from(s||''); const e=Buffer.from(expected);
  if(a.length!==e.length || !crypto.timingSafeEqual(a,e)) return null;
  try { const data=JSON.parse(Buffer.from(b,'base64url').toString()); return data.role===role && data.exp>Date.now()?data:null; } catch { return null; }
}
const attempts = new Map();
function rateLimited(ip) {const t=Date.now(); const old=attempts.get(ip)||[]; const curr=old.filter(v=>v>t-60000);curr.push(t);attempts.set(ip,curr);return curr.length>30;}
function json(res,status,body,origin) {
  const h={'content-type':'application/json; charset=utf-8','cache-control':'no-store'};
  if(origin && (origin===ORIGIN || (ORIGIN==='local' && /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)))) { h['access-control-allow-origin']=origin;h['vary']='Origin'; }
  res.writeHead(status,h); res.end(JSON.stringify(body));
}
function safeText(v,max=100){return typeof v==='string'?v.trim().slice(0,max):'';}
http.createServer(async (req,res)=>{
  const origin=req.headers.origin || '';
  if (req.method==='OPTIONS') {
    if(origin && (origin===ORIGIN || (ORIGIN==='local' && /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)))) {
      res.writeHead(204,{'access-control-allow-origin':origin,'access-control-allow-methods':'GET,POST,OPTIONS','access-control-allow-headers':'authorization,content-type','access-control-max-age':'600'});
    } else res.writeHead(403);
    return res.end();
  }
  if(rateLimited(req.socket.remoteAddress||'unknown'))return json(res,429,{error:'Too many requests'},origin);
  let body={};
  if(req.method==='POST') {
    try {
      let data='';
      for await (const chunk of req) {data+=chunk; if(data.length>100000)throw new Error('Too large');}
      body=JSON.parse(data||'{}');
    } catch {return json(res,400,{error:'Invalid request body'},origin);}
  }
  if(req.url==='/api/health'&&req.method==='GET')return json(res,200,{ok:true},origin);
  if(req.url==='/api/teacher/login' && req.method==='POST') {
    const e=safeText(body.email).toLowerCase();const p=typeof body.password==='string'?body.password:'';
    // Use scrypt and timing-safe comparison for credentials from env.
    const digest=(v)=>crypto.scryptSync(v,KEY,32);
    const ok=e===EMAIL && crypto.timingSafeEqual(digest(p),digest(PASSWORD));
    return json(res,ok?200:401,ok?{token:sign({role:'teacher'})}:{error:'Invalid credentials'},origin);
  }
  if(req.url==='/api/students/enroll' && req.method==='POST') {
    const name=safeText(body.name); const id=safeText(body.studentId,90);
    if(body.code!==JOIN_CODE || !id.startsWith('local_') || name.length<3) return json(res,403,{error:'Invalid class code or student information'},origin);
    // Never overwrite a name already tied to an existing local profile without matching same name.
    if(records[id] && records[id].name!==name) return json(res,409,{error:'Student profile conflict'},origin);
    records[id] ??={name, lessons:[], changedAt:null, receivedAt:null};persist();
    return json(res,200,{token:sign({role:'student',id})},origin);
  }
  const bearer=(req.headers.authorization||'').replace(/^Bearer /,'');
  if(req.url==='/api/students/sync'&&req.method==='POST') {
    const auth=verify(bearer,'student');
    if(!auth || !records[auth.id])return json(res,401,{error:'Student is not authorized'},origin);
    const lessons=body.lessons;
    if(!Array.isArray(lessons)||lessons.length>8||lessons.some(l=>!Number.isInteger(l.number)||l.number<1||l.number>8))return json(res,400,{error:'Invalid lessons'},origin);
    const changedAt=safeText(body.changedAt,50);
    // Stable client timestamp: older retries should not overwrite a more recent snapshot.
    const old=records[auth.id];
    if(!old.changedAt || changedAt>=old.changedAt) {
      old.lessons=lessons.map(l=>({number:l.number, steps:Object.fromEntries(['learn','explore','sim','play'].map(k=>[k,l.steps?.[k]===true])),
        scoreCorrect:Number.isInteger(l.scoreCorrect)?Math.max(0,l.scoreCorrect):null,
        scoreTotal:Number.isInteger(l.scoreTotal)?Math.max(0,l.scoreTotal):null}));
      old.changedAt=changedAt;
      old.receivedAt=new Date().toISOString();persist();
    }
    return json(res,200,{ok:true},origin);
  }
  if(req.url==='/api/teacher/students'&&req.method==='GET') {
    if(!verify(bearer,'teacher'))return json(res,401,{error:'Teacher is not authorized'},origin);
    const students=Object.entries(records).map(([id,r])=>({id,name:r.name,lessons:r.lessons,changedAt:r.changedAt,receivedAt:r.receivedAt}));
    return json(res,200,{students},origin);
  }
  return json(res,404,{error:'Not found'},origin);
}).listen(PORT,'0.0.0.0',()=>console.log(`BioBlast demo API listening on port ${PORT}`));
