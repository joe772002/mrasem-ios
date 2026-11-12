/* Source: https://claude.ai/artifact/Gg4iccc4Y1qqbwAV7d2d52 — reference render functions.
   Part 2 of the reference script: state, helpers, and every guest/team view. */

const S={mode:'inbound',role:'guest',tab:'mission',teamTab:'visit',day:1,filter:'all',
  arrived:{inbound:0,outbound:0},requests:[],notices:[],changed:{},dress:'formal',checks:{},chat:[]};
try{const saved=JSON.parse(localStorage.getItem('mrasem-ui')||'{}');if(saved.tab)S.tab=saved.tab;}catch(e){}

const $=s=>document.querySelector(s);
const esc=s=>String(s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const D=()=>DATA[S.mode];
const AR='٠١٢٣٤٥٦٧٨٩';
const ar=n=>String(n).replace(/\d/g,d=>AR[d]);

function daysUntil(dateStr){
  const t=new Date(dateStr+'T00:00:00');const now=new Date();now.setHours(0,0,0,0);
  return Math.round((t-now)/86400000);
}
function duration(d){return Math.round((new Date(d.end)-new Date(d.start))/86400000)+1;}

function toast(html){
  const t=$('#toast');t.innerHTML=html;t.hidden=false;
  clearTimeout(toast._t);toast._t=setTimeout(()=>{t.hidden=true},3800);
}

function plate(car){
  return `<span class="plate ${car.style==='uk'?'uk':''}" aria-label="رقم اللوحة ${esc(car.plate)}"><span class="c">${car.country}</span><span class="n">${esc(car.plate)}</span></span>`;
}

function mapSvg(v){
  return `<div class="map"><svg viewBox="0 0 400 150" role="img" aria-label="موقع ${esc(v.building)}">
  <rect width="400" height="150" fill="var(--tint)"/>
  <path d="M0 110 Q120 90 200 105 T400 95 V150 H0Z" fill="color-mix(in srgb,#3b82c4 22%,transparent)"/>
  <path d="M30 0 V150 M0 50 H400 M150 0 L210 150 M320 0 V110" stroke="var(--line)" stroke-width="8" fill="none"/>
  <rect x="235" y="22" width="56" height="44" rx="4" fill="var(--surface)" stroke="var(--maroon)" stroke-width="2"/>
  <text x="263" y="49" text-anchor="middle" font-size="11" fill="var(--maroon)" font-family="IBM Plex Sans Arabic">${S.mode==='inbound'?'الوزارة':'المؤتمر'}</text>
  <path d="M262 18c-9 0-15 6-15 14 0 10 15 22 15 22s15-12 15-22c0-8-6-14-15-14Z" fill="var(--maroon)" transform="translate(0,-14)"/>
  <circle cx="262" cy="18" r="5" fill="#fff"/>
  <rect x="60" y="62" width="40" height="30" rx="4" fill="var(--surface)" stroke="var(--gold)" stroke-width="2"/>
  <text x="80" y="81" text-anchor="middle" font-size="10" fill="var(--gold)" font-family="IBM Plex Sans Arabic">الفندق</text>
  <path d="M100 76 C160 70 200 50 236 46" stroke="var(--gold)" stroke-width="2.5" stroke-dasharray="6 5" fill="none"/>
  </svg></div>`;
}

function arrivalSteps(){
  const a=S.arrived[S.mode];
  const r=D().receiver,c=D().car;
  const steps=[['هبوط الطائرة وتأكيد الوصول',0],[`${r.name} بانتظارك – ${r.spot}`,1],[`السائق ${c.driver} في طريقه إلى نقطة الالتقاء`,2],['التوجه إلى الفندق',3]];
  return `<div class="status">${steps.map(([s,i])=>`<div class="step ${a>i?'done':a===i?'now':''}"><span class="dot"></span><span>${esc(s)}</span></div>`).join('')}</div>`;
}

function noticesHtml(){
  const list=S.notices.filter(n=>n.mode===S.mode);
  if(!list.length)return '';
  return list.slice(-2).reverse().map(n=>`<div class="notice"><b>تحديث من فريق المراسم</b><span>${esc(n.text)}</span></div>`).join('');
}

/* ---------- Guest views ---------- */
function viewMission(){
  const d=D(),r=d.receiver,c=d.car,v=d.venue,h=d.hotel;
  const left=daysUntil(d.start);
  const ch=k=>S.changed[S.mode+k]?' <span class="pill warn">محدَّث</span>':'';
  return `
  ${noticesHtml()}
  <section class="hero" aria-label="ملخص المهمة">
    <div class="row"><span class="pill">${esc(d.country)}</span><span class="label grow" style="text-align:left">${esc(d.host)}</span></div>
    <p class="dest">${esc(d.dest)}</p>
    <p class="sub">${esc(d.guest)}</p>
    <div class="stats">
      <div class="stat"><b>${left>0?ar(left):'اليوم'}</b><span>${left>0?'يوماً على الوصول':'موعد الوصول'}</span></div>
      <div class="stat"><b>${ar(duration(d))}</b><span>أيام المهمة</span></div>
      <div class="stat"><b>${ar(d.days.reduce((s,x)=>s+x.items.filter(i=>!i.free).length,0))}</b><span>فقرة رسمية</span></div>
    </div>
    <dl class="kv"><dt>التوقيت</dt><dd>${esc(d.tz)}</dd><dt>العملة</dt><dd>${esc(d.currency)}</dd><dt>الطقس</dt><dd>${esc(d.weather)}</dd></dl>
  </section>

  <section class="card" aria-label="الوصول">
    <h2>حالة الوصول ${S.arrived[S.mode]>=4?'<span class="pill ok">اكتمل</span>':''}</h2>
    ${arrivalSteps()}
    <button class="btn primary block" data-action="arrive" ${S.arrived[S.mode]>=4?'disabled':''}>${S.arrived[S.mode]===0?'وصلت: أبلغ المستقبِل والسائق':S.arrived[S.mode]>=4?'تم الوصول إلى الفندق':'الخطوة التالية'}</button>
  </section>

  <section class="card" aria-label="المستقبِل">
    <h2>من سيستقبلك${ch('receiver')}</h2>
    <div class="row"><div class="avatar">${esc(r.name.trim()[0]||'م')}</div>
      <div class="grow"><div class="strong">${esc(r.name)}</div><div class="label">${esc(r.title)}</div></div></div>
    <dl class="kv"><dt>الهاتف</dt><dd dir="ltr" style="text-align:right">${esc(r.phone)}</dd><dt>نقطة اللقاء</dt><dd>${esc(r.spot)}</dd></dl>
    <div class="btns"><a class="btn" href="tel:${esc(r.phone.replace(/\s/g,''))}">اتصال</a><a class="btn" href="https://wa.me/${esc(r.phone.replace(/\D/g,''))}">واتساب</a></div>
  </section>

  <section class="card" aria-label="السيارة">
    <h2>السيارة الرسمية${ch('car')}</h2>
    <div class="row"><div class="grow"><div class="strong">${esc(c.type)}</div><div class="label">السائق: ${esc(c.driver)}</div></div>${plate(c)}</div>
  </section>

  <section class="card" aria-label="موقع المهمة">
    <h2>موقع الملتقى${ch('venue')}</h2>
    <h3>${esc(v.building)}</h3>
    ${mapSvg(v)}
    <dl class="kv"><dt>المنطقة</dt><dd>${esc(v.area)}</dd><dt>المدخل</dt><dd>${esc(v.entrance)}</dd><dt>الطابق</dt><dd>${esc(v.floor)}</dd><dt>القاعة</dt><dd>${esc(v.hall)}</dd><dt>المواقف</dt><dd>${esc(v.parking)}</dd></dl>
    <a class="btn" href="https://www.google.com/maps/search/?api=1&query=${v.lat},${v.lng}">فتح في الخرائط</a>
  </section>

  <section class="card" aria-label="الإقامة">
    <h2>الإقامة</h2>
    <dl class="kv"><dt>الفندق</dt><dd>${esc(h.name)} – ${esc(h.area)}</dd><dt>الغرفة</dt><dd>${ar(h.room)}</dd><dt>الإفطار</dt><dd>${esc(h.breakfast)}</dd><dt>المسافة</dt><dd>${esc(h.drive)}</dd></dl>
  </section>

  <section class="card" aria-label="بطاقة المرور">
    <h2>بطاقة المرور الرقمية</h2>
    <div class="row">${qr()}<div class="grow"><div class="strong">${esc(d.guest)}</div><div class="label">تُبرز عند مدخل ${esc(v.building)}</div></div></div>
  </section>

  <section class="card" aria-label="الطوارئ">
    <h2>الطوارئ</h2>
    <dl class="kv">${d.emergency.map(([a,b])=>`<dt>${esc(a)}</dt><dd dir="ltr" style="text-align:right">${esc(b)}</dd>`).join('')}</dl>
    <div class="label">منسق المراسم المكلّف: ${esc(d.coordinator.name)}، متاح على مدار الساعة.</div>
  </section>`;
}

function qr(){
  let cells='';let seed=7;
  for(let y=0;y<11;y++)for(let x=0;x<11;x++){
    seed=(seed*31+x*7+y*13)%97;
    const corner=(x<3&&y<3)||(x>7&&y<3)||(x<3&&y>7);
    if(corner? !(x%10===1&&y%10===1) && !((x===1||x===9)&&y===1) : seed%3===0) cells+=`<rect x="${x*6}" y="${y*6}" width="6" height="6"/>`;
  }
  return `<svg viewBox="-3 -3 72 72" width="84" height="84" role="img" aria-label="رمز QR توضيحي" style="background:#fff;border-radius:8px;flex:0 0 auto"><g fill="#111">${cells}</g></svg>`;
}

function viewPlan(){
  const d=D();if(S.day>=d.days.length)S.day=0;
  const day=d.days[S.day];
  return `
  ${noticesHtml()}
  <div class="days" role="group" aria-label="أيام المهمة">${d.days.map((x,i)=>`<button data-day="${i}" aria-pressed="${i===S.day}">${x.label}</button>`).join('')}</div>
  <section class="card"><h2>البرنامج اليومي <span class="label">${esc(d.tz)}</span></h2>
  <div class="tl">${day.items.map((it,idx)=>it.free?`
    <div class="tl-item free"><div class="tl-time">${it.from}</div><div><div class="strong">وقت حر حتى ${it.to}</div>
    <div class="label">${ar(it.hours)} ساعات متاحة. اقتراحات قريبة من موقعك:</div>
    <div class="chips" style="margin-top:6px">${d.places.filter(p=>p.dur+p.min/30<=it.hours).slice(0,3).map(p=>`<button class="chip" data-action="goplace" data-hours="${it.hours}">${esc(p.n)}</button>`).join('')}</div></div></div>`:`
    <div class="tl-item ${S.changed[S.mode+'d'+S.day+'i'+idx]?'changed':''}"><div class="tl-time">${it.t}</div><div>
      <div class="strong">${esc(it.title)} ${S.changed[S.mode+'d'+S.day+'i'+idx]?'<span class="pill warn">تغيّر الموعد</span>':''}</div>
      <div class="label">${esc(it.where)}</div>${it.note?`<div class="label">${esc(it.note)}</div>`:''}
      ${it.key?'<button class="chip" data-action="goprotocol" style="margin-top:6px">بطاقة الـ ٣٠ ثانية قبل اللقاء</button>':''}
    </div></div>`).join('')}</div></section>`;
}

function viewServices(){
  const d=D();
  return `${d.services.map(g=>`<section class="card"><h2>${g.cat}</h2><div class="list">${g.items.map(s=>`
    <div class="svc"><div class="logo" style="background:${s.c}">${esc(s.en.trim()[0])}</div>
    <div class="grow"><div class="strong">${esc(s.n)} <span class="label" dir="ltr">${s.n!==s.en?esc(s.en):''}</span></div><div class="label">${esc(s.d)}</div></div>
    <a class="btn" href="${s.url}">فتح</a></div>`).join('')}</div></section>`).join('')}
  <section class="card"><h2>معلومات سريعة</h2><dl class="kv">${d.quick.map(([a,b])=>`<dt>${esc(a)}</dt><dd>${esc(b)}</dd>`).join('')}</dl>
  <div class="label">التوصيل إلى الفندق: رقم الغرفة ${ar(d.hotel.room)} محفوظ مسبقاً لتسهيل الطلب.</div></section>`;
}

function viewExplore(){
  const d=D();
  const f=S.filter;
  const fit=p=>f==='all'||(f==='1'&&p.dur<=1)||(f==='2'&&p.dur<=2)||(f==='half'&&p.dur<=4)||(f==='day');
  const list=d.places.filter(fit).sort((a,b)=>a.min-b.min);
  return `
  <section class="card"><h2>حول ${esc(d.hotel.name)}</h2>
  <div class="label">مرتبة حسب زمن الوصول بالسيارة من الفندق. اختر الوقت المتاح لديك:</div>
  <div class="chips" role="group" aria-label="الوقت المتاح">${[['all','الكل'],['1','ساعة'],['2','ساعتان'],['half','نصف يوم'],['day','يوم كامل']].map(([k,l])=>`<button class="chip" data-filter="${k}" aria-pressed="${f===k}">${l}</button>`).join('')}</div></section>
  <div class="list">${list.map(p=>{const req=S.requests.find(r=>r.place===p.n&&r.mode===S.mode);return `
    <article class="place"><div class="place-top"><h3>${esc(p.n)}</h3><span class="pill">${esc(p.tag)}</span></div>
    <div class="label">${esc(p.d)}</div>
    <div class="meta"><span>${ar(p.min)} دقيقة بالسيارة</span><span>مدة الزيارة نحو ${ar(p.dur)} ${p.dur>2?'ساعات':'ساعة'}</span><span>مناسب لكبار الضيوف</span></div>
    <button class="btn ${req?'':'primary'}" data-action="request" data-place="${esc(p.n)}" ${req?'disabled':''}>${req?(req.status==='done'?'تم الترتيب':'أُرسل الطلب لمنسق المراسم'):'أرغب في الزيارة'}</button></article>`}).join('')}</div>
  <div class="demo">الأزمنة تقريبية وتتغير حسب الازدحام.</div>`;
}

function viewProtocol(){
  const d=D(),n=d.next;
  const dressSets={
    formal:{t:'بدلة رسمية داكنة',m:['بدلة كحلية أو سوداء أو رمادية، مغلقة','ربطة العنق تنتهي عند مستوى الحزام','البنطال يغطي سطح الحذاء','حذاء جلد أسود أو بني'],w:['فستان رسمي طويل أو بدلة نسائية داكنة','كعب لا يتجاوز ٤ سم ولا يصدر صوتاً','حذاء أسود أو بني أو عنابي','مكياج وإكسسوارات هادئة']},
    bisht:{t:'الزي الوطني مع البشت',m:['الثوب والغترة مع البشت القطري','البشت للمناسبات البروتوكولية الرفيعة','التنسيق مع بقية أعضاء الوفد لضمان الاتساق'],w:['عباءة رسمية محتشمة بلون هادئ','حذاء بكعب منخفض','إكسسوارات محدودة']}
  };
  const ds=dressSets[S.dress];
  const checks=['البطاقات التعريفية','الهدية الرسمية','الملف التعريفي للضيف','الزي المعتمد لليوم','تأكيد موعد السيارة'];
  return `
  <section class="hero"><div class="row"><span class="pill">بطاقة الـ ٣٠ ثانية</span><span class="label grow" style="text-align:left">اللقاء القادم</span></div>
    <h3>${esc(n.who)}</h3>
    <dl class="kv"><dt>صيغة المخاطبة</dt><dd>${esc(n.address)}</dd><dt>الجلوس</dt><dd>${esc(n.seat)}</dd><dt>الهدية</dt><dd>${esc(n.gift)}</dd><dt>اللغة</dt><dd>${esc(n.lang)}</dd></dl></section>

  <section class="card"><h2>زي اليوم <span class="pill ok">معتمد من فريق المراسم</span></h2>
    <div class="dress">${dressSvg()}<div><div class="strong">${ds.t}</div><div class="label">يصل تنبيه لكل أعضاء الوفد عند تغييره.</div></div></div>
    <div class="grid2"><div><div class="label strong">للرجال</div><ul class="tight">${ds.m.map(x=>`<li>${x}</li>`).join('')}</ul></div>
    <div><div class="label strong">للنساء</div><ul class="tight">${ds.w.map(x=>`<li>${x}</li>`).join('')}</ul></div></div></section>

  <section class="card"><h2>قبل الخروج من الفندق</h2>
    ${checks.map((c,i)=>`<label class="check"><input type="checkbox" id="chk${i}" data-check="${i}" ${S.checks[S.mode+i]?'checked':''}> ${c}</label>`).join('')}
    <div class="label">${ar(checks.filter((c,i)=>S.checks[S.mode+i]).length)} من ${ar(checks.length)} جاهزة</div></section>

  <section class="card"><h2>${S.mode==='inbound'?'آداب وأعراف في قطر':'أعراف بلد الوجهة'}</h2><ul class="tight">${d.customs.map(x=>`<li>${esc(x)}</li>`).join('')}</ul></section>

  <section class="card"><h2>الدليل الإرشادي</h2><div class="chips">${['الزيارات الداخلية','الزيارات الخارجية','الجلوس','الإعلام','الضيافة','الزي واللباس','تقديم الهدايا','الصور التذكارية'].map(x=>`<button class="chip" data-action="guide" data-g="${x}">${x}</button>`).join('')}</div></section>`;
}

function dressSvg(){
  if(S.dress==='bisht')return `<svg viewBox="0 0 96 120" aria-hidden="true"><circle cx="48" cy="20" r="11" fill="#d9b99b"/><path d="M33 16 Q48 2 63 16 L66 30 Q48 24 30 30Z" fill="#fff" stroke="#bbb"/><path d="M28 36 L48 32 L68 36 L72 116 H24Z" fill="#f7f7f5" stroke="#ccc"/><path d="M22 38 L40 34 L44 116 H16Z M74 38 L56 34 L52 116 H80Z" fill="#2a1f1a"/><path d="M40 34 L44 116 M56 34 L52 116" stroke="#c9a14a" stroke-width="2.5"/></svg>`;
  return `<svg viewBox="0 0 96 120" aria-hidden="true"><circle cx="48" cy="18" r="11" fill="#d9b99b"/><path d="M26 36 L48 30 L70 36 L74 80 H22Z" fill="#1f2a44"/><path d="M42 31 L48 46 L54 31Z" fill="#fff"/><path d="M46 36 L50 36 L52 66 L48 72 L44 66Z" fill="#8a1538"/><rect x="30" y="80" width="15" height="34" fill="#1f2a44"/><rect x="51" y="80" width="15" height="34" fill="#1f2a44"/><rect x="28" y="112" width="18" height="6" rx="2" fill="#111"/><rect x="50" y="112" width="18" height="6" rx="2" fill="#111"/></svg>`;
}

function viewAssistant(){
  if(!S.chat.length)S.chat.push({me:false,t:`أهلاً بك. أنا مساعد مراسم، أجيب عن أسئلة برنامجك والبروتوكول والخدمات في ${D().dest.split('،')[0]}. ما لا أعرفه أحوّله إلى منسق المراسم.`});
  return `<section class="card"><h2>المساعد <span class="label">نموذج توضيحي</span></h2>
  <div class="chat" id="chat">${S.chat.map(m=>`<div class="msg ${m.me?'me':'bot'}">${esc(m.t)}</div>`).join('')}</div>
  <div class="chips">${['ماذا ألبس اليوم؟','متى موعدي القادم؟','أين السيارة؟','أريد طلب طعام','تاكسي','أماكن قريبة'].map(q=>`<button class="chip" data-q="${q}">${q}</button>`).join('')}</div>
  <form class="ask" id="askform"><input id="askin" placeholder="اكتب سؤالك…" autocomplete="off" aria-label="سؤالك"><button class="btn primary" type="submit">إرسال</button></form></section>`;
}

function answer(q){
  const d=D();
  const nextItem=d.days.flatMap(x=>x.items.filter(i=>!i.free).map(i=>({...i,day:x.label})))[S.mode==='inbound'?4:4]||d.days[0].items[0];
  const rules=[
    [/لبس|ألبس|زي|بشت|بدلة/,()=>`زي اليوم المعتمد: ${S.dress==='bisht'?'الزي الوطني مع البشت':'بدلة رسمية داكنة مغلقة مع ربطة عنق'}. التفاصيل في قسم البروتوكول.`],
    [/موعد|اجتماع|لقاء|برنامج/,()=>`أقرب فقرة رئيسية: ${nextItem.title}، ${nextItem.day} الساعة ${nextItem.t}، في ${nextItem.where}.`],
    [/سيار|سائق/,()=>`سيارتك ${d.car.type}، رقم اللوحة ${d.car.plate}، والسائق ${d.car.driver}.`],
    [/فندق|غرفة/,()=>`إقامتك في ${d.hotel.name} (${d.hotel.area})، الغرفة ${d.hotel.room}. ${d.hotel.drive}.`],
    [/طعام|أكل|توصيل|جوع/,()=>`تطبيقات التوصيل المتاحة: ${d.services[0].items.map(s=>s.n).join('، ')}. رقم غرفتك محفوظ لتسهيل الطلب.`],
    [/تاكسي|أجرة|مواصلات/,()=>`سيارات الأجرة: ${d.services[1].items.map(s=>s.n).join('، ')}. وسيارتك الرسمية متاحة للبرنامج الرسمي.`],
    [/سياح|أماكن|زيارة|قريب/,()=>`الأقرب إلى فندقك: ${d.places.slice().sort((a,b)=>a.min-b.min).slice(0,3).map(p=>p.n).join('، ')}. اطلب الزيارة من قسم استكشف.`],
    [/طوارئ|إسعاف|مستشفى/,()=>`رقم الطوارئ ${d.emergency[0][1]}. ومنسق المراسم ${d.coordinator.name} على ${d.coordinator.phone}.`]
  ];
  for(const [re,f] of rules)if(re.test(q))return f();
  S.requests.push({mode:S.mode,place:null,text:q,status:'new',kind:'سؤال'});
  return 'لم أجد إجابة مؤكدة. أرسلت سؤالك إلى منسق المراسم وسيردّ عليك قريباً.';
}

/* ---------- Team views ---------- */
function viewTeam(){
  const d=D();
  const reqs=S.requests.filter(r=>r.mode===S.mode);
  const tt=S.teamTab;
  const head=`<div class="kpis"><div class="kpi"><b>${S.arrived[S.mode]>=4?'✓':ar(S.arrived[S.mode])+'/٤'}</b><span>مراحل الوصول</span></div>
    <div class="kpi"><b>${ar(reqs.filter(r=>r.status==='new').length)}</b><span>طلبات جديدة</span></div>
    <div class="kpi"><b>${ar(S.notices.filter(n=>n.mode===S.mode).length)}</b><span>تحديثات مرسلة</span></div></div>
    <div class="chips" role="group" aria-label="أقسام اللوحة">${[['visit','بيانات الزيارة'],['changes','التغييرات'],['requests','الطلبات'],['archive','الأرشيف']].map(([k,l])=>`<button class="chip" data-tt="${k}" aria-pressed="${tt===k}">${l}</button>`).join('')}</div>`;
  if(tt==='visit'){
    const r=d.receiver,c=d.car,v=d.venue;
    return head+`<form class="card" id="visitform"><h2>${esc(d.guest)}</h2>
      <div class="label">التعديل هنا يظهر فوراً في تطبيق الضيف مع تنبيه.</div>
      <div class="grid2">
      <div class="field"><label for="f_rn">اسم المستقبِل</label><input id="f_rn" value="${esc(r.name)}"></div>
      <div class="field"><label for="f_rp">هاتف المستقبِل</label><input id="f_rp" dir="ltr" value="${esc(r.phone)}"></div>
      <div class="field"><label for="f_ct">نوع السيارة</label><input id="f_ct" value="${esc(c.type)}"></div>
      <div class="field"><label for="f_cp">رقم اللوحة</label><input id="f_cp" dir="ltr" value="${esc(c.plate)}"></div>
      <div class="field"><label for="f_cd">السائق</label><input id="f_cd" value="${esc(c.driver)}"></div>
      <div class="field"><label for="f_vh">القاعة</label><input id="f_vh" value="${esc(v.hall)}"></div>
      <div class="field"><label for="f_vf">الطابق</label><input id="f_vf" value="${esc(v.floor)}"></div>
      <div class="field"><label for="f_dr">زي اليوم</label><select id="f_dr"><option value="formal" ${S.dress==='formal'?'selected':''}>بدلة رسمية</option><option value="bisht" ${S.dress==='bisht'?'selected':''}>الزي الوطني مع البشت</option></select></div>
      </div>
      <button class="btn primary block" type="submit">حفظ وإشعار الضيف</button></form>`;
  }
  if(tt==='changes'){
    const day=d.days[1];const idx=day.items.findIndex(i=>i.key);const it=day.items[idx];
    return head+`<section class="card"><h2>رادار التغييرات</h2>
      <div class="label">أي تعديل في الموعد يُعاد معه ترتيب الجدول، ويُبلَّغ السائق والفندق والمستقبِل معاً.</div>
      <div class="svc"><div class="grow"><div class="strong">${esc(it.title)}</div><div class="label">${day.label} – ${it.t}</div></div>
      <button class="btn primary" data-action="delay" data-idx="${idx}">تأجيل ٣٠ دقيقة</button></div></section>
      <section class="card"><h2>إرسال تنبيه عام للوفد</h2>
      <form class="ask" id="noticeform"><input id="noticein" placeholder="مثال: تغيير المدخل إلى البوابة (أ)" aria-label="نص التنبيه"><button class="btn primary" type="submit">إرسال</button></form></section>`;
  }
  if(tt==='requests'){
    return head+`<section class="card"><h2>طلبات الضيف</h2>${reqs.length?`<div class="list">${reqs.map((r,i)=>`
      <div class="svc"><div class="grow"><div class="strong">${r.place?'طلب زيارة: '+esc(r.place):esc(r.kind)+': '+esc(r.text)}</div>
      <div class="label">${r.status==='done'?'تم الترتيب':'بانتظار الرد'}</div></div>
      ${r.status==='done'?'<span class="pill ok">منجز</span>':`<button class="btn primary" data-action="resolve" data-i="${S.requests.indexOf(r)}">تم الترتيب</button>`}</div>`).join('')}</div>`:'<div class="empty">لا توجد طلبات بعد. جرّب من عرض الضيف: قسم استكشف ← أرغب في الزيارة، أو اسأل المساعد سؤالاً خارج نطاقه.</div>'}</section>`;
  }
  return head+`<section class="card"><h2>أرشيف الزيارة</h2>
    <dl class="kv"><dt>الضيف</dt><dd>${esc(d.guest)}</dd><dt>الجهة</dt><dd>${esc(d.host)}</dd><dt>الفترة</dt><dd>${d.start} إلى ${d.end}</dd><dt>الفقرات</dt><dd>${ar(d.days.reduce((s,x)=>s+x.items.filter(i=>!i.free).length,0))}</dd><dt>سجل الهدايا</dt><dd>هدية تذكارية مقدّمة (مثال)</dd></dl>
    <div class="label">يُولَّد تقرير الزيارة تلقائياً بعد الوداع (اسم الضيف، الجهة، الموضوع، التوصيات) ويُحفظ مع الصور.</div>
    <button class="btn" data-action="report">إنشاء تقرير الزيارة</button></section>`;
}

/* ---------- Render ---------- */
const GUEST_TABS=[['mission','المهمة'],['plan','البرنامج'],['services','الخدمات'],['explore','استكشف'],['protocol','البروتوكول'],['assistant','المساعد']];
function render(){
  document.querySelectorAll('[data-mode]').forEach(b=>b.setAttribute('aria-pressed',b.dataset.mode===S.mode));
  document.querySelectorAll('[data-role]').forEach(b=>b.setAttribute('aria-pressed',b.dataset.role===S.role));
  const tabs=$('#tabs');
  if(S.role==='team'){
    tabs.style.gridTemplateColumns='repeat(4,1fr)';
    tabs.innerHTML=[['visit','الزيارة','edit'],['changes','التغييرات','plan'],['requests','الطلبات','inbox'],['archive','الأرشيف','dash']].map(([k,l,ic])=>`<button data-tt="${k}" aria-current="${S.teamTab===k?'page':'false'}">${ICONS[ic]}<span>${l}</span></button>`).join('');
    $('#view').innerHTML=viewTeam()+'<p class="demo">بيانات توضيحية لنموذج أولي.</p>';
  }else{
    tabs.style.gridTemplateColumns='repeat(6,1fr)';
    tabs.innerHTML=GUEST_TABS.map(([k,l])=>`<button data-tab="${k}" aria-current="${S.tab===k?'page':'false'}">${ICONS[k]}<span>${l}</span></button>`).join('');
    const v={mission:viewMission,plan:viewPlan,services:viewServices,explore:viewExplore,protocol:viewProtocol,assistant:viewAssistant}[S.tab];
    $('#view').innerHTML=v()+'<p class="demo">بيانات توضيحية لنموذج أولي.</p>';
  }
  try{localStorage.setItem('mrasem-ui',JSON.stringify({tab:S.tab}))}catch(e){}
}

function go(tab){S.tab=tab;render();window.scrollTo({top:0});}

document.addEventListener('click',e=>{
  const b=e.target.closest('button,[data-check]');if(!b)return;
  const ds=b.dataset;
  if(ds.mode){S.mode=ds.mode;S.day=S.mode==='inbound'?1:0;S.chat=[];render();return;}
  if(ds.role){S.role=ds.role;render();window.scrollTo({top:0});return;}
  if(ds.tab){go(ds.tab);return;}
  if(ds.tt){S.teamTab=ds.tt;render();return;}
  if(ds.day){S.day=+ds.day;render();return;}
  if(ds.filter){S.filter=ds.filter;render();return;}
  if(ds.q){ask(ds.q);return;}
  switch(ds.action){
    case 'arrive':{
      S.arrived[S.mode]=Math.min(4,S.arrived[S.mode]+1);
      const r=D().receiver;
      const msgs=['','<b>تم إبلاغ المستقبِل والسائق.</b> '+esc(r.name)+' بانتظارك.','<b>السائق في الطريق</b> إلى نقطة الالتقاء.','<b>أهلاً بك.</b> جارٍ التوجه إلى الفندق.','<b>وصلت إلى الفندق.</b> نتمنى لك إقامة طيبة.'];
      toast(msgs[S.arrived[S.mode]]);render();break;}
    case 'request':{
      S.requests.push({mode:S.mode,place:ds.place,status:'new',kind:'زيارة'});
      toast('<b>أُرسل طلبك</b> إلى منسق المراسم لترتيب السيارة والحجز.');render();break;}
    case 'goplace':{S.filter='all';go('explore');break;}
    case 'goprotocol':{go('protocol');break;}
    case 'guide':{toast('<b>دليل '+esc(ds.g)+'</b> يُفتح هنا في النسخة الكاملة من التطبيق.');break;}
    case 'resolve':{S.requests[+ds.i].status='done';S.notices.push({mode:S.mode,text:'تم ترتيب طلبك: '+(S.requests[+ds.i].place||'تم الرد على سؤالك')});toast('<b>تم.</b> وصل إشعار للضيف.');render();break;}
    case 'delay':{
      const day=D().days[1];const it=day.items[+ds.idx];
      const [h,m]=it.t.split(':').map(Number);const t=h*60+m+30;
      it.t=String(Math.floor(t/60)).padStart(2,'0')+':'+String(t%60).padStart(2,'0');
      S.changed[S.mode+'d1i'+ds.idx]=true;
      S.notices.push({mode:S.mode,text:`تأجّل موعد "${it.title}" إلى ${it.t}. تم إبلاغ السائق والفندق.`});
      toast('<b>تم التأجيل.</b> أُبلغ الضيف والسائق والفندق.');render();break;}
    case 'report':{toast('<b>تقرير الزيارة</b> يُنشأ تلقائياً ويُحفظ في الأرشيف في النسخة الكاملة.');break;}
  }
});
document.addEventListener('change',e=>{
  const c=e.target.closest('[data-check]');if(c){S.checks[S.mode+c.dataset.check]=c.checked;render();}
});
document.addEventListener('submit',e=>{
  e.preventDefault();
  if(e.target.id==='askform'){const v=$('#askin').value.trim();if(v)ask(v);}
  if(e.target.id==='noticeform'){const v=$('#noticein').value.trim();if(!v)return;S.notices.push({mode:S.mode,text:v});toast('<b>أُرسل التنبيه</b> لجميع أعضاء الوفد.');render();}
  if(e.target.id==='visitform'){
    const d=D(),val=id=>$('#'+id).value.trim();
    const before=JSON.stringify([d.receiver.name,d.receiver.phone,d.car.type,d.car.plate,d.car.driver,d.venue.hall,d.venue.floor,S.dress]);
    if(val('f_rn')!==d.receiver.name||val('f_rp')!==d.receiver.phone)S.changed[S.mode+'receiver']=true;
    if(val('f_ct')!==d.car.type||val('f_cp')!==d.car.plate||val('f_cd')!==d.car.driver)S.changed[S.mode+'car']=true;
    if(val('f_vh')!==d.venue.hall||val('f_vf')!==d.venue.floor)S.changed[S.mode+'venue']=true;
    d.receiver.name=val('f_rn')||d.receiver.name;d.receiver.phone=val('f_rp')||d.receiver.phone;
    d.car.type=val('f_ct')||d.car.type;d.car.plate=val('f_cp')||d.car.plate;d.car.driver=val('f_cd')||d.car.driver;
    d.venue.hall=val('f_vh')||d.venue.hall;d.venue.floor=val('f_vf')||d.venue.floor;
    const newDress=$('#f_dr').value;const dressChanged=newDress!==S.dress;S.dress=newDress;
    const after=JSON.stringify([d.receiver.name,d.receiver.phone,d.car.type,d.car.plate,d.car.driver,d.venue.hall,d.venue.floor,S.dress]);
    if(before===after){toast('لا توجد تغييرات لحفظها.');return;}
    S.notices.push({mode:S.mode,text:dressChanged?'تم اعتماد زي اليوم: '+(S.dress==='bisht'?'الزي الوطني مع البشت':'بدلة رسمية')+'، وتحديث بيانات الزيارة.':'تم تحديث بيانات الاستقبال أو السيارة أو القاعة. راجع بطاقة المهمة.'});
    toast('<b>تم الحفظ.</b> وصل تنبيه للضيف. انتقل إلى عرض الضيف لرؤيته.');render();
  }
});
function ask(q){
  S.chat.push({me:true,t:q});S.chat.push({me:false,t:answer(q)});render();
  const c=$('#chat');if(c)c.lastElementChild.scrollIntoView({block:'nearest'});
}
render();
