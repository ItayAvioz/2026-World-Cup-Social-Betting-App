// ── COUNTDOWN ────────────────────────────────────────────────
// Target: June 11 2026, 19:00 UTC = 22:00 IDT (opening kick-off)
(function() {
  const T = new Date('2026-06-11T19:00:00Z');
  function tick() {
    let d = T - Date.now();
    if (d < 0) d = 0;
    document.getElementById('cd-days').textContent  = String(Math.floor(d/86400000)).padStart(2,'0');
    document.getElementById('cd-hours').textContent = String(Math.floor(d%86400000/3600000)).padStart(2,'0');
    document.getElementById('cd-mins').textContent  = String(Math.floor(d%3600000/60000)).padStart(2,'0');
    document.getElementById('cd-secs').textContent  = String(Math.floor(d%60000/1000)).padStart(2,'0');
  }
  tick(); setInterval(tick,1000);
})();

// ── TEAM DATA ────────────────────────────────────────────────
// Draw: December 5, 2025, Kennedy Center, Washington D.C.
// IDT = UTC+3 (Israel Daylight Time, June–July)
// Mexico City = UTC-6 (no DST since 2023) → IDT = local+9
// Los Angeles/Seattle/Vancouver = PDT UTC-7 → IDT = local+10
// Toronto = EDT UTC-4 → IDT = local+7

const TEAMS = [
  // GROUP A
  { name:'Mexico', code:'mx', group:'A', conf:'CONCACAF', host:true, lat:19.4, lng:-99.1,
    fifaRank:15, best:'Quarter-Finals', times:'2×', lastAchieved:'1986 (Mexico)', lastWC:'2022 (Qatar) — Group Stage',
    schedule:[
      { phase:'group', label:'Group A', date:'Thu, Jun 11', opponent:'South Africa', oppCode:'za', venue:'Estadio Azteca', city:'Mexico City', idt:'22:00', idtLabel:'Jun 11' },
      { phase:'group', label:'Group A', date:'Thu, Jun 18', opponent:'South Korea',  oppCode:'kr', venue:'Estadio Akron',  city:'Guadalajara', idt:'06:00', idtLabel:'Jun 19 ⁺¹' },
      { phase:'group', label:'Group A', date:'Wed, Jun 24', opponent:'UEFA PO-D TBD', oppCode:null, venue:'Estadio Azteca', city:'Mexico City', idt:'04:00', idtLabel:'Jun 25 ⁺¹' },
      { phase:'knockout', label:'Round of 32', date:'Tue, Jun 30', opponent:'TBD (if advancing)', oppCode:null, venue:'Estadio Azteca', city:'Mexico City', idt:'TBD', idtLabel:'Jun 30' },
    ]
  },
  { name:'South Africa', code:'za', group:'A', conf:'CAF',      host:false, lat:-25.7, lng:28.2,
    fifaRank:65, best:'Group Stage', times:'3 appearances', lastAchieved:'2010 (as host)', lastWC:'2010 (South Africa) — Group Stage (as host)' },
  { name:'South Korea',  code:'kr', group:'A', conf:'AFC',      host:false, lat:37.6, lng:127.0,
    fifaRank:25, best:'4th Place', times:'1×', lastAchieved:'2002 (Japan/Korea)', lastWC:'2022 (Qatar) — Round of 16' },
  // GROUP B
  { name:'Canada', code:'ca', group:'B', conf:'CONCACAF', host:true, lat:43.7, lng:-79.4,
    fifaRank:47, best:'Group Stage', times:'2 appearances', lastAchieved:'2022 (Qatar)', lastWC:'2022 (Qatar) — Group Stage',
    schedule:[
      { phase:'group', label:'Group B', date:'Fri, Jun 12', opponent:'UEFA PO-A TBD', oppCode:null, venue:'BMO Field',  city:'Toronto',    idt:'22:00', idtLabel:'Jun 12' },
      { phase:'group', label:'Group B', date:'Thu, Jun 18', opponent:'Qatar',          oppCode:'qa', venue:'BC Place',   city:'Vancouver',  idt:'01:00', idtLabel:'Jun 19 ⁺¹' },
      { phase:'group', label:'Group B', date:'Wed, Jun 24', opponent:'Switzerland',    oppCode:'ch', venue:'BC Place',   city:'Vancouver',  idt:'22:00', idtLabel:'Jun 24' },
      { phase:'knockout', label:'Round of 32', date:'Thu, Jul 2', opponent:'TBD (if advancing)', oppCode:null, venue:'BC Place', city:'Vancouver', idt:'TBD', idtLabel:'Jul 2' },
    ]
  },
  { name:'Qatar',       code:'qa', group:'B', conf:'AFC',  host:false, lat:26.0, lng:50.5,
    fifaRank:63, best:'Group Stage (host)', times:'1×', lastAchieved:'2022 (Qatar)', lastWC:'2022 (Qatar) — Group Stage (as host)' },
  { name:'Switzerland', code:'ch', group:'B', conf:'UEFA', host:false, lat:46.9, lng:7.4,
    fifaRank:20, best:'Quarter-Finals', times:'3×', lastAchieved:'1954 (Switzerland)', lastWC:'2022 (Qatar) — Round of 16' },
  // GROUP C
  { name:'Brazil',   code:'br', group:'C', conf:'CONMEBOL', host:false, lat:-15.8, lng:-47.9,
    fifaRank:5,  best:'World Champion', times:'5×', lastAchieved:'2002 (Japan/Korea)', lastWC:'2022 (Qatar) — Quarter-Finals' },
  { name:'Morocco',  code:'ma', group:'C', conf:'CAF',      host:false, lat:34.0, lng:-6.8,
    fifaRank:12, best:'4th Place', times:'1×', lastAchieved:'2022 (Qatar)', lastWC:'2022 (Qatar) — 4th Place' },
  { name:'Haiti',    code:'ht', group:'C', conf:'CONCACAF', host:false, lat:19.0, lng:-72.3,
    fifaRank:88, best:'Group Stage', times:'1 appearance', lastAchieved:'1974 (West Germany)', lastWC:'1974 (West Germany) — Group Stage' },
  { name:'Scotland', code:'gb-sct', group:'C', conf:'UEFA', host:false, lat:55.9, lng:-3.2,
    fifaRank:30, best:'Group Stage', times:'8 appearances', lastAchieved:'1998 (France)', lastWC:'1998 (France) — Group Stage' },
  // GROUP D
  { name:'United States', code:'us', group:'D', conf:'CONCACAF', host:true, lat:38.9, lng:-77.0,
    fifaRank:14, best:'3rd Place', times:'1×', lastAchieved:'1930 (Uruguay)', lastWC:'2022 (Qatar) — Round of 16',
    schedule:[
      { phase:'group', label:'Group D', date:'Fri, Jun 12', opponent:'Paraguay',       oppCode:'py', venue:'SoFi Stadium', city:'Inglewood, CA', idt:'04:00', idtLabel:'Jun 13 ⁺¹' },
      { phase:'group', label:'Group D', date:'Fri, Jun 19', opponent:'Australia',       oppCode:'au', venue:'Lumen Field',  city:'Seattle',       idt:'22:00', idtLabel:'Jun 19' },
      { phase:'group', label:'Group D', date:'Thu, Jun 25', opponent:'UEFA PO-C TBD',   oppCode:null, venue:'SoFi Stadium', city:'Inglewood, CA', idt:'05:00', idtLabel:'Jun 26 ⁺¹' },
      { phase:'knockout', label:'Round of 32', date:'Sun, Jun 28', opponent:'TBD (if advancing)', oppCode:null, venue:'SoFi Stadium', city:'Inglewood, CA', idt:'TBD', idtLabel:'Jun 28' },
    ]
  },
  { name:'Paraguay',  code:'py', group:'D', conf:'CONMEBOL', host:false, lat:-25.3, lng:-57.6,
    fifaRank:60, best:'Quarter-Finals', times:'1×', lastAchieved:'2010 (South Africa)', lastWC:'2010 (South Africa) — Quarter-Finals' },
  { name:'Australia', code:'au', group:'D', conf:'AFC',      host:false, lat:-33.9, lng:151.2,
    fifaRank:24, best:'Round of 16', times:'2×', lastAchieved:'2022 (Qatar)', lastWC:'2022 (Qatar) — Round of 16' },
  // GROUP E
  { name:'Germany',     code:'de', group:'E', conf:'UEFA',     host:false, lat:52.5, lng:13.4,
    fifaRank:13, best:'World Champion', times:'4×', lastAchieved:'2014 (Brazil)', lastWC:'2022 (Qatar) — Group Stage' },
  { name:'Curaçao',     code:'cw', group:'E', conf:'CONCACAF', host:false, lat:10.5, lng:-66.9,
    fifaRank:92, best:'First World Cup!', times:'First time', lastAchieved:'2026 (debut)', lastWC:'2026 — First World Cup ever' },
  { name:'Ivory Coast', code:'ci', group:'E', conf:'CAF',      host:false, lat:5.4, lng:-4.0,
    fifaRank:61, best:'Group Stage', times:'3 appearances', lastAchieved:'2014 (Brazil)', lastWC:'2014 (Brazil) — Group Stage' },
  { name:'Ecuador',     code:'ec', group:'E', conf:'CONMEBOL', host:false, lat:-0.2, lng:-78.5,
    fifaRank:30, best:'Round of 16', times:'1×', lastAchieved:'2006 (Germany)', lastWC:'2022 (Qatar) — Group Stage' },
  // GROUP F
  { name:'Netherlands', code:'nl', group:'F', conf:'UEFA', host:false, lat:52.4, lng:4.9,
    fifaRank:7,  best:'Runner-Up', times:'3×', lastAchieved:'2010 (South Africa)', lastWC:'2022 (Qatar) — Quarter-Finals' },
  { name:'Japan',       code:'jp', group:'F', conf:'AFC',  host:false, lat:35.7, lng:139.7,
    fifaRank:18, best:'Round of 16', times:'4×', lastAchieved:'2022 (Qatar)', lastWC:'2022 (Qatar) — Round of 16' },
  { name:'Tunisia',     code:'tn', group:'F', conf:'CAF',  host:false, lat:36.8, lng:10.2,
    fifaRank:26, best:'Group Stage', times:'6 appearances', lastAchieved:'2022 (Qatar)', lastWC:'2022 (Qatar) — Group Stage' },
  // GROUP G
  { name:'Belgium',     code:'be', group:'G', conf:'UEFA', host:false, lat:50.8, lng:4.4,
    fifaRank:8,  best:'3rd Place', times:'1×', lastAchieved:'2018 (Russia)', lastWC:'2022 (Qatar) — Group Stage' },
  { name:'Egypt',       code:'eg', group:'G', conf:'CAF',  host:false, lat:30.0, lng:31.2,
    fifaRank:38, best:'Group Stage', times:'3 appearances', lastAchieved:'2018 (Russia)', lastWC:'2018 (Russia) — Group Stage' },
  { name:'Iran',        code:'ir', group:'G', conf:'AFC',  host:false, lat:35.7, lng:51.4,
    fifaRank:22, best:'Group Stage', times:'6 appearances', lastAchieved:'2022 (Qatar)', lastWC:'2022 (Qatar) — Group Stage' },
  { name:'New Zealand', code:'nz', group:'G', conf:'OFC',  host:false, lat:-37.0, lng:175.5,
    fifaRank:90, best:'Group Stage (unbeaten!)', times:'2 appearances', lastAchieved:'2010 (South Africa)', lastWC:'2010 (South Africa) — Group Stage' },
  // GROUP H
  { name:'Spain',        code:'es', group:'H', conf:'UEFA',     host:false, lat:40.4, lng:-3.7,
    fifaRank:3,  best:'World Champion', times:'1×', lastAchieved:'2010 (South Africa)', lastWC:'2022 (Qatar) — Round of 16' },
  { name:'Cape Verde',   code:'cv', group:'H', conf:'CAF',      host:false, lat:14.9, lng:-23.5,
    fifaRank:97, best:'First World Cup!', times:'First time', lastAchieved:'2026 (debut)', lastWC:'2026 — First World Cup ever' },
  { name:'Saudi Arabia', code:'sa', group:'H', conf:'AFC',      host:false, lat:24.7, lng:46.7,
    fifaRank:56, best:'Round of 16', times:'1×', lastAchieved:'1994 (USA)', lastWC:'2022 (Qatar) — Group Stage' },
  { name:'Uruguay',      code:'uy', group:'H', conf:'CONMEBOL', host:false, lat:-34.9, lng:-56.2,
    fifaRank:10, best:'World Champion', times:'2×', lastAchieved:'1950 (Brazil)', lastWC:'2022 (Qatar) — Group Stage' },
  // GROUP I
  { name:'France',  code:'fr', group:'I', conf:'UEFA', host:false, lat:48.9, lng:2.3,
    fifaRank:2,  best:'World Champion', times:'2×', lastAchieved:'2018 (Russia)', lastWC:'2022 (Qatar) — Runner-Up' },
  { name:'Senegal', code:'sn', group:'I', conf:'CAF',  host:false, lat:14.5, lng:-14.5,
    fifaRank:17, best:'Quarter-Finals', times:'1×', lastAchieved:'2002 (Japan/Korea)', lastWC:'2022 (Qatar) — Round of 16' },
  { name:'Norway',  code:'no', group:'I', conf:'UEFA', host:false, lat:59.9, lng:10.8,
    fifaRank:35, best:'Round of 16', times:'2×', lastAchieved:'1998 (France)', lastWC:'1998 (France) — Round of 16' },
  // GROUP J
  { name:'Argentina', code:'ar', group:'J', conf:'CONMEBOL', host:false, lat:-34.6, lng:-58.4,
    fifaRank:1,  best:'World Champion', times:'3×', lastAchieved:'2022 (Qatar)', lastWC:'2022 (Qatar) — 🏆 Champion' },
  { name:'Algeria',   code:'dz', group:'J', conf:'CAF',      host:false, lat:36.7, lng:3.0,
    fifaRank:55, best:'Round of 16', times:'1×', lastAchieved:'2014 (Brazil)', lastWC:'2014 (Brazil) — Round of 16' },
  { name:'Austria',   code:'at', group:'J', conf:'UEFA',     host:false, lat:48.2, lng:16.4,
    fifaRank:23, best:'3rd Place', times:'1×', lastAchieved:'1954 (Switzerland)', lastWC:'1998 (France) — Group Stage' },
  { name:'Jordan',    code:'jo', group:'J', conf:'AFC',      host:false, lat:31.9, lng:35.9,
    fifaRank:80, best:'First World Cup!', times:'First time', lastAchieved:'2026 (debut)', lastWC:'2026 — First World Cup ever' },
  // GROUP K
  { name:'Portugal',   code:'pt', group:'K', conf:'UEFA',     host:false, lat:38.7, lng:-9.1,
    fifaRank:6,  best:'3rd Place', times:'1×', lastAchieved:'1966 (England)', lastWC:'2022 (Qatar) — Quarter-Finals' },
  { name:'Uzbekistan', code:'uz', group:'K', conf:'AFC',      host:false, lat:41.3, lng:69.3,
    fifaRank:105, best:'First World Cup!', times:'First time', lastAchieved:'2026 (debut)', lastWC:'2026 — First World Cup ever' },
  { name:'Colombia',   code:'co', group:'K', conf:'CONMEBOL', host:false, lat:4.7, lng:-74.1,
    fifaRank:9,  best:'Quarter-Finals', times:'1×', lastAchieved:'2014 (Brazil)', lastWC:'2018 (Russia) — Round of 16' },
  // GROUP L
  { name:'England', code:'gb-eng', group:'L', conf:'UEFA',     host:false, lat:51.5, lng:-0.1,
    fifaRank:4,  best:'World Champion', times:'1×', lastAchieved:'1966 (England)', lastWC:'2022 (Qatar) — Quarter-Finals' },
  { name:'Croatia', code:'hr',     group:'L', conf:'UEFA',     host:false, lat:45.8, lng:16.0,
    fifaRank:11, best:'Runner-Up', times:'1×', lastAchieved:'2018 (Russia)', lastWC:'2022 (Qatar) — 3rd Place' },
  { name:'Ghana',   code:'gh',     group:'L', conf:'CAF',      host:false, lat:5.6, lng:-0.2,
    fifaRank:50, best:'Quarter-Finals', times:'1×', lastAchieved:'2010 (South Africa)', lastWC:'2022 (Qatar) — Group Stage' },
  { name:'Panama',  code:'pa',     group:'L', conf:'CONCACAF', host:false, lat:8.9, lng:-79.5,
    fifaRank:72, best:'Group Stage', times:'1 appearance', lastAchieved:'2018 (Russia)', lastWC:'2018 (Russia) — Group Stage' },
];

// ── TEAM EXTRA DATA (population, WC apps, facts) ─────────────
const TEAM_EXTRA = {
  'mx':     { pop:'130M',  wcApps:18, footballFact:'First nation to host/co-host 3 World Cups.',     nonFootballFact:'Home to the world\'s largest pyramid (Cholula).' },
  'za':     { pop:'60M',   wcApps:4,  footballFact:'Hosted the first African World Cup in 2010.',    nonFootballFact:'The only country with three capital cities.' },
  'kr':     { pop:'51M',   wcApps:12, footballFact:'Most World Cup appearances of any Asian side.',  nonFootballFact:'Has the world\'s fastest average internet speed.' },
  'ca':     { pop:'40M',   wcApps:3,  footballFact:'This is their first time hosting the World Cup.',nonFootballFact:'Has more lakes than the rest of the world combined.' },
  'qa':     { pop:'3M',    wcApps:2,  footballFact:'Qualified "on merit" for the first time.',       nonFootballFact:'One of two places where the desert meets the sea.' },
  'ch':     { pop:'9M',    wcApps:13, footballFact:'Reached the Round of 16 in 4 of last 5 WCs.',   nonFootballFact:'Has no official capital (Bern is de facto).' },
  'br':     { pop:'215M',  wcApps:23, footballFact:'Only team to appear in every World Cup.',        nonFootballFact:'Largest Japanese population outside of Japan.' },
  'ma':     { pop:'38M',   wcApps:7,  footballFact:'First African semi-finalist in WC history (2022).', nonFootballFact:'Home to the world\'s oldest university.' },
  'ht':     { pop:'11.7M', wcApps:2,  footballFact:'Returning since their 1974 debut.',              nonFootballFact:'First black-led republic in the world.' },
  'gb-sct': { pop:'5.5M',  wcApps:9,  footballFact:'First World Cup appearance since 1998.',         nonFootballFact:'The national animal of Scotland is the Unicorn.' },
  'us':     { pop:'340M',  wcApps:12, footballFact:'Hosting for the 2nd time (also co-hosted 1994).', nonFootballFact:'Has the world\'s largest highway system.' },
  'py':     { pop:'7M',    wcApps:9,  footballFact:'Qualified on the final matchday of CONMEBOL.',   nonFootballFact:'Shares the world\'s largest hydroelectric plant.' },
  'au':     { pop:'26M',   wcApps:7,  footballFact:'Moved from OFC to the Asian confederation in 2006.', nonFootballFact:'Home to more than 10,000 unique beaches.' },
  'de':     { pop:'84M',   wcApps:21, footballFact:'Have reached the semi-finals 13 times.',         nonFootballFact:'First country to adopt Daylight Saving Time.' },
  'cw':     { pop:'150K',  wcApps:1,  footballFact:'Debut — the smallest nation to qualify.',        nonFootballFact:'Most residents speak at least 4 languages.' },
  'ci':     { pop:'28M',   wcApps:4,  footballFact:'Won the 2024 Africa Cup of Nations tournament.', nonFootballFact:'The world\'s largest producer of cocoa beans.' },
  'ec':     { pop:'18M',   wcApps:5,  footballFact:'Record for most altitude-aided home wins in qualifying.', nonFootballFact:'First country to give nature legal rights.' },
  'nl':     { pop:'18M',   wcApps:12, footballFact:'Runners-up 3 times — never won the trophy.',    nonFootballFact:'One-third of the country is below sea level.' },
  'jp':     { pop:'124M',  wcApps:8,  footballFact:'Fans world-famous for cleaning the stadium.',    nonFootballFact:'Features over 5 million vending machines.' },
  'tn':     { pop:'12M',   wcApps:7,  footballFact:'First African team to win a World Cup match.',   nonFootballFact:'Location of the ancient city-state of Carthage.' },
  'be':     { pop:'12M',   wcApps:15, footballFact:'Known as the "Red Devils."',                    nonFootballFact:'Has the highest density of castles in the world.' },
  'eg':     { pop:'112M',  wcApps:4,  footballFact:'First African team to play a World Cup (1934).', nonFootballFact:'Home to the last of the Ancient Wonders (Giza).' },
  'ir':     { pop:'89M',   wcApps:7,  footballFact:'Have never passed the group stage.',             nonFootballFact:'Home to the world\'s oldest continuous civilization.' },
  'nz':     { pop:'5.2M',  wcApps:3,  footballFact:'Only unbeaten team at the 2010 World Cup.',     nonFootballFact:'First country to grant women the right to vote (1893).' },
  'es':     { pop:'48M',   wcApps:17, footballFact:'Hold the record for most passes in a WC match.', nonFootballFact:'Produces nearly half of the world\'s olive oil.' },
  'cv':     { pop:'590K',  wcApps:1,  footballFact:'Debut — smallest African island nation to qualify.', nonFootballFact:'Charles Darwin studied the local flora here.' },
  'sa':     { pop:'36M',   wcApps:7,  footballFact:'Shocked Argentina in the 2022 opening match.',  nonFootballFact:'A country with no permanent natural rivers.' },
  'uy':     { pop:'3.5M',  wcApps:15, footballFact:'Won the very first World Cup in 1930.',          nonFootballFact:'First nation to fully legalize marijuana sales.' },
  'fr':     { pop:'68M',   wcApps:17, footballFact:'Reached the final in 3 of the last 7 WCs.',     nonFootballFact:'The most visited country in the world.' },
  'sn':     { pop:'18M',   wcApps:4,  footballFact:'Known as the "Lions of Teranga."',               nonFootballFact:'Features a bright pink lake (Lake Retba).' },
  'no':     { pop:'5.6M',  wcApps:4,  footballFact:'Erling Haaland\'s first-ever World Cup.',        nonFootballFact:'Home to the world\'s longest road tunnel (24.5km).' },
  'ar':     { pop:'46M',   wcApps:19, footballFact:'Entering as defending 2022 World Champions.',    nonFootballFact:'Invented the world\'s first animated feature film.' },
  'dz':     { pop:'45M',   wcApps:5,  footballFact:'Part of the infamous "Disgrace of Gijon" (1982).', nonFootballFact:'The largest country in Africa by land area.' },
  'at':     { pop:'9M',    wcApps:8,  footballFact:'Best finish: 3rd place at the 1954 World Cup.',  nonFootballFact:'Home to the world\'s oldest zoo (Tiergarten Schönbrunn).' },
  'jo':     { pop:'11M',   wcApps:1,  footballFact:'Debut — qualified through the AFC playoff.',     nonFootballFact:'Contains the Dead Sea (the lowest point on Earth).' },
  'pt':     { pop:'10M',   wcApps:9,  footballFact:'Likely Cristiano Ronaldo\'s final World Cup.',   nonFootballFact:'The world\'s largest producer of natural cork.' },
  'uz':     { pop:'36M',   wcApps:1,  footballFact:'Debut — one of the longest waits in Asian football.', nonFootballFact:'One of only two doubly landlocked countries in the world.' },
  'co':     { pop:'52M',   wcApps:7,  footballFact:'Famous for Higuita\'s iconic "Scorpion Kick."',  nonFootballFact:'Second most biodiverse country on the planet.' },
  'gb-eng': { pop:'69M',   wcApps:17, footballFact:'Won their only title on home soil in 1966.',    nonFootballFact:'Champagne was actually invented here, not France.' },
  'hr':     { pop:'3.8M',  wcApps:7,  footballFact:"Reached the top 3 in '98, '18, and '22.",       nonFootballFact:'Invented the necktie (originally called cravat).' },
  'gh':     { pop:'34M',   wcApps:5,  footballFact:'Cruelly denied a semi-final by Suarez in 2010.', nonFootballFact:'First sub-Saharan nation to gain independence.' },
  'pa':     { pop:'4.5M',  wcApps:2,  footballFact:'Debuted in 2018; returning for 2026.',           nonFootballFact:'Only place on Earth to see the sun rise over the Pacific Ocean.' },
};

// TBD playoff slots per group
const TBD = {
  A:{ note:'UEFA Playoff D', hint:'Denmark / Czechia / N.Macedonia / Ireland' },
  B:{ note:'UEFA Playoff A', hint:'Italy / N.Ireland / Wales / Bosnia' },
  D:{ note:'UEFA Playoff C', hint:'Turkey / Romania / Slovakia / Kosovo' },
  F:{ note:'UEFA Playoff B', hint:'Ukraine / Sweden / Poland / Albania' },
  I:{ note:'Intercont. PO 2', hint:'Bolivia / Suriname / Iraq' },
  K:{ note:'Intercont. PO 1', hint:'Jamaica / New Caledonia / DR Congo' },
};

const flagUrl = (code, w=40) => `https://flagcdn.com/w${w}/${code}.png`;

// ── RENDER GROUPS ────────────────────────────────────────────
(function() {
  const letters = ['A','B','C','D','E','F','G','H','I','J','K','L'];
  const container = document.getElementById('groups-grid');

  letters.forEach(letter => {
    const groupTeams = TEAMS.filter(t => t.group === letter);
    const tbd = TBD[letter];
    const card = document.createElement('div');
    card.className = 'group-card';

    let html = `<div class="group-header">GROUP ${letter}</div><div class="group-teams">`;
    groupTeams.forEach(team => {
      const idx = TEAMS.indexOf(team);
      html += `
        <div class="group-team" data-team-idx="${idx}">
          <img src="${flagUrl(team.code)}" alt="${team.name}"
               onerror="this.style.display='none';this.nextSibling.style.display='flex'">
          <div class="team-placeholder" style="display:none">?</div>
          <div class="team-info">
            <div class="team-name-sm">${team.name}</div>
            <div class="team-conf-sm">${team.conf}</div>
          </div>
          ${team.host ? '<span class="badge-host">HOST</span>' : ''}
        </div>`;
    });
    if (tbd) {
      html += `
        <div class="group-team" title="${tbd.hint}" style="cursor:default">
          <div class="team-placeholder">?</div>
          <div class="team-info">
            <div class="team-name-sm">TBD</div>
            <div class="team-conf-sm">${tbd.note}</div>
          </div>
          <span class="badge-tbd">TBD</span>
        </div>`;
    }
    html += `</div>`;
    card.innerHTML = html;
    container.appendChild(card);
  });

  // Event delegation — click any team row
  container.addEventListener('click', e => {
    const row = e.target.closest('[data-team-idx]');
    if (row) openModal(TEAMS[+row.dataset.teamIdx], 'stats');
  });
})();

// ── WORLD MAP (flat equirectangular) ─────────────────────────
(function() {
  var container = document.getElementById('globe-container');

  // Background map — object-fit:fill keeps exact equirectangular alignment (no crop/shift)
  var mapImg = document.createElement('img');
  mapImg.className = 'map-bg';
  mapImg.alt = '';
  // earth-dark.jpg is guaranteed equirectangular (designed for globe.gl)
  mapImg.src = 'https://unpkg.com/three-globe/example/img/earth-dark.jpg';
  mapImg.onerror = function() {
    this.src = 'https://cdn.jsdelivr.net/npm/three-globe/example/img/earth-dark.jpg';
  };
  container.appendChild(mapImg);

  var W = container.offsetWidth  || 900;
  var H = container.offsetHeight || 560;

  // Equirectangular: lng→x, lat→y
  function proj(lat, lng) {
    return {
      x: ((lng + 180) / 360) * 100,
      y: ((90  - lat)  / 180) * 100
    };
  }

  TEAMS.forEach(function(d) {
    var p   = proj(d.lat, d.lng);
    var big = d.host;
    var fw  = big ? 38 : 26;
    var fh  = big ? 28 : 19;

    var wrap = document.createElement('div');
    wrap.title = d.name + ' · Group ' + d.group;
    wrap.style.cssText = [
      'position:absolute',
      'left:' + p.x + '%',
      'top:'  + p.y + '%',
      'transform:translate(-50%,-50%)',
      'cursor:pointer',
      'z-index:' + (big ? 15 : 10),
      'transition:transform .18s',
      'pointer-events:auto'
    ].join(';');

    var img = document.createElement('img');
    img.src = 'https://flagcdn.com/w' + (big ? 56 : 40) + '/' + d.code + '.png';
    img.alt = d.name;
    img.style.cssText = [
      'width:'  + fw + 'px',
      'height:' + fh + 'px',
      'border-radius:3px',
      'object-fit:cover',
      'display:block',
      'pointer-events:none',
      'box-shadow:0 2px 10px rgba(0,0,0,.9)',
      big ? 'border:2.5px solid #f5c518' : 'border:1px solid rgba(255,255,255,.4)'
    ].join(';');

    img.onerror = function() {
      this.style.display = 'none';
      var fb = document.createElement('div');
      fb.textContent = d.code.slice(0, 2).toUpperCase();
      fb.style.cssText = [
        'width:'  + fw + 'px',
        'height:' + fh + 'px',
        'border-radius:3px',
        'display:flex','align-items:center','justify-content:center',
        'font-size:9px','font-weight:700',
        'box-shadow:0 2px 8px rgba(0,0,0,.9)',
        big ? 'background:#f5c518;color:#000;border:2.5px solid #f5c518'
            : 'background:#444;color:#fff;border:1px solid rgba(255,255,255,.3)'
      ].join(';');
      wrap.appendChild(fb);
    };

    wrap.appendChild(img);
    wrap.addEventListener('click',      function() { openModal(d, 'nation'); });
    wrap.addEventListener('mouseenter', function() { this.style.transform='translate(-50%,-50%) scale(1.55)'; this.style.zIndex='40'; });
    wrap.addEventListener('mouseleave', function() { this.style.transform='translate(-50%,-50%) scale(1)';   this.style.zIndex= big ? '15' : '10'; });

    container.appendChild(wrap);
  });
})();

// ── MODAL ────────────────────────────────────────────────────
function openModal(team, mode) {
  const el = id => document.getElementById(id);
  el('m-flag-img').src   = flagUrl(team.code, 160);
  el('m-flag-img').alt   = team.name;
  el('m-flag-img').style.display = 'block';
  el('m-name').textContent  = team.name;
  el('m-conf').textContent  = team.conf;
  el('m-group').textContent = 'Group ' + team.group;
  el('m-host').style.display = team.host ? 'flex' : 'none';

  const showNation = (mode === 'nation');
  el('m-stats-section').style.display  = showNation ? 'none'  : 'block';
  el('m-nation-section').style.display = showNation ? 'block' : 'none';

  if (!showNation) {
    el('m-best').textContent          = team.best;
    el('m-rank').textContent          = '#' + team.fifaRank;
    el('m-times').textContent         = team.times;
    el('m-last-achieved').textContent = team.lastAchieved;
    el('m-lastwc').textContent        = team.lastWC;
  } else {
    const extra = TEAM_EXTRA[team.code] || {};
    el('m-pop').textContent              = extra.pop             || '—';
    el('m-wc-apps').textContent          = extra.wcApps          || '—';
    el('m-football-fact').textContent    = extra.footballFact    || '—';
    el('m-nonfootball-fact').textContent = extra.nonFootballFact || '—';
  }

  el('modal').classList.add('open');
  el('modal').querySelector('.modal').scrollTop = 0;
}

function openTeamByName(name) {
  const team = TEAMS.find(t => t.name === name);
  if (team) openModal(team);
}

function closeModal() { document.getElementById('modal').classList.remove('open'); }
document.getElementById('modal').addEventListener('click', e => { if (e.target === document.getElementById('modal')) closeModal(); });
document.addEventListener('keydown', function(e) { if (e.key === 'Escape') { closeModal(); closeHostModal(); } });

// ── FORM TOGGLE ──────────────────────────────────────────────
let isReg = true;
document.getElementById('toggle-link').addEventListener('click', e => {
  e.preventDefault();
  isReg = !isReg;
  document.getElementById('form-register').style.display = isReg ? 'block' : 'none';
  document.getElementById('form-login').style.display    = isReg ? 'none'  : 'block';
  document.getElementById('form-title').textContent = isReg ? 'Create Account' : 'Welcome Back';
  document.getElementById('form-sub').textContent   = isReg ? 'Join thousands of fans predicting the 2026 World Cup' : 'Log in to see your predictions and ranking';
  document.getElementById('toggle-text').textContent = isReg ? 'Already have an account? ' : "Don't have an account? ";
  document.getElementById('toggle-link').textContent = isReg ? 'Sign In' : 'Create one';
});
document.getElementById('form-register').addEventListener('submit', async e => {
  e.preventDefault();
  const u  = document.getElementById('reg-username').value.trim();
  const em = document.getElementById('reg-email').value.trim();
  const pw = document.getElementById('reg-password').value;
  if (!u||!em||!pw) { showToast('Please fill in all fields','error'); return; }
  if (pw.length<8)  { showToast('Password must be at least 8 characters','error'); return; }
  const btn = e.target.querySelector('button[type="submit"]');
  btn.disabled = true; btn.textContent = 'Creating account…';
  const { error } = await _supabase.auth.signUp({
    email: em, password: pw, options: { data: { username: u } }
  });
  btn.disabled = false; btn.textContent = 'Create Account →';
  if (error) { showToast(error.message, 'error'); return; }
  showToast('🎉 Account created! Check your email to confirm.', 'success');
  e.target.reset();
});

document.getElementById('form-login').addEventListener('submit', async e => {
  e.preventDefault();
  const em = document.getElementById('login-email').value.trim();
  const pw = document.getElementById('login-password').value;
  if (!em||!pw) { showToast('Please fill in all fields','error'); return; }
  const btn = e.target.querySelector('button[type="submit"]');
  btn.disabled = true; btn.textContent = 'Logging in…';
  const { error } = await _supabase.auth.signInWithPassword({ email: em, password: pw });
  btn.disabled = false; btn.textContent = 'Login →';
  if (error) { showToast(error.message, 'error'); return; }
  showToast('✓ Welcome back!', 'success');
  setTimeout(() => window.location.href = 'dashboard.html', 800);
});

// ── HOST SCHEDULE DATA + MODAL (wired via addEventListener) ──
const HOST_SCHEDULES = {
  'Mexico': {
    flag:'🇲🇽', code:'mx', cities:3, totalGames:13,
    cityList:'📍 Mexico City · Guadalajara · Monterrey',
    games:[
      { phase:'group', round:'Group A · MD1', date:'Thu, Jun 11', idt:'22:00', idtDate:'Jun 11',     home:'Mexico',       hCode:'mx', away:'South Africa', aCode:'za', venue:'Estadio Azteca', city:'Mexico City',  capacity:'87,500' },
      { phase:'group', round:'Group A · MD1', date:'Fri, Jun 12', idt:'00:00', idtDate:'Jun 13 ⁺¹', home:'South Korea',  hCode:'kr', away:'UEFA PO-D',    aCode:null, venue:'Estadio BBVA',   city:'Monterrey',    capacity:'53,500' },
      { phase:'group', round:'Group A · MD2', date:'Tue, Jun 17', idt:'21:00', idtDate:'Jun 17',     home:'South Africa', hCode:'za', away:'UEFA PO-D',    aCode:null, venue:'Estadio Azteca', city:'Mexico City',  capacity:'87,500' },
      { phase:'group', round:'Group A · MD2', date:'Thu, Jun 18', idt:'06:00', idtDate:'Jun 19 ⁺¹', home:'Mexico',       hCode:'mx', away:'South Korea',  aCode:'kr', venue:'Estadio Akron',  city:'Guadalajara',  capacity:'49,850' },
      { phase:'group', round:'Group A · MD3', date:'Wed, Jun 24', idt:'04:00', idtDate:'Jun 25 ⁺¹', home:'Mexico',       hCode:'mx', away:'UEFA PO-D',    aCode:null, venue:'Estadio Azteca', city:'Mexico City',  capacity:'87,500' },
      { phase:'group', round:'Group A · MD3', date:'Wed, Jun 24', idt:'04:00', idtDate:'Jun 25 ⁺¹', home:'South Africa', hCode:'za', away:'South Korea',  aCode:'kr', venue:'Estadio BBVA',   city:'Monterrey',    capacity:'53,500' },
      { phase:'knockout', round:'Round of 32', date:'Mon, Jun 30', idt:'TBD', idtDate:'', home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'Estadio Azteca', city:'Mexico City',  capacity:'87,500' },
      { phase:'knockout', round:'Round of 32', date:'Tue, Jul 1',  idt:'TBD', idtDate:'', home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'Estadio BBVA',   city:'Monterrey',    capacity:'53,500' },
      { phase:'knockout', round:'Round of 16', date:'Mon, Jul 7',  idt:'TBD', idtDate:'', home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'Estadio Azteca', city:'Mexico City',  capacity:'87,500' },
      { phase:'knockout', round:'Round of 16', date:'Tue, Jul 8',  idt:'TBD', idtDate:'', home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'Estadio Akron',  city:'Guadalajara',  capacity:'49,850' },
      { phase:'knockout', round:'Quarter-Final', date:'Sat, Jul 12', idt:'TBD', idtDate:'', home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'Estadio Azteca', city:'Mexico City',  capacity:'87,500' },
      { phase:'knockout', round:'Quarter-Final', date:'Sun, Jul 13', idt:'TBD', idtDate:'', home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'Estadio BBVA',   city:'Monterrey',    capacity:'53,500' },
      { phase:'knockout', round:'Quarter-Final', date:'Mon, Jul 14', idt:'TBD', idtDate:'', home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'Estadio Akron',  city:'Guadalajara',  capacity:'49,850' },
    ]
  },
  'Canada': {
    flag:'🇨🇦', code:'ca', cities:2, totalGames:13,
    cityList:'📍 Toronto · Vancouver',
    games:[
      { phase:'group', round:'Group B · MD1', date:'Fri, Jun 12', idt:'22:00', idtDate:'Jun 12',     home:'Canada',      hCode:'ca', away:'UEFA PO-A',   aCode:null, venue:'BMO Field', city:'Toronto',    capacity:'45,000' },
      { phase:'group', round:'Group B · MD1', date:'Fri, Jun 12', idt:'01:00', idtDate:'Jun 13 ⁺¹', home:'Qatar',       hCode:'qa', away:'Switzerland', aCode:'ch', venue:'BC Place',  city:'Vancouver',  capacity:'54,500' },
      { phase:'group', round:'Group B · MD2', date:'Tue, Jun 17', idt:'22:00', idtDate:'Jun 17',     home:'Switzerland', hCode:'ch', away:'UEFA PO-A',   aCode:null, venue:'BMO Field', city:'Toronto',    capacity:'45,000' },
      { phase:'group', round:'Group B · MD2', date:'Wed, Jun 18', idt:'01:00', idtDate:'Jun 19 ⁺¹', home:'Canada',      hCode:'ca', away:'Qatar',       aCode:'qa', venue:'BC Place',  city:'Vancouver',  capacity:'54,500' },
      { phase:'group', round:'Group B · MD3', date:'Wed, Jun 24', idt:'22:00', idtDate:'Jun 24',     home:'Qatar',       hCode:'qa', away:'UEFA PO-A',   aCode:null, venue:'BMO Field', city:'Toronto',    capacity:'45,000' },
      { phase:'group', round:'Group B · MD3', date:'Wed, Jun 24', idt:'22:00', idtDate:'Jun 24',     home:'Canada',      hCode:'ca', away:'Switzerland', aCode:'ch', venue:'BC Place',  city:'Vancouver',  capacity:'54,500' },
      { phase:'knockout', round:'Round of 32', date:'Mon, Jun 29', idt:'TBD', idtDate:'', home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'BC Place',  city:'Vancouver', capacity:'54,500' },
      { phase:'knockout', round:'Round of 32', date:'Tue, Jun 30', idt:'TBD', idtDate:'', home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'BMO Field', city:'Toronto',   capacity:'45,000' },
      { phase:'knockout', round:'Round of 16', date:'Sun, Jul 6',  idt:'TBD', idtDate:'', home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'BC Place',  city:'Vancouver', capacity:'54,500' },
      { phase:'knockout', round:'Round of 16', date:'Mon, Jul 7',  idt:'TBD', idtDate:'', home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'BMO Field', city:'Toronto',   capacity:'45,000' },
      { phase:'knockout', round:'Quarter-Final', date:'Fri, Jul 11', idt:'TBD', idtDate:'', home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'BC Place',  city:'Vancouver', capacity:'54,500' },
      { phase:'knockout', round:'Quarter-Final', date:'Sat, Jul 12', idt:'TBD', idtDate:'', home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'BMO Field', city:'Toronto',   capacity:'45,000' },
      { phase:'knockout', round:'Quarter-Final', date:'Sun, Jul 13', idt:'TBD', idtDate:'', home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'BC Place',  city:'Vancouver', capacity:'54,500' },
    ]
  },
  'United States': {
    flag:'🇺🇸', code:'us', cities:11, totalGames:78,
    cityList:'📍 New York/NJ · Los Angeles · Dallas · Seattle · San Francisco · Miami · Kansas City · Boston · Philadelphia · Atlanta · Houston',
    games:[
      // ── GROUP A ──
      { phase:'group', round:'Group A · MD2', date:'Thu, Jun 18', idt:'19:00', idtDate:'Jun 18',     home:'UEFA PO-D',     hCode:null,     away:'South Africa',  aCode:'za',     venue:'Mercedes-Benz Stadium',   city:'Atlanta, GA',       capacity:'71,000' },
      // ── GROUP B ──
      { phase:'group', round:'Group B · MD1', date:'Sat, Jun 13', idt:'22:00', idtDate:'Jun 13',     home:'Qatar',         hCode:'qa',     away:'Switzerland',   aCode:'ch',     venue:"Levi's Stadium",          city:'Santa Clara, CA',   capacity:'68,500' },
      { phase:'group', round:'Group B · MD2', date:'Thu, Jun 18', idt:'22:00', idtDate:'Jun 18',     home:'Switzerland',   hCode:'ch',     away:'UEFA PO-A',     aCode:null,     venue:'SoFi Stadium',            city:'Inglewood, CA',     capacity:'70,240' },
      { phase:'group', round:'Group B · MD3', date:'Wed, Jun 24', idt:'22:00', idtDate:'Jun 24',     home:'UEFA PO-A',     hCode:null,     away:'Qatar',         aCode:'qa',     venue:'Lumen Field',             city:'Seattle, WA',       capacity:'68,740' },
      // ── GROUP C ──
      { phase:'group', round:'Group C · MD1', date:'Sat, Jun 13', idt:'01:00', idtDate:'Jun 14 ⁺¹', home:'Brazil',        hCode:'br',     away:'Morocco',       aCode:'ma',     venue:'MetLife Stadium',         city:'E. Rutherford, NJ', capacity:'82,500' },
      { phase:'group', round:'Group C · MD1', date:'Sat, Jun 13', idt:'04:00', idtDate:'Jun 14 ⁺¹', home:'Haiti',         hCode:'ht',     away:'Scotland',      aCode:'gb-sct', venue:'Gillette Stadium',        city:'Foxborough, MA',    capacity:'65,878' },
      { phase:'group', round:'Group C · MD2', date:'Thu, Jun 19', idt:'01:00', idtDate:'Jun 20 ⁺¹', home:'Scotland',      hCode:'gb-sct', away:'Morocco',       aCode:'ma',     venue:'Gillette Stadium',        city:'Foxborough, MA',    capacity:'65,878' },
      { phase:'group', round:'Group C · MD2', date:'Thu, Jun 19', idt:'04:00', idtDate:'Jun 20 ⁺¹', home:'Brazil',        hCode:'br',     away:'Haiti',         aCode:'ht',     venue:'Lincoln Financial Field',  city:'Philadelphia, PA',  capacity:'69,796' },
      { phase:'group', round:'Group C · MD3', date:'Wed, Jun 24', idt:'01:00', idtDate:'Jun 25 ⁺¹', home:'Scotland',      hCode:'gb-sct', away:'Brazil',        aCode:'br',     venue:'Hard Rock Stadium',       city:'Miami Gardens, FL', capacity:'64,767' },
      { phase:'group', round:'Group C · MD3', date:'Wed, Jun 24', idt:'01:00', idtDate:'Jun 25 ⁺¹', home:'Morocco',       hCode:'ma',     away:'Haiti',         aCode:'ht',     venue:'Mercedes-Benz Stadium',   city:'Atlanta, GA',       capacity:'71,000' },
      // ── GROUP D ──
      { phase:'group', round:'Group D · MD1', date:'Fri, Jun 12', idt:'04:00', idtDate:'Jun 13 ⁺¹', home:'United States', hCode:'us',     away:'Paraguay',      aCode:'py',     venue:'SoFi Stadium',            city:'Inglewood, CA',     capacity:'70,240' },
      { phase:'group', round:'Group D · MD2', date:'Thu, Jun 19', idt:'22:00', idtDate:'Jun 19',     home:'United States', hCode:'us',     away:'Australia',     aCode:'au',     venue:'Lumen Field',             city:'Seattle, WA',       capacity:'68,740' },
      { phase:'group', round:'Group D · MD2', date:'Thu, Jun 19', idt:'07:00', idtDate:'Jun 20 ⁺¹', home:'UEFA PO-C',     hCode:null,     away:'Paraguay',      aCode:'py',     venue:"Levi's Stadium",          city:'Santa Clara, CA',   capacity:'68,500' },
      { phase:'group', round:'Group D · MD3', date:'Thu, Jun 25', idt:'05:00', idtDate:'Jun 26 ⁺¹', home:'UEFA PO-C',     hCode:null,     away:'United States', aCode:'us',     venue:'SoFi Stadium',            city:'Inglewood, CA',     capacity:'70,240' },
      { phase:'group', round:'Group D · MD3', date:'Thu, Jun 25', idt:'05:00', idtDate:'Jun 26 ⁺¹', home:'Paraguay',      hCode:'py',     away:'Australia',     aCode:'au',     venue:"Levi's Stadium",          city:'Santa Clara, CA',   capacity:'68,500' },
      // ── GROUP E ──
      { phase:'group', round:'Group E · MD1', date:'Sun, Jun 14', idt:'20:00', idtDate:'Jun 14',     home:'Germany',       hCode:'de',     away:'Curaçao',       aCode:'cw',     venue:'NRG Stadium',             city:'Houston, TX',       capacity:'72,220' },
      { phase:'group', round:'Group E · MD1', date:'Sun, Jun 14', idt:'02:00', idtDate:'Jun 15 ⁺¹', home:'Ivory Coast',   hCode:'ci',     away:'Ecuador',       aCode:'ec',     venue:'Lincoln Financial Field',  city:'Philadelphia, PA',  capacity:'69,796' },
      { phase:'group', round:'Group E · MD2', date:'Sat, Jun 20', idt:'03:00', idtDate:'Jun 21 ⁺¹', home:'Ecuador',       hCode:'ec',     away:'Curaçao',       aCode:'cw',     venue:'Arrowhead Stadium',       city:'Kansas City, MO',   capacity:'76,416' },
      { phase:'group', round:'Group E · MD3', date:'Thu, Jun 25', idt:'23:00', idtDate:'Jun 25',     home:'Ecuador',       hCode:'ec',     away:'Germany',       aCode:'de',     venue:'MetLife Stadium',         city:'E. Rutherford, NJ', capacity:'82,500' },
      { phase:'group', round:'Group E · MD3', date:'Thu, Jun 25', idt:'23:00', idtDate:'Jun 25',     home:'Curaçao',       hCode:'cw',     away:'Ivory Coast',   aCode:'ci',     venue:'Lincoln Financial Field',  city:'Philadelphia, PA',  capacity:'69,796' },
      // ── GROUP F ──
      { phase:'group', round:'Group F · MD1', date:'Sun, Jun 14', idt:'23:00', idtDate:'Jun 14',     home:'Netherlands',   hCode:'nl',     away:'Japan',         aCode:'jp',     venue:'AT&T Stadium',            city:'Arlington, TX',     capacity:'80,000' },
      { phase:'group', round:'Group F · MD2', date:'Sat, Jun 20', idt:'20:00', idtDate:'Jun 20',     home:'Netherlands',   hCode:'nl',     away:'UEFA PO-B',     aCode:null,     venue:'NRG Stadium',             city:'Houston, TX',       capacity:'72,220' },
      { phase:'group', round:'Group F · MD3', date:'Thu, Jun 25', idt:'02:00', idtDate:'Jun 26 ⁺¹', home:'Japan',         hCode:'jp',     away:'UEFA PO-B',     aCode:null,     venue:'AT&T Stadium',            city:'Arlington, TX',     capacity:'80,000' },
      { phase:'group', round:'Group F · MD3', date:'Thu, Jun 25', idt:'02:00', idtDate:'Jun 26 ⁺¹', home:'Tunisia',       hCode:'tn',     away:'Netherlands',   aCode:'nl',     venue:'Arrowhead Stadium',       city:'Kansas City, MO',   capacity:'76,416' },
      // ── GROUP G ──
      { phase:'group', round:'Group G · MD1', date:'Mon, Jun 15', idt:'22:00', idtDate:'Jun 15',     home:'Belgium',       hCode:'be',     away:'Egypt',         aCode:'eg',     venue:'Lumen Field',             city:'Seattle, WA',       capacity:'68,740' },
      { phase:'group', round:'Group G · MD1', date:'Mon, Jun 15', idt:'04:00', idtDate:'Jun 16 ⁺¹', home:'Iran',          hCode:'ir',     away:'New Zealand',   aCode:'nz',     venue:'SoFi Stadium',            city:'Inglewood, CA',     capacity:'70,240' },
      { phase:'group', round:'Group G · MD2', date:'Sun, Jun 21', idt:'22:00', idtDate:'Jun 21',     home:'Belgium',       hCode:'be',     away:'Iran',          aCode:'ir',     venue:'SoFi Stadium',            city:'Inglewood, CA',     capacity:'70,240' },
      { phase:'group', round:'Group G · MD3', date:'Fri, Jun 26', idt:'06:00', idtDate:'Jun 27 ⁺¹', home:'Egypt',         hCode:'eg',     away:'Iran',          aCode:'ir',     venue:'Lumen Field',             city:'Seattle, WA',       capacity:'68,740' },
      // ── GROUP H ──
      { phase:'group', round:'Group H · MD1', date:'Mon, Jun 15', idt:'19:00', idtDate:'Jun 15',     home:'Spain',         hCode:'es',     away:'Cape Verde',    aCode:'cv',     venue:'Mercedes-Benz Stadium',   city:'Atlanta, GA',       capacity:'71,000' },
      { phase:'group', round:'Group H · MD1', date:'Mon, Jun 15', idt:'01:00', idtDate:'Jun 16 ⁺¹', home:'Saudi Arabia',  hCode:'sa',     away:'Uruguay',       aCode:'uy',     venue:'Hard Rock Stadium',       city:'Miami Gardens, FL', capacity:'64,767' },
      { phase:'group', round:'Group H · MD2', date:'Sun, Jun 21', idt:'19:00', idtDate:'Jun 21',     home:'Spain',         hCode:'es',     away:'Saudi Arabia',  aCode:'sa',     venue:'Mercedes-Benz Stadium',   city:'Atlanta, GA',       capacity:'71,000' },
      { phase:'group', round:'Group H · MD2', date:'Sun, Jun 21', idt:'01:00', idtDate:'Jun 22 ⁺¹', home:'Uruguay',       hCode:'uy',     away:'Cape Verde',    aCode:'cv',     venue:'Hard Rock Stadium',       city:'Miami Gardens, FL', capacity:'64,767' },
      { phase:'group', round:'Group H · MD3', date:'Fri, Jun 26', idt:'03:00', idtDate:'Jun 27 ⁺¹', home:'Cape Verde',    hCode:'cv',     away:'Saudi Arabia',  aCode:'sa',     venue:'NRG Stadium',             city:'Houston, TX',       capacity:'72,220' },
      // ── GROUP I ──
      { phase:'group', round:'Group I · MD1', date:'Tue, Jun 16', idt:'22:00', idtDate:'Jun 16',     home:'France',        hCode:'fr',     away:'Senegal',       aCode:'sn',     venue:'MetLife Stadium',         city:'E. Rutherford, NJ', capacity:'82,500' },
      { phase:'group', round:'Group I · MD1', date:'Tue, Jun 16', idt:'01:00', idtDate:'Jun 17 ⁺¹', home:'IC PO-2',       hCode:null,     away:'Norway',        aCode:'no',     venue:'Gillette Stadium',        city:'Foxborough, MA',    capacity:'65,878' },
      { phase:'group', round:'Group I · MD2', date:'Sun, Jun 22', idt:'00:00', idtDate:'Jun 23 ⁺¹', home:'France',        hCode:'fr',     away:'IC PO-2',       aCode:null,     venue:'Lincoln Financial Field',  city:'Philadelphia, PA',  capacity:'69,796' },
      { phase:'group', round:'Group I · MD2', date:'Sun, Jun 22', idt:'03:00', idtDate:'Jun 23 ⁺¹', home:'Norway',        hCode:'no',     away:'Senegal',       aCode:'sn',     venue:'MetLife Stadium',         city:'E. Rutherford, NJ', capacity:'82,500' },
      { phase:'group', round:'Group I · MD3', date:'Fri, Jun 26', idt:'22:00', idtDate:'Jun 26',     home:'Norway',        hCode:'no',     away:'France',        aCode:'fr',     venue:'Gillette Stadium',        city:'Foxborough, MA',    capacity:'65,878' },
      // ── GROUP J ──
      { phase:'group', round:'Group J · MD1', date:'Tue, Jun 16', idt:'04:00', idtDate:'Jun 17 ⁺¹', home:'Argentina',     hCode:'ar',     away:'Algeria',       aCode:'dz',     venue:'Arrowhead Stadium',       city:'Kansas City, MO',   capacity:'76,416' },
      { phase:'group', round:'Group J · MD1', date:'Tue, Jun 16', idt:'07:00', idtDate:'Jun 17 ⁺¹', home:'Austria',       hCode:'at',     away:'Jordan',        aCode:'jo',     venue:"Levi's Stadium",          city:'Santa Clara, CA',   capacity:'68,500' },
      { phase:'group', round:'Group J · MD2', date:'Sun, Jun 22', idt:'20:00', idtDate:'Jun 22',     home:'Argentina',     hCode:'ar',     away:'Austria',       aCode:'at',     venue:'AT&T Stadium',            city:'Arlington, TX',     capacity:'80,000' },
      { phase:'group', round:'Group J · MD2', date:'Sun, Jun 22', idt:'06:00', idtDate:'Jun 23 ⁺¹', home:'Jordan',        hCode:'jo',     away:'Algeria',       aCode:'dz',     venue:"Levi's Stadium",          city:'Santa Clara, CA',   capacity:'68,500' },
      { phase:'group', round:'Group J · MD3', date:'Sat, Jun 27', idt:'05:00', idtDate:'Jun 28 ⁺¹', home:'Algeria',       hCode:'dz',     away:'Austria',       aCode:'at',     venue:'Arrowhead Stadium',       city:'Kansas City, MO',   capacity:'76,416' },
      { phase:'group', round:'Group J · MD3', date:'Sat, Jun 27', idt:'05:00', idtDate:'Jun 28 ⁺¹', home:'Jordan',        hCode:'jo',     away:'Argentina',     aCode:'ar',     venue:'AT&T Stadium',            city:'Arlington, TX',     capacity:'80,000' },
      // ── GROUP K ──
      { phase:'group', round:'Group K · MD1', date:'Tue, Jun 17', idt:'20:00', idtDate:'Jun 17',     home:'Portugal',      hCode:'pt',     away:'IC PO-1',       aCode:null,     venue:'NRG Stadium',             city:'Houston, TX',       capacity:'72,220' },
      { phase:'group', round:'Group K · MD2', date:'Mon, Jun 23', idt:'20:00', idtDate:'Jun 23',     home:'Portugal',      hCode:'pt',     away:'Uzbekistan',    aCode:'uz',     venue:'NRG Stadium',             city:'Houston, TX',       capacity:'72,220' },
      { phase:'group', round:'Group K · MD3', date:'Sat, Jun 27', idt:'02:30', idtDate:'Jun 28 ⁺¹', home:'Colombia',      hCode:'co',     away:'Portugal',      aCode:'pt',     venue:'Hard Rock Stadium',       city:'Miami Gardens, FL', capacity:'64,767' },
      { phase:'group', round:'Group K · MD3', date:'Sat, Jun 27', idt:'02:30', idtDate:'Jun 28 ⁺¹', home:'IC PO-1',       hCode:null,     away:'Uzbekistan',    aCode:'uz',     venue:'Mercedes-Benz Stadium',   city:'Atlanta, GA',       capacity:'71,000' },
      // ── GROUP L ──
      { phase:'group', round:'Group L · MD1', date:'Tue, Jun 17', idt:'23:00', idtDate:'Jun 17',     home:'England',       hCode:'gb-eng', away:'Croatia',       aCode:'hr',     venue:'AT&T Stadium',            city:'Arlington, TX',     capacity:'80,000' },
      { phase:'group', round:'Group L · MD2', date:'Mon, Jun 23', idt:'23:00', idtDate:'Jun 23',     home:'England',       hCode:'gb-eng', away:'Ghana',         aCode:'gh',     venue:'Gillette Stadium',        city:'Foxborough, MA',    capacity:'65,878' },
      { phase:'group', round:'Group L · MD3', date:'Sat, Jun 27', idt:'00:00', idtDate:'Jun 28 ⁺¹', home:'Panama',        hCode:'pa',     away:'England',       aCode:'gb-eng', venue:'MetLife Stadium',         city:'E. Rutherford, NJ', capacity:'82,500' },
      { phase:'group', round:'Group L · MD3', date:'Sat, Jun 27', idt:'00:00', idtDate:'Jun 28 ⁺¹', home:'Croatia',       hCode:'hr',     away:'Ghana',         aCode:'gh',     venue:'Lincoln Financial Field',  city:'Philadelphia, PA',  capacity:'69,796' },
      // ── ROUND OF 32 (12 games) ──
      { phase:'knockout', round:'Round of 32', date:'Sun, Jun 28', idt:'22:00', idtDate:'Jun 28',     home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'SoFi Stadium',            city:'Inglewood, CA',     capacity:'70,240' },
      { phase:'knockout', round:'Round of 32', date:'Mon, Jun 29', idt:'20:00', idtDate:'Jun 29',     home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'NRG Stadium',             city:'Houston, TX',       capacity:'72,220' },
      { phase:'knockout', round:'Round of 32', date:'Mon, Jun 29', idt:'23:30', idtDate:'Jun 29',     home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'Gillette Stadium',        city:'Foxborough, MA',    capacity:'65,878' },
      { phase:'knockout', round:'Round of 32', date:'Tue, Jun 30', idt:'20:00', idtDate:'Jun 30',     home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'AT&T Stadium',            city:'Arlington, TX',     capacity:'80,000' },
      { phase:'knockout', round:'Round of 32', date:'Tue, Jun 30', idt:'00:00', idtDate:'Jul 1 ⁺¹',  home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'MetLife Stadium',         city:'E. Rutherford, NJ', capacity:'82,500' },
      { phase:'knockout', round:'Round of 32', date:'Wed, Jul 1',  idt:'19:00', idtDate:'Jul 1',      home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'Mercedes-Benz Stadium',   city:'Atlanta, GA',       capacity:'71,000' },
      { phase:'knockout', round:'Round of 32', date:'Wed, Jul 1',  idt:'23:00', idtDate:'Jul 1',      home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'Lumen Field',             city:'Seattle, WA',       capacity:'68,740' },
      { phase:'knockout', round:'Round of 32', date:'Wed, Jul 1',  idt:'03:00', idtDate:'Jul 2 ⁺¹',  home:'TBD', hCode:null, away:'TBD', aCode:null, venue:"Levi's Stadium",          city:'Santa Clara, CA',   capacity:'68,500' },
      { phase:'knockout', round:'Round of 32', date:'Thu, Jul 2',  idt:'22:00', idtDate:'Jul 2',      home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'SoFi Stadium',            city:'Inglewood, CA',     capacity:'70,240' },
      { phase:'knockout', round:'Round of 32', date:'Fri, Jul 3',  idt:'21:00', idtDate:'Jul 3',      home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'AT&T Stadium',            city:'Arlington, TX',     capacity:'80,000' },
      { phase:'knockout', round:'Round of 32', date:'Fri, Jul 3',  idt:'01:00', idtDate:'Jul 4 ⁺¹',  home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'Hard Rock Stadium',       city:'Miami Gardens, FL', capacity:'64,767' },
      { phase:'knockout', round:'Round of 32', date:'Fri, Jul 3',  idt:'04:30', idtDate:'Jul 4 ⁺¹',  home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'Arrowhead Stadium',       city:'Kansas City, MO',   capacity:'76,416' },
      // ── ROUND OF 16 (6 games) ──
      { phase:'knockout', round:'Round of 16', date:'Sat, Jul 4',  idt:'20:00', idtDate:'Jul 4',      home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'NRG Stadium',             city:'Houston, TX',       capacity:'72,220' },
      { phase:'knockout', round:'Round of 16', date:'Sat, Jul 4',  idt:'00:00', idtDate:'Jul 5 ⁺¹',  home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'Lincoln Financial Field',  city:'Philadelphia, PA',  capacity:'69,796' },
      { phase:'knockout', round:'Round of 16', date:'Sun, Jul 5',  idt:'23:00', idtDate:'Jul 5',      home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'MetLife Stadium',         city:'E. Rutherford, NJ', capacity:'82,500' },
      { phase:'knockout', round:'Round of 16', date:'Mon, Jul 6',  idt:'22:00', idtDate:'Jul 6',      home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'AT&T Stadium',            city:'Arlington, TX',     capacity:'80,000' },
      { phase:'knockout', round:'Round of 16', date:'Mon, Jul 6',  idt:'03:00', idtDate:'Jul 7 ⁺¹',  home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'Lumen Field',             city:'Seattle, WA',       capacity:'68,740' },
      { phase:'knockout', round:'Round of 16', date:'Tue, Jul 7',  idt:'19:00', idtDate:'Jul 7',      home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'Mercedes-Benz Stadium',   city:'Atlanta, GA',       capacity:'71,000' },
      // ── QUARTER-FINALS (4 games) ──
      { phase:'knockout', round:'Quarter-Final', date:'Thu, Jul 9',  idt:'23:00', idtDate:'Jul 9',      home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'Gillette Stadium',        city:'Foxborough, MA',    capacity:'65,878' },
      { phase:'knockout', round:'Quarter-Final', date:'Fri, Jul 10', idt:'22:00', idtDate:'Jul 10',     home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'SoFi Stadium',            city:'Inglewood, CA',     capacity:'70,240' },
      { phase:'knockout', round:'Quarter-Final', date:'Sat, Jul 11', idt:'00:00', idtDate:'Jul 12 ⁺¹', home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'Hard Rock Stadium',       city:'Miami Gardens, FL', capacity:'64,767' },
      { phase:'knockout', round:'Quarter-Final', date:'Sat, Jul 11', idt:'04:00', idtDate:'Jul 12 ⁺¹', home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'Arrowhead Stadium',       city:'Kansas City, MO',   capacity:'76,416' },
      // ── SEMI-FINALS (2 games) ──
      { phase:'knockout', round:'Semi-Final',    date:'Tue, Jul 14', idt:'22:00', idtDate:'Jul 14',     home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'AT&T Stadium',            city:'Arlington, TX',     capacity:'80,000' },
      { phase:'knockout', round:'Semi-Final',    date:'Wed, Jul 15', idt:'22:00', idtDate:'Jul 15',     home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'Mercedes-Benz Stadium',   city:'Atlanta, GA',       capacity:'71,000' },
      // ── 3RD PLACE + FINAL ──
      { phase:'knockout', round:'🥉 3rd Place',  date:'Sat, Jul 18', idt:'00:00', idtDate:'Jul 19 ⁺¹', home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'Hard Rock Stadium',       city:'Miami Gardens, FL', capacity:'64,767' },
      { phase:'knockout', round:'🏆 Final',      date:'Sun, Jul 19', idt:'22:00', idtDate:'Jul 19',     home:'TBD', hCode:null, away:'TBD', aCode:null, venue:'MetLife Stadium',         city:'E. Rutherford, NJ', capacity:'82,500' },
    ]
  }
};

// ── HOST SCHEDULE MODAL ──────────────────────────────────────
function openHostSchedule(name) {
  var d = HOST_SCHEDULES[name];
  if (!d) return;

  document.getElementById('hs-flag-img').src = 'https://flagcdn.com/w160/' + d.code + '.png';
  document.getElementById('hs-flag-img').style.display = 'block';
  document.getElementById('hs-country-name').textContent = name;
  document.getElementById('hs-stats-row').innerHTML = '🏠 Host Nation &nbsp;·&nbsp; ' + d.cities + ' cities &nbsp;·&nbsp; ' + d.totalGames + ' matches';
  document.getElementById('hs-cities-row').textContent = d.cityList;

  var tbody = '';
  var lastPhase = '';
  for (var i = 0; i < d.games.length; i++) {
    var g = d.games[i];
    if (g.phase !== lastPhase) {
      var icon = g.phase === 'group' ? '⚽' : '🏆';
      var label = g.phase === 'group' ? 'Group Stage' : 'Knockout Rounds';
      tbody += '<tr class="hs-phase-hdr"><td colspan="6">' + icon + '&nbsp; ' + label + '</td></tr>';
      lastPhase = g.phase;
    }

    var hf = g.hCode
      ? '<img class="td-flag" src="https://flagcdn.com/w40/' + g.hCode + '.png" alt="">'
      : '<div class="td-flag-ph"></div>';
    var af = g.aCode
      ? '<img class="td-flag" src="https://flagcdn.com/w40/' + g.aCode + '.png" alt="">'
      : '<div class="td-flag-ph"></div>';

    var timeCell = (g.idt === 'TBD' || g.idt === 'Various')
      ? '<span class="td-tbd">' + g.idt + '</span>'
      : '<span class="td-time">' + g.idt + '</span>' + (g.idtDate ? '<br><span style="font-size:.6rem;color:var(--muted)">' + g.idtDate + '</span>' : '');

    tbody += '<tr>'
      + '<td><span class="hs-tag ' + g.phase + '">' + g.round + '</span></td>'
      + '<td><div class="td-teams">' + hf + '<span>' + g.home + '</span><span class="td-vs">vs</span>' + af + '<span>' + g.away + '</span></div></td>'
      + '<td>' + g.venue + '<br><span style="font-size:.62rem;color:var(--muted)">' + g.city + '</span></td>'
      + '<td style="color:var(--muted);white-space:nowrap">' + (g.capacity || '—') + '</td>'
      + '<td style="white-space:nowrap;font-size:.78rem;color:var(--muted)">' + g.date + '</td>'
      + '<td>' + timeCell + '</td>'
      + '</tr>';
  }

  document.getElementById('hs-games-container').innerHTML =
    '<div class="hs-table-wrap">'
    + '<table class="hs-table"><thead><tr>'
    + '<th>Stage</th><th>Teams</th><th>Stadium</th><th>Cap.</th><th>Date</th><th>Time (ISR)</th>'
    + '</tr></thead><tbody>' + tbody + '</tbody></table></div>';

  var ov = document.getElementById('host-modal');
  ov.classList.add('open');
  ov.querySelector('.modal').scrollTop = 0;
}

function closeHostModal() {
  document.getElementById('host-modal').classList.remove('open');
}

document.getElementById('host-modal').addEventListener('click', function(e) {
  if (e.target === document.getElementById('host-modal')) closeHostModal();
});

document.querySelectorAll('.host-card').forEach(function(card) {
  card.addEventListener('click', function() {
    openHostSchedule(card.dataset.host);
  });
});

// ── TOAST ────────────────────────────────────────────────────
function showToast(msg, type='success') {
  const t = document.getElementById('toast');
  document.getElementById('toast-msg').textContent = msg;
  document.getElementById('toast-icon').textContent = type==='success'?'✓':'✕';
  t.className='toast '+type; t.classList.add('show');
  setTimeout(()=>t.classList.remove('show'),3500);
}
