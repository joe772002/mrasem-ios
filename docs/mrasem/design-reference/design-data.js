/* Source: https://claude.ai/artifact/Gg4iccc4Y1qqbwAV7d2d52 — reference script of the Mrasem design.
   This is the original JavaScript that renders every screen of the prototype. It is the
   authoritative source for behaviour, markup structure and copy. Kept in the repo so the
   Android implementation can be checked against it offline. */

const ICONS={
  mission:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="3" y="5" width="18" height="15" rx="3"/><path d="M8 5V3h8v2M3 11h18"/></svg>',
  plan:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="3" y="4" width="18" height="17" rx="3"/><path d="M3 9h18M8 2v4M16 2v4M7 13h4M7 17h7"/></svg>',
  services:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M5 17h14l-1.5-6.5A2 2 0 0 0 15.6 9H8.4a2 2 0 0 0-1.9 1.5Z"/><circle cx="8" cy="18" r="1.8"/><circle cx="16" cy="18" r="1.8"/></svg>',
  explore:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M12 21s-7-6.2-7-11.5A7 7 0 0 1 19 9.5C19 14.8 12 21 12 21Z"/><circle cx="12" cy="9.5" r="2.5"/></svg>',
  protocol:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M12 3 4 6v6c0 4.5 3.4 8 8 9 4.6-1 8-4.5 8-9V6Z"/><path d="m9 12 2 2 4-4"/></svg>',
  assistant:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 5h16v11H9l-5 4Z"/><path d="M8 10h8M8 13h5"/></svg>',
  dash:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><rect x="3" y="3" width="8" height="8" rx="2"/><rect x="13" y="3" width="8" height="5" rx="2"/><rect x="13" y="10" width="8" height="11" rx="2"/><rect x="3" y="13" width="8" height="8" rx="2"/></svg>',
  edit:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 20h4L19 9l-4-4L4 16Z"/></svg>',
  inbox:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M3 13h5l1.5 3h5L16 13h5M5 5h14l2 8v6H3v-6Z"/></svg>'
};

const DATA={
  inbound:{
    guest:'معالي وزير العدل ووفده المرافق',
    country:'وفد رسمي زائر',
    dest:'الدوحة، دولة قطر',
    host:'وزارة العدل – دولة قطر',
    start:'2026-11-23',end:'2026-11-25',
    tz:'توقيت الدوحة UTC+3',currency:'الريال القطري (QAR)',weather:'٢٥–٣٠° مشمس',
    receiver:{name:'سعيد المري',title:'منسق المراسم والتشريفات',phone:'+974 5555 0123',spot:'صالة كبار الشخصيات – مطار حمد الدولي'},
    car:{type:'لكزس LS – أسود',plate:'123456',driver:'أحمد',country:'QATAR',style:'qa'},
    venue:{building:'مبنى وزارة العدل',area:'الدفنة، الدوحة',entrance:'المدخل الرئيسي (ب)',floor:'الطابق الرابع',hall:'قاعة الاجتماعات الكبرى',parking:'مواقف كبار الزوار أمام المدخل',lat:25.3226,lng:51.5262},
    hotel:{name:'فندق الإقامة الرسمي',area:'الخليج الغربي',room:'1204',breakfast:'٦:٣٠ – ١٠:٣٠',drive:'٨ دقائق إلى الوزارة'},
    coordinator:{name:'مريم الكعبي',phone:'+974 5555 0456'},
    emergency:[['الطوارئ (شرطة، إسعاف، إطفاء)','999'],['منسق المراسم','+974 5555 0456'],['أقرب مستشفى','مستشفى حمد العام']],
    days:[
      {label:'الإثنين ٢٣',items:[
        {t:'14:10',title:'الوصول إلى مطار حمد الدولي',where:'صالة كبار الشخصيات',note:'الاستقبال: سعيد المري'},
        {t:'15:00',title:'التوجه إلى الفندق',where:'الخليج الغربي'},
        {free:true,from:'15:30',to:'19:00',hours:3.5},
        {t:'19:30',title:'عشاء ترحيبي',where:'مطعم الفندق',note:'زي رسمي'}
      ]},
      {label:'الثلاثاء ٢٤',items:[
        {t:'09:30',title:'جلسة المباحثات الرسمية',where:'وزارة العدل – قاعة الاجتماعات الكبرى',note:'بحضور سعادة الوزير',key:true},
        {t:'11:30',title:'توقيع مذكرة التفاهم وصورة تذكارية',where:'القاعة ذاتها'},
        {t:'12:30',title:'غداء رسمي',where:'وزارة العدل'},
        {free:true,from:'14:00',to:'16:30',hours:2.5},
        {t:'17:00',title:'جولة في متحف الفن الإسلامي',where:'الكورنيش'}
      ]},
      {label:'الأربعاء ٢٥',items:[
        {t:'10:00',title:'زيارة ميدانية لمركز خدمات',where:'إدارة الخدمات الخارجية'},
        {t:'13:00',title:'الوداع الرسمي والتوجه للمطار',where:'مطار حمد الدولي',note:'المرافق: سعيد المري'}
      ]}
    ],
    services:[
      {cat:'التوصيل',items:[
        {n:'سنونو',en:'Snoonu',c:'#e3262f',d:'طعام وبقالة وصيدليات',url:'https://snoonu.com'},
        {n:'طلبات',en:'Talabat',c:'#ff5a00',d:'مطاعم وبقالة',url:'https://www.talabat.com/qatar'},
        {n:'رفيق',en:'Rafeeq',c:'#1f8a70',d:'مطاعم وخدمات توصيل',url:'https://www.google.com/search?q=Rafeeq+Qatar+app'}
      ]},
      {cat:'سيارات الأجرة',items:[
        {n:'كروة',en:'Karwa',c:'#0b6e4f',d:'التاكسي الرسمي بالعداد، متاح من المطار مباشرة',url:'https://www.mowasalat.com'},
        {n:'أوبر',en:'Uber',c:'#111111',d:'يتيح طلب تاكسي كروة من داخله',url:'https://www.uber.com'},
        {n:'تطبيقات مرخّصة أخرى',en:'Badrgo · Aabir · Ryde',c:'#6f6266',d:'من قائمة وزارة المواصلات',url:'https://marhaba.qa/?p=358177'}
      ]},
      {cat:'النقل العام',items:[
        {n:'مترو الدوحة',en:'Doha Metro',c:'#8a1538',d:'أقرب محطة للفندق: الخليج الغربي – ٧ دقائق مشياً',url:'https://www.qr.com.qa'}
      ]}
    ],
    quick:[['العملة','ريال قطري'],['المقابس','نوع G (ثلاثي)'],['الطوارئ','999'],['البقشيش','١٠٪ اختياري'],['عطلة الأسبوع','الجمعة والسبت'],['الماء','آمن ومتوفر معبأً']],
    places:[
      {n:'متحف الفن الإسلامي',d:'مجموعة فنية إسلامية من ثلاث قارات، على الكورنيش',min:10,dur:1.5,tag:'ثقافة'},
      {n:'كورنيش الدوحة',d:'ممشى بحري بإطلالة على أبراج الخليج الغربي',min:5,dur:1,tag:'إطلالة'},
      {n:'سوق واقف',d:'السوق التراثي، مطاعم وصقور وحرف تقليدية',min:12,dur:2,tag:'تراث'},
      {n:'متحف قطر الوطني',d:'قصة قطر في مبنى وردة الصحراء',min:12,dur:2,tag:'ثقافة'},
      {n:'الحي الثقافي كتارا',d:'مدرج ومساجد ومعارض على البحر',min:10,dur:1.5,tag:'ثقافة'},
      {n:'مشيرب قلب الدوحة',d:'حي معماري حديث ومتاحف مشيرب',min:12,dur:1.5,tag:'عمارة'},
      {n:'اللؤلؤة – قطر',d:'مرسى ويخوت ومطاعم مطلة على البحر',min:15,dur:2,tag:'مساء'},
      {n:'رحلة صحراوية إلى خور العديد',d:'البحر الداخلي والكثبان، تحتاج يوماً أو نصف يوم',min:70,dur:5,tag:'طبيعة'}
    ],
    customs:['المصافحة باليد اليمنى، والانتظار حتى تمدّ السيدة يدها أولاً','تقديم القهوة العربية والتمر من مظاهر الترحيب، ويُهزّ الفنجان عند الاكتفاء','تجنّب التقاط صور للأشخاص دون استئذان','مراعاة أوقات الصلاة عند جدولة الزيارات'],
    next:{who:'سعادة وزير العدل – دولة قطر',address:'سعادة الوزير',seat:'رأس الطاولة، الضيف عن يمينه',gift:'هدية تذكارية تُقدّم بعد التوقيع',lang:'ترجمة فورية متاحة'}
  },
  outbound:{
    guest:'وفد وزارة العدل – دولة قطر',
    country:'مهمة رسمية',
    dest:'لندن، المملكة المتحدة',
    host:'مؤتمر قانوني دولي (مثال)',
    start:'2026-12-07',end:'2026-12-10',
    tz:'لندن UTC+0 (الدوحة أبكر ٣ ساعات)',currency:'الجنيه الإسترليني (GBP)',weather:'٤–٩° غائم، احتمال مطر',
    receiver:{name:'ممثل سفارة دولة قطر',title:'الملحق الإداري (مثال)',phone:'يُضاف من فريق المراسم',spot:'صالة الوصول – مطار هيثرو'},
    car:{type:'مرسيدس V-Class – أسود',plate:'AB12 CDE',driver:'جيمس',country:'UK',style:'uk'},
    venue:{building:'مركز المؤتمرات (مثال)',area:'وستمنستر، لندن',entrance:'مدخل الوفود الرسمية',floor:'الطابق الأول',hall:'القاعة الرئيسية',parking:'منطقة إنزال الوفود',lat:51.5007,lng:-0.1246},
    hotel:{name:'فندق إقامة الوفد',area:'وسط لندن',room:'512',breakfast:'٧:٠٠ – ١٠:٣٠',drive:'١٥ دقيقة إلى المؤتمر'},
    coordinator:{name:'مريم الكعبي',phone:'+974 5555 0456'},
    emergency:[['الطوارئ في المملكة المتحدة','999'],['منسق المراسم','+974 5555 0456'],['سفارة دولة قطر','يُضاف من فريق المراسم']],
    days:[
      {label:'الإثنين ٧',items:[
        {t:'13:40',title:'الوصول إلى مطار هيثرو',where:'صالة الوصول',note:'الاستقبال: ممثل السفارة'},
        {t:'15:00',title:'التوجه إلى الفندق',where:'وسط لندن'},
        {free:true,from:'15:30',to:'18:30',hours:3},
        {t:'19:00',title:'عشاء عمل مع السفارة',where:'مقر السفارة',note:'زي رسمي'}
      ]},
      {label:'الثلاثاء ٨',items:[
        {t:'09:00',title:'الجلسة الافتتاحية للمؤتمر',where:'القاعة الرئيسية',key:true},
        {t:'11:00',title:'كلمة وفد دولة قطر',where:'القاعة الرئيسية',note:'الملف التعريفي مرفق'},
        {free:true,from:'13:00',to:'15:00',hours:2},
        {t:'15:30',title:'لقاء ثنائي مع وفد شريك',where:'قاعة الاجتماعات ٣'}
      ]},
      {label:'الأربعاء ٩',items:[
        {t:'10:00',title:'ورش العمل المتخصصة',where:'الطابق الأول'},
        {t:'16:00',title:'حفل الختام',where:'القاعة الرئيسية'}
      ]},
      {label:'الخميس ١٠',items:[
        {t:'11:00',title:'المغادرة إلى المطار',where:'مطار هيثرو'}
      ]}
    ],
    services:[
      {cat:'التوصيل',items:[
        {n:'Deliveroo',en:'Deliveroo',c:'#00ccbc',d:'مطاعم وبقالة',url:'https://deliveroo.co.uk'},
        {n:'Uber Eats',en:'Uber Eats',c:'#06c167',d:'مطاعم',url:'https://www.ubereats.com/gb'},
        {n:'Just Eat',en:'Just Eat',c:'#ff8000',d:'مطاعم',url:'https://www.just-eat.co.uk'}
      ]},
      {cat:'سيارات الأجرة',items:[
        {n:'Uber',en:'Uber',c:'#111111',d:'الأكثر انتشاراً',url:'https://www.uber.com/gb'},
        {n:'Bolt',en:'Bolt',c:'#34d186',d:'بديل بأسعار منافسة',url:'https://bolt.eu'},
        {n:'التاكسي الأسود',en:'Black Cab',c:'#333333',d:'من الشارع أو عبر FREENOW',url:'https://www.free-now.com/uk/'}
      ]},
      {cat:'النقل العام',items:[
        {n:'مترو لندن',en:'TfL Underground',c:'#dc241f',d:'الدفع بالبطاقة اللاتلامسية مباشرة',url:'https://tfl.gov.uk'}
      ]}
    ],
    quick:[['العملة','جنيه إسترليني'],['المقابس','نوع G (ثلاثي)'],['الطوارئ','999'],['البقشيش','١٠–١٢٫٥٪ في المطاعم'],['القيادة','على اليسار'],['الطقس','اصطحب معطفاً ومظلة']],
    places:[
      {n:'المتحف البريطاني',d:'من أكبر متاحف العالم، الدخول مجاني',min:12,dur:2,tag:'ثقافة'},
      {n:'نهر التايمز ووستمنستر',d:'ممشى يطل على البرلمان وساعة بيغ بن',min:10,dur:1,tag:'إطلالة'},
      {n:'المعرض الوطني',d:'لوحات أوروبية كلاسيكية في ميدان ترافلغار',min:10,dur:1.5,tag:'فن'},
      {n:'حدائق هايد بارك',d:'نزهة هادئة بين الجلسات',min:8,dur:1,tag:'طبيعة'}
    ],
    customs:['الالتزام الدقيق بالمواعيد','المصافحة باختصار مع تواصل بصري','تجنّب الأسئلة الشخصية في اللقاء الأول','يُفضّل عدم مقاطعة المتحدث في الجلسات'],
    next:{who:'رئيس اللجنة المنظمة للمؤتمر',address:'Your Excellency / Mr. Chairman',seat:'المقعد المخصص لوفد دولة قطر في الصف الأول',gift:'هدية تذكارية من الوزارة',lang:'الإنجليزية'}
  }
};
