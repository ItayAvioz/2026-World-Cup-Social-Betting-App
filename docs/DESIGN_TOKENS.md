# Design Tokens & Component Patterns

## Fonts
- **Oswald** — headings, numbers, scores, times, nav logo (weights: 300/400/600/700)
- **Inter** — body text, labels, buttons (weights: 300/400/500/600)

```html
<link href="https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;600;700&family=Inter:wght@300;400;500;600&display=swap" rel="stylesheet">
```

## CSS Variables
```css
--bg: #0a0a0a      /* page background */
--bg2: #111111     /* cards, inputs */
--bg3: #1a1a1a     /* elevated cards, modals */
--accent: #f5c518  /* gold — primary highlight */
--green: #2ecc71   /* success, win */
--red: #e74c3c     /* error, loss */
--blue: #3498db    /* info, group stage */
--text: #f0f0f0    /* body text */
--muted: #888888   /* secondary text */
--border: #2a2a2a  /* all borders */
--radius: 12px     /* standard border-radius */
```

## Buttons
```html
<button class="btn btn-gold">Primary</button>
<button class="btn btn-outline">Secondary</button>
<button class="btn btn-gold btn-lg">Large</button>
<button class="btn btn-gold btn-full">Full width</button>
```

## Nav — Landing (index.html)
```html
<nav>
  <div class="nav-logo">⚽ WC2026</div>
  <div class="nav-links">
    <a href="#register-section"><button class="btn btn-outline">Login</button></a>
    <a href="#register-section"><button class="btn btn-gold">Sign Up</button></a>
  </div>
</nav>
```

## Nav — Inner Pages
```html
<nav class="page-nav">
  <button class="page-back" onclick="history.back()">← Back</button>
  <div class="nav-logo">⚽ WC2026</div>
  <div style="width:60px"></div>
</nav>
<div class="page-body" id="page-body">…</div>
```

## Section Labels
```html
<div class="section-pill">Label</div>
<h2 class="section-title">Heading</h2>
<p class="section-desc">Description…</p>
```

## Card
```html
<div style="background:var(--bg3);border:1px solid var(--border);border-radius:var(--radius);padding:1.5rem">
```

## Stats Bar (4-up)
```html
<div class="stats-bar">
  <div class="stat-item"><div class="stat-num">48</div><div class="stat-desc">Teams</div></div>
</div>
```

## Stat Box (2-col grid)
```html
<div class="stat-grid-2">
  <div class="stat-box">
    <div class="stat-box-label">Label</div>
    <div class="stat-box-val gold">Value</div>
  </div>
  <div class="stat-box full">…</div>
</div>
```

## Phase Tags
```html
<span class="hs-tag group">Group A</span>
<span class="hs-tag knockout">Quarter-Final</span>
```

## Section Divider
```html
<div class="phase-divider">Group Stage</div>
```

## Modal
```html
<div class="modal-overlay" id="my-modal">
  <div class="modal">
    <button class="modal-close" onclick="document.getElementById('my-modal').classList.remove('open')">✕</button>
    <!-- content -->
  </div>
</div>
```
Open: `document.getElementById('my-modal').classList.add('open')`

## Toast
```html
<div class="toast" id="toast"><span id="toast-icon">✓</span><span id="toast-msg">Done!</span></div>
```
```js
function showToast(msg, type = 'success') {
  const t = document.getElementById('toast');
  t.className = `toast ${type}`;
  document.getElementById('toast-icon').textContent = type === 'success' ? '✓' : '✕';
  document.getElementById('toast-msg').textContent = msg;
  t.classList.add('show');
  setTimeout(() => t.classList.remove('show'), 3000);
}
```

## Tabs
```html
<div class="team-tabs">
  <button class="team-tab active" onclick="switchTab('overview')">Overview</button>
  <button class="team-tab" onclick="switchTab('games')">Games</button>
</div>
<div id="tab-overview" class="tab-panel active">…</div>
<div id="tab-games" class="tab-panel">…</div>
```

## Flag Images
```js
const flagUrl = (code, w = 40) => `https://flagcdn.com/w${w}/${code}.png`;
// code = ISO 2-letter lowercase: 'us', 'br', 'fr'
```

## Radial Background (hero / page headers)
```css
background: radial-gradient(ellipse 80% 60% at 50% 0%, #1a1000 0%, var(--bg) 70%);
```

## Inner Page Shell Template
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
  <title>Page Title — WC2026</title>
  <link href="https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;600;700&family=Inter:wght@300;400;500;600&display=swap" rel="stylesheet">
  <meta name="theme-color" content="#0a0a0a">
  <meta name="color-scheme" content="dark">
  <link rel="stylesheet" href="css/style.css">
  <style>/* page-specific CSS only */</style>
</head>
<body>
<nav class="page-nav">
  <button class="page-back" onclick="history.back()">← Back</button>
  <div class="nav-logo">⚽ WC2026</div>
  <div style="width:60px"></div>
</nav>
<div class="page-body" id="page-body"></div>
<div class="toast" id="toast"><span id="toast-icon">✓</span><span id="toast-msg">Done!</span></div>
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.js"></script>
<script src="js/supabase.js"></script>
<script>
(async () => {
  const { data: { session } } = await _supabase.auth.getSession();
  if (!session) { window.location.href = 'index.html'; return; }
  init(session);
})();
async function init(session) { /* page logic */ }
</script>
</body>
</html>
```

## Bottom Nav (React app only)
```css
/* Fixed bottom bar — 4 tabs */
.bottom-nav          { position:fixed; bottom:0; left:0; right:0; z-index:200; display:flex; background:rgba(10,10,10,.95); backdrop-filter:blur(12px); border-top:1px solid var(--border); padding-bottom:env(safe-area-inset-bottom); }
.bottom-nav-tab      { flex:1; display:flex; flex-direction:column; align-items:center; justify-content:center; padding:.55rem .25rem; color:var(--muted); text-decoration:none; transition:color .15s; gap:.2rem; }
.bottom-nav-tab.active { color:var(--accent); }
.bottom-nav-icon     { font-size:1.25rem; line-height:1; }
.bottom-nav-label    { font-family:'Inter',sans-serif; font-size:.62rem; font-weight:500; letter-spacing:.3px; }
```

## Group Selector
```css
.group-selector { background:var(--bg2); border:1px solid var(--border); border-radius:8px; color:var(--text); font-family:'Inter',sans-serif; font-size:.9rem; padding:.5rem .9rem; cursor:pointer; outline:none; }
.group-selector:focus { border-color:var(--accent); }
```

## AI Feed Summary Card
```html
<div class="af-card">
  <div class="af-card-header">
    <div class="af-card-date">Monday, Jun 12, 2026</div>
    <div class="af-card-games">3 games</div>
  </div>
  <div class="af-card-content">Summary text here…</div>
  <div class="af-card-footer">Generated at 11:30 PM · Jun 12</div>
</div>
```
State classes: `.af-list` (flex column gap), `.af-empty` + `.af-empty-icon` + `.af-empty-text`, `.af-selector-row` (group selector wrapper), `.af-group-label` (single-group Oswald label), `.af-skeleton` (loading pulse animation)
