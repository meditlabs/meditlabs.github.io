const NS='http://www.w3.org/2000/svg';
const stages=[
 {name:'总览',date:'1935年1月19日 — 3月22日',title:'总览：在折返中寻找主动',story:'遵义会议后，中央红军在川黔滇边反复机动。四次横渡赤水河，调动、迷惑并摆脱围堵，最终跳出重围。',quote:'“打得赢就打，打不赢就走。”',insight:'路线看似反复，实则始终围绕敌军部署的空隙改变方向。',days:'63',cross:'4',move:'∞',range:[0,23]},
 {name:'一渡',date:'1935年1月29日',title:'一渡赤水：避实击虚，向川南转进',story:'土城战斗后，红军从猿猴场（今元厚）等渡口西渡赤水，进入川南。主动转向，使紧逼的川军失去预定决战目标。',quote:'先跳出压迫最紧的战场。',insight:'不是执着于一城一地，而是保存力量、寻找新的机动空间。',days:'11',cross:'1',move:'西',range:[0,6]},
 {name:'二渡',date:'1935年2月18日—21日',title:'二渡赤水：回师黔北，重占遵义',story:'敌军被吸引向川滇边后，红军突然东渡赤水，杀回黔北，取得娄山关、遵义战斗的胜利。',quote:'出其不意，攻其不备。',insight:'利用敌军调动形成的空隙突然折返，将战略机动转化为战场主动。',days:'4',cross:'2',move:'东',range:[6,13]},
 {name:'三渡',date:'1935年3月16日',title:'三渡赤水：再向西去，佯动调敌',story:'红军由茅台附近西渡赤水，摆出再次北渡长江的姿态，诱使敌军主力向西追堵。',quote:'以行动制造判断，以判断牵动部署。',insight:'这次西渡更像一记“虚招”，重点在于调动对手而非占领地域。',days:'1',cross:'3',move:'西',range:[13,18]},
 {name:'四渡',date:'1935年3月21日—22日',title:'四渡赤水：折返东岸，跳出合围',story:'红军从二郎滩、太平渡一带再次东渡，随后南渡乌江、佯攻贵阳，最终向云南方向机动。',quote:'当对手追向西面，真正的方向已在东面。',insight:'快速回穿敌军部署间隙，以连续转向彻底夺回战略主动。',days:'2',cross:'4',move:'东',range:[18,23]}
];
const route=[[645,205],[570,220],[490,238],[405,255],[350,270],[300,286],[247,300],[285,332],[335,352],[405,370],[485,390],[558,405],[615,430],[540,455],[462,468],[380,454],[330,435],[280,420],[315,462],[365,500],[430,522],[520,540],[610,565],[690,590]];
const places=[['遵义',650,205,'capital'],['土城',355,268,''],['元厚',300,300,''],['扎西',210,330,''],['娄山关',640,145,''],['茅台',330,435,''],['太平渡',315,462,''],['二郎滩',350,493,''],['贵阳',760,430,'capital'],['昆明',230,625,'capital']];
const crosses=[{i:5,label:'一渡',stage:1},{i:9,label:'二渡',stage:2},{i:16,label:'三渡',stage:3},{i:19,label:'四渡',stage:4}];
const enemies=[['川军','M150 90 Q260 120 360 205'],['中央军','M900 170 Q790 210 685 250'],['黔军','M860 490 Q760 455 665 420'],['滇军','M120 650 Q205 575 270 520']];
const $=s=>document.querySelector(s), svg=(tag,a={})=>{const e=document.createElementNS(NS,tag);Object.entries(a).forEach(([k,v])=>e.setAttribute(k,v));return e};
const routeLayer=$('#routeLayer'), placeLayer=$('#placeLayer'), crossingLayer=$('#crossingLayer'), enemyLayer=$('#enemyLayer'), cursorLayer=$('#cursorLayer');
function linePath(points){return points.map((p,i)=>(i?'L':'M')+p.join(' ')).join(' ')}
function buildTerrain(){const g=$('.terrain');for(let y=55;y<680;y+=68){const p=svg('path',{d:`M20 ${y} Q110 ${y-35} 200 ${y} T380 ${y} T560 ${y} T740 ${y} T960 ${y}`});g.append(p)}}
function buildMap(){
 buildTerrain();
 enemies.forEach(([label,d],i)=>{const p=svg('path',{d,class:'enemy-path'});p.style.animationDelay=`-${i*.3}s`;enemyLayer.append(p);const m=d.match(/(\d+) (\d+)$/);const t=svg('text',{x:+m[1]+8,y:+m[2]-8,class:'enemy-label'});t.textContent=label;enemyLayer.append(t)});
 const future=svg('path',{d:linePath(route),class:'route future'});routeLayer.append(future);
 const base=svg('path',{d:linePath(route),class:'route-base'}),path=svg('path',{d:linePath(route),class:'route'});routeLayer.append(base,path);window.routePath=path;
 places.forEach(([n,x,y,c])=>{const g=svg('g',{class:`place ${c}`});g.append(svg('circle',{cx:x,cy:y,r:c?6:4}));const t=svg('text',{x:x+9,y:y-8});t.textContent=n;g.append(t);placeLayer.append(g)});
 crosses.forEach(c=>{const [x,y]=route[c.i],g=svg('g',{class:'crossing','data-stage':c.stage,transform:`translate(${x} ${y})`});g.append(svg('circle',{class:'pulse',r:9}),svg('circle',{class:'core',r:7}));const t=svg('text',{x:12,y:-12});t.textContent=c.label;g.append(t);g.addEventListener('click',()=>selectStage(c.stage,true));crossingLayer.append(g)});
 const g=svg('g',{id:'cursor',transform:`translate(${route[0]})`});g.append(svg('circle',{class:'cursor-ring',r:10}),svg('path',{class:'cursor-star',d:'M0-7 2-2 7 0 2 2 0 7-2 2-7 0-2-2Z'}));cursorLayer.append(g);
 requestAnimationFrame(()=>{pathLength=path.getTotalLength();path.style.strokeDasharray=pathLength;path.style.strokeDashoffset=0});
}
let current=0,playing=false,progress=1,pathLength=1,raf,last,speed=1,view={x:0,y:0,w:1000,h:690};
function buildTimeline(){stages.forEach((s,i)=>{const b=document.createElement('button');b.className='stage-btn'+(i===0?' active':'');b.textContent=s.name;b.onclick=()=>selectStage(i,true);$('#timeline').append(b)})}
function selectStage(i,play=false){current=i;const s=stages[i];['Title','Date','Story','Quote','Insight'].forEach(k=>$('#stage'+k).textContent=s[k.toLowerCase()]);$('#statDays').textContent=s.days;$('#statCross').textContent=s.cross;$('#statMove').textContent=s.move;document.querySelectorAll('.stage-btn').forEach((b,j)=>b.className='stage-btn'+(j===i?' active':j<i?' done':''));document.querySelectorAll('.crossing').forEach(g=>g.classList.toggle('active',+g.dataset.stage===i));progress=i===0?1:0;drawProgress();playing=false;updatePlay();if(play)startPlayback()}
function drawProgress(){const stage=stages[current],start=stage.range[0]/(route.length-1),end=stage.range[1]/(route.length-1),p=current===0?progress:start+(end-start)*progress;window.routePath.style.strokeDashoffset=pathLength*(1-p);const pt=window.routePath.getPointAtLength(pathLength*p);$('#cursor').setAttribute('transform',`translate(${pt.x} ${pt.y})`)}
function startPlayback(){if(progress>=.999)progress=0;playing=true;last=performance.now();updatePlay();raf=requestAnimationFrame(tick)}
function tick(t){if(!playing)return;const dt=Math.min(50,t-last);last=t;progress+=dt*.000075*speed;if(progress>=1){progress=1;playing=false}drawProgress();updatePlay();if(playing)raf=requestAnimationFrame(tick)}
function updatePlay(){$('#playBtn').textContent=playing?'Ⅱ':'▶';$('#playLabel').textContent=playing?'推演进行中':progress>=1?'重新播放':'继续播放';$('#playHint').textContent=stages[current].title}
$('#playBtn').onclick=()=>{if(playing){playing=false;cancelAnimationFrame(raf);updatePlay()}else startPlayback()};
$('#enemyToggle').onchange=e=>enemyLayer.style.display=e.target.checked?'':'none';$('#placeToggle').onchange=e=>placeLayer.style.display=e.target.checked?'':'none';
$('#speedBtn').onclick=e=>{speed=speed===1?1.5:speed===1.5?2:1;e.target.textContent=speed+'×'};
function setView(){ $('#map').setAttribute('viewBox',`${view.x} ${view.y} ${view.w} ${view.h}`)}
document.querySelectorAll('[data-zoom]').forEach(b=>b.onclick=()=>{const z=b.dataset.zoom;if(z==='reset')view={x:0,y:0,w:1000,h:690};else{const f=z==='in'?.82:1.22,cx=view.x+view.w/2,cy=view.y+view.h/2;view.w=Math.max(360,Math.min(1300,view.w*f));view.h=view.w*.69;view.x=cx-view.w/2;view.y=cy-view.h/2}setView()});
const map=$('#map');map.addEventListener('wheel',e=>{e.preventDefault();document.querySelector(`[data-zoom="${e.deltaY<0?'in':'out'}"]`).click()},{passive:false});let drag=null;map.addEventListener('pointerdown',e=>{drag={x:e.clientX,y:e.clientY,vx:view.x,vy:view.y};map.setPointerCapture(e.pointerId)});map.addEventListener('pointermove',e=>{if(!drag)return;view.x=drag.vx-(e.clientX-drag.x)*view.w/map.clientWidth;view.y=drag.vy-(e.clientY-drag.y)*view.h/map.clientHeight;setView()});map.addEventListener('pointerup',()=>drag=null);
const dlg=$('#aboutDialog');$('#aboutBtn').onclick=()=>dlg.showModal();$('.dialog-close').onclick=()=>dlg.close();dlg.onclick=e=>{if(e.target===dlg)dlg.close()};
addEventListener('keydown',e=>{if(e.code==='Space'){e.preventDefault();$('#playBtn').click()}if(e.key==='ArrowRight')selectStage(Math.min(4,current+1));if(e.key==='ArrowLeft')selectStage(Math.max(0,current-1))});
buildMap();buildTimeline();selectStage(0);
