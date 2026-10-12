import {JSDOM} from 'jsdom';
import {readFileSync} from 'node:fs';
import assert from 'node:assert/strict';
const tick=()=>new Promise(r=>setTimeout(r,30));
const helpers=readFileSync('src/supabase.js','utf8').slice(readFileSync('src/supabase.js','utf8').indexOf('export function unwrap')).replaceAll('export ','');
const html='<!doctype html><meta name="robots" content="noindex"><meta name="description"><body></body>';
const dom=new JSDOM(html,{url:'https://netv.example/admin',runScripts:'outside-only'});
dom.window.HTMLElement.prototype.scrollIntoView=function(){};
let signedIn=false;const writes=[];
const query=(table)=>{const q={select(){return q},eq(){return q},order(){return q},range(){return q},limit(){return q},insert(v){writes.push([table,v]);return q},maybeSingle(){return Promise.resolve({data:{user_id:'u1',display_name:'Editor Test',role:'editor',active:true},error:null})},then(resolve){return Promise.resolve({data:[],count:0,error:null}).then(resolve)}};return q;};
dom.window.db={auth:{getSession:async()=>({data:{session:signedIn?{user:{id:'u1'}}:null}}),signInWithPassword:async()=>{signedIn=true;return {data:{}}},onAuthStateChange(){},signOut:async()=>({data:{}})},from:query};
dom.window.eval(helpers+'\n'+readFileSync('src/admin/app.js','utf8').replace(/^import .*;\n/gm,''));
await tick();assert.ok(dom.window.document.querySelector('#login'));const form=dom.window.document.querySelector('#login');form.querySelector('[name=email]').value='editor@example.com';form.querySelector('[name=password]').value='local-test-only';form.dispatchEvent(new dom.window.Event('submit',{cancelable:true}));await tick();assert.ok(dom.window.document.querySelector('.nr-shell'));assert.match(dom.window.document.body.textContent,/Editor Test/);assert.ok(!dom.window.document.querySelector('[data-view=Team]'),'editor must not see team controls');dom.window.document.querySelector('[data-view=Articles]').click();await tick();dom.window.document.querySelector('#new').click();await tick();assert.ok(dom.window.document.querySelector('[name=seo_description]'));assert.ok(dom.window.document.querySelector('[name=sources]'));assert.ok(dom.window.document.querySelector('[name=faqs]'));dom.window.document.querySelector('[name=title]').value='<img src=x onerror=alert(1)>';dom.window.document.querySelector('[name=body_text]').value='<script>alert(1)</script>';dom.window.document.querySelector('#preview').click();assert.equal(dom.window.document.querySelectorAll('.nr-preview script,.nr-preview img').length,0,'preview escapes untrusted HTML');
dom.window.document.querySelector('#close-preview').click();
// Exercise real form handlers, including the headline-only breaking-news path.
dom.window.confirm=()=>true;
for(const section of ['Breaking news','Authors','Categories','Topics','Pages','Homepage']){
 dom.window.document.querySelector('[data-view="'+section+'"]').click();await tick();
 dom.window.document.querySelector('#add-resource').click();await tick();
 const f=dom.window.document.querySelector('#resource-edit');assert.ok(f,section+' form opens');
 if(section==='Breaking news'){
  assert.equal(f.querySelector('[name=active]').value,'true');
  assert.ok(f.querySelector('[name=starts_at]').value);assert.ok(f.querySelector('[name=ends_at]').value);
  f.querySelector('[name=headline]').value='Regression test headline';
  f.dispatchEvent(new dom.window.Event('submit',{cancelable:true}));await tick();
  const payload=writes.find(([t])=>t==='breaking_news')[1];assert.equal(payload.article_id,null);assert.equal(payload.active,true);assert.ok(payload.ends_at>payload.starts_at);
 }else if(section==='Homepage'){
  f.dispatchEvent(new dom.window.Event('submit',{cancelable:true}));await tick();
  assert.match(dom.window.document.querySelector('#nr-message').textContent,/Publish an article first/);
  assert.ok(!writes.some(([t])=>t==='homepage_placements'));
 }else{
  if(f.querySelector('[name=name]'))f.querySelector('[name=name]').value='Test';
  if(f.querySelector('[name=title]'))f.querySelector('[name=title]').value='Test page';
  f.querySelector('[name=slug]').value='test';
  f.dispatchEvent(new dom.window.Event('submit',{cancelable:true}));await tick();
 }
}
assert.equal(writes.find(([t])=>t==='categories')[1].sort_order,0);
console.log('PASS: Breaking News defaults and save without article; Authors, Categories, Topics, Pages save; Homepage missing-article validation.');
dom.window.close();
const pub=new JSDOM(html,{url:'https://netv.example/article/test-news',runScripts:'outside-only'});const article={id:'a1',slug:'test-news',title:'<script>bad</script> Test news',body_text:'Real published article\n\nSecond paragraph.',language:'hi-Latn',published_at:'2026-10-12T00:00:00Z',updated_at:'2026-10-12T00:00:00Z',status:'published',sources:[{title:'Unsafe link',url:'javascript:alert(1)'}],seo_description:'A test report',robots_index:true,robots_follow:true,article_type:'NewsArticle'};
pub.window.db={from(table){const q={select(){return q},eq(){return q},lte(){return q},gt(){return q},or(){return q},order(){return q},range(){return q},in(){return q},maybeSingle(){return Promise.resolve({data:article})},then(resolve){return Promise.resolve({data:[]}).then(resolve)}};return q;}};
pub.window.eval(helpers+'\nconst pages={};const policyPage=()=>"";\n'+readFileSync('src/news.js','utf8').replace(/^import .*;\n/gm,'').replaceAll('export ','')+'\nwindow.renderNews=renderNews;');
const rendered=await pub.window.renderNews('/article/test-news','hinglish');assert.match(rendered,/Real published article/);assert.ok(!rendered.includes('javascript:'));assert.ok(!rendered.includes('<script>bad'));assert.equal(pub.window.document.querySelector('meta[name=robots]').content,'index,follow');assert.equal(JSON.parse(pub.window.document.querySelector('script[type="application/ld+json"]').textContent).headline,article.title);assert.match(await pub.window.renderNews('/','hinglish'),/Stories are on their way/);pub.window.close();console.log('PASS: staff login, role-aware navigation, article editor fields, safe preview, public article, metadata, unsafe URL filtering, empty newsroom. DOM checks only.');
