import {JSDOM,VirtualConsole} from 'jsdom';
import {readFileSync,existsSync} from 'node:fs';
import assert from 'node:assert/strict';
const errors=[];const vc=new VirtualConsole();vc.on('jsdomError',e=>errors.push(e.message));
let html=readFileSync('dist/index.html','utf8').replace(/<link[^>]+rel="stylesheet"[^>]*>/g,'');
for(const name of ['policies','app'])html=html.replace(`<script src="/${name}.js"></script>`,()=>`<script>${readFileSync(`dist/${name}.js`,'utf8')}</script>`);
const dom=new JSDOM(html,{url:'https://netv.example/',runScripts:'dangerously',pretendToBeVisual:true,virtualConsole:vc,beforeParse(w){w.matchMedia=()=>({matches:false,addEventListener(){}});w.scrollTo=()=>{};w.HTMLElement.prototype.scrollIntoView=function(){};w.HTMLDialogElement.prototype.showModal=function(){this.open=true};w.HTMLDialogElement.prototype.close=function(){this.open=false}}});
const w=dom.window,d=w.document;const tick=()=>new Promise(r=>setTimeout(r,20));
async function route(hash){w.location.hash=hash;await tick();assert.ok(d.querySelector('main').textContent.trim().length>100,hash)}
assert.equal(d.querySelectorAll('.discovery').length,0);assert.equal(d.querySelectorAll('.nav').length,1);assert.equal(d.querySelectorAll('.nav > a, .nav > details').length,8);assert.equal(d.querySelectorAll('.nav details[data-group=magazine] a').length,5);assert.equal(d.querySelectorAll('.social-links svg').length,3);
const links=new Set([...d.querySelectorAll('a[href^="#/"]')].map(a=>a.getAttribute('href')));
for(const hash of links){await route(hash);assert.ok(!d.querySelector('main').textContent.includes('Page nahi mila'),hash);assert.ok(!d.querySelector('main').innerHTML.includes('undefined'),hash)}
for(const key of ['privacy','terms','standards','corrections','cookies','sponsored','team','accessibility']){await route('#/'+key);assert.ok(d.querySelectorAll('.policy-content section').length>=2,key);assert.ok(d.title.includes(d.querySelector('main h1').textContent),key)}
await route('#/privacy');const old=w.location.hash;d.querySelector('[data-section]').click();assert.equal(w.location.hash,old);
await route('#/');d.querySelector('[data-state="Assam"]').click();assert.ok(d.querySelector('#stateStories').textContent.includes('Assam'));assert.ok(!d.querySelector('#stateStories').textContent.includes('Maharashtra'));
d.querySelector('#searchButton').click();assert.ok(d.querySelector('#searchDialog').open);d.querySelector('#query').value='history';d.querySelector('#searchForm').dispatchEvent(new w.Event('submit',{cancelable:true}));assert.ok(d.querySelectorAll('#searchResults a').length>0);d.querySelector('#closeSearch').click();assert.ok(!d.querySelector('#searchDialog').open);
d.querySelector('#language').value='hi';d.querySelector('#language').dispatchEvent(new w.Event('change'));assert.equal(w.localStorage.getItem('netv-language'),'hi');await route('#/cookies');d.querySelector('#resetPreferences').click();assert.equal(w.localStorage.getItem('netv-language'),null);
d.querySelector('#menuButton').click();assert.equal(d.querySelector('#drawer').hidden,false);assert.equal(d.querySelectorAll('#drawerLinks details').length,3);d.querySelector('#closeMenu').click();assert.equal(d.querySelector('#drawer').hidden,true);
await route('#/article/cities');const articleHash=w.location.hash;const articleText=d.querySelector('main').textContent;d.querySelector('.skip').click();await tick();assert.equal(w.location.hash,articleHash);assert.equal(d.activeElement.id,'main');d.querySelector('.footer-back').click();await tick();assert.equal(d.querySelector('main').textContent,articleText);
await route('#/latest');d.querySelector('#menuButton').click();d.querySelector('#drawerLinks a[href="#/latest"]').click();assert.equal(d.querySelector('#drawer').hidden,true);
assert.equal(d.querySelector('meta[name=robots]').content,'noindex,nofollow');
d.querySelector('#menuButton').click();assert.equal(d.querySelector('main').inert,true);d.dispatchEvent(new w.KeyboardEvent('keydown',{key:'Escape'}));assert.equal(d.querySelector('main').inert,false);assert.equal(d.activeElement.id,'menuButton');
for(const file of ['index.html','style.css','app.js','policies.js','editorial.webp','logo.png'])assert.ok(existsSync('dist/'+file));
assert.deepEqual(errors,[]);console.log(`${links.size} linked routes, 8 policy pages, search, state filter, menu, language reset, internal contents links and assets passed. DOM checks only; visual browser verification unavailable.`);dom.window.close();
