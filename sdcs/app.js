const NS='http://www.w3.org/2000/svg';
const stages=[
 {short:'认识故事',badge:'先认识一下',date:'1935年1月—3月',emoji:'⭐',title:'为什么要四次过河？',story:'前面有拦路的军队，后面有追赶的军队。红军没有硬碰硬，而是一边走、一边观察，哪里有空隙就往哪里走。',lesson:'像走迷宫一样，遇到死路就换方向。灵活思考，也是一种勇敢！',word:'灵活',explain:'根据情况及时改变办法。',button:'开始第一渡',progress:0},
 {short:'第一渡',badge:'第一关 · 向西走',date:'1月29日',emoji:'⛰️',title:'先离开危险的地方',story:'土城战斗后，红军发现继续打下去不合适，于是从土城、元厚一带渡过赤水河，向西进入川南。',lesson:'暂时离开，不是害怕，而是为了保护大家，寻找更合适的机会。',word:'转移',explain:'从一个地方有计划地走到另一个地方。',button:'看看第二渡',progress:.25},
 {short:'第二渡',badge:'第二关 · 向东回',date:'2月18日—21日',emoji:'↩️',title:'突然回头，出其不意',story:'追赶的军队被引到了西边。红军马上改变方向，从太平渡、二郎滩一带向东过河，回到黔北，还打了娄山关和遵义战斗。',lesson:'别人以为你会往前时，换一个方向，就可能找到新的出口。',word:'出其不意',explain:'做出别人没有想到的行动。',button:'看看第三渡',progress:.5},
 {short:'第三渡',badge:'第三关 · 再向西',date:'3月16日—17日',emoji:'🎭',title:'做一个巧妙的“假动作”',story:'红军从茅台附近再次向西过河，让追赶的军队以为红军还要继续向西、向北走，于是也跟着移动。',lesson:'这次过河像球场上的“假动作”，目的是让对方判断错方向。',word:'调动',explain:'用行动让对方跟着改变位置。',button:'看看第四渡',progress:.75},
 {short:'第四渡',badge:'第四关 · 向东突围',date:'3月21日—22日',emoji:'🌈',title:'抓住空隙，走出包围',story:'当追赶的军队集中到西边时，红军迅速从二郎滩、太平渡一带向东过河，接着南渡乌江，终于争取到了主动。',lesson:'认真观察、快速决定、一起行动，困难的迷宫也能找到出口。',word:'主动',explain:'自己抓住机会，决定下一步怎么做。',button:'完成啦，去答题',progress:1}
];
const route=[[525,120],[470,145],[395,160],[315,170],[267,195],[220,220],[185,250],[230,270],[285,285],[365,270],[440,250],[495,230],[445,290],[365,315],[290,306],[258,330],[215,355],[260,382],[325,400],[405,420],[505,405],[595,380]];
const crossings=[{i:5,n:1,label:'一渡'},{i:10,n:2,label:'二渡'},{i:15,n:3,label:'三渡'},{i:18,n:4,label:'四渡'}];
const places=[['遵义',535,112],['土城',302,170],['元厚',220,220],['茅台',258,330],['太平渡',325,400],['贵阳',620,340]];
const $=s=>document.querySelector(s);
const makeSvg=(tag,attrs={})=>{const el=document.createElementNS(NS,tag);Object.entries(attrs).forEach(([k,v])=>el.setAttribute(k,v));return el};
const linePath=pts=>pts.map((p,i)=>(i?'L':'M')+p.join(' ')).join(' ');
function buildMap(){
 const hills=$('.hills');
 [[60,135],[430,80],[555,255],[80,340],[455,435]].forEach(([x,y],i)=>{const g=makeSvg('g',{transform:`translate(${x} ${y})`,class:'hill'});g.append(makeSvg('path',{d:'M0 40 Q28 -5 58 40 Q85 5 116 40Z'}));const t=makeSvg('text',{x:55,y:56});t.textContent=['大山','山路','贵州','云南','乌江'][i];g.append(t);hills.append(g)});
 const base=makeSvg('path',{d:linePath(route),class:'route-base'}),path=makeSvg('path',{d:linePath(route),class:'route-path','marker-end':'url(#arrow)'});$('#routeLayer').append(base,path);window.routePath=path;
 places.forEach(([name,x,y])=>{const g=makeSvg('g',{class:'place'});g.append(makeSvg('circle',{cx:x,cy:y,r:5}));const t=makeSvg('text',{x:x+10,y:y-8});t.textContent=name;g.append(t);$('#placeLayer').append(g)});
 crossings.forEach(({i,n,label})=>{const [x,y]=route[i],g=makeSvg('g',{class:'crossing','data-stage':n,transform:`translate(${x} ${y})`,role:'button',tabindex:'0','aria-label':label});g.innerHTML=`<circle class="cross-halo" r="22"/><circle class="cross-dot" r="16"/><text class="cross-number" text-anchor="middle" y="6">${n}</text><text class="cross-label" x="24" y="5">${label}</text>`;g.addEventListener('click',()=>selectStage(n));g.addEventListener('keydown',e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();selectStage(n)}});$('#crossLayer').append(g)});
 const star=makeSvg('g',{id:'mapStar',transform:`translate(${route[0]})`});star.innerHTML='<circle r="17"/><text text-anchor="middle" y="7">★</text>';$('#starLayer').append(star);
 requestAnimationFrame(()=>{window.pathLength=path.getTotalLength();selectStage(0,false)});
}
function buildNav(){stages.forEach((s,i)=>{const b=document.createElement('button');b.type='button';b.innerHTML=`<span>${i===0?'★':i}</span><b>${s.short}</b>`;b.addEventListener('click',()=>selectStage(i));$('#chapterNav').append(b)})}
function selectStage(index,scroll=true){
 const s=stages[index];window.currentStage=index;
 $('#stageBadge').textContent=s.badge;$('#stageDate').textContent=s.date;$('#stageEmoji').textContent=s.emoji;$('#stageTitle').textContent=s.title;$('#stageStory').textContent=s.story;$('#stageLesson').textContent=s.lesson;$('#stageWord').textContent=s.word;$('#stageWordExplain').textContent=s.explain;$('#nextBtn').innerHTML=`${s.button} <span>→</span>`;
 document.querySelectorAll('#chapterNav button').forEach((b,i)=>{b.classList.toggle('active',i===index);b.classList.toggle('done',i<index)});document.querySelectorAll('.crossing').forEach(g=>g.classList.toggle('active',Number(g.dataset.stage)===index));
 if(window.pathLength){const shown=window.pathLength*s.progress;window.routePath.style.strokeDasharray=window.pathLength;window.routePath.style.strokeDashoffset=window.pathLength-shown;const pt=window.routePath.getPointAtLength(shown);$('#mapStar').setAttribute('transform',`translate(${pt.x} ${pt.y})`)}
 if(scroll&&matchMedia('(max-width: 800px)').matches)$('.story-card').scrollIntoView({behavior:'smooth',block:'start'});
}
$('#nextBtn').addEventListener('click',()=>{if(window.currentStage<4)selectStage(window.currentStage+1);else $('#quiz').scrollIntoView({behavior:'smooth'})});
$('#startBtn').addEventListener('click',()=>$('#storyZone').scrollIntoView({behavior:'smooth'}));
document.querySelectorAll('.answers button').forEach(btn=>btn.addEventListener('click',()=>{document.querySelectorAll('.answers button').forEach(b=>b.classList.remove('right','wrong'));const right=btn.dataset.correct==='true';btn.classList.add(right?'right':'wrong');$('#quizResult').textContent=right?'🎉 答对啦！会观察、会思考、会改变办法，就是四渡赤水故事里的智慧。':'再想一想：遇到变化时，是不是应该先观察，再想新办法呢？'}));
const dialog=$('#aboutDialog');$('#aboutBtn').addEventListener('click',()=>dialog.showModal());$('.dialog-close').addEventListener('click',()=>dialog.close());dialog.addEventListener('click',e=>{if(e.target===dialog)dialog.close()});$('#backTop').addEventListener('click',()=>scrollTo({top:0,behavior:'smooth'}));
buildNav();buildMap();
