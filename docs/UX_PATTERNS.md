# UX Patterns — WorldCup 2026

Reference for the `/ux` skill. Documents spacing rules, interaction patterns, state templates, accessibility rules, and app-specific do/don'ts.

---

## Spacing Grid

Base unit: **8px**. All padding, margin, gap values must be multiples of 4px or 8px.

| Token | Value | Use |
|-------|-------|-----|
| `0.25rem` | 4px | Tight inline spacing |
| `0.5rem` | 8px | Small gaps, icon margins |
| `0.75rem` | 12px | Input padding, compact rows |
| `1rem` | 16px | Standard section padding |
| `1.5rem` | 24px | Card padding, section gaps |
| `2rem` | 32px | Large section spacing |
| `3rem` | 48px | Hero/header vertical padding |

---

## Touch Targets

- Minimum tap target: **48×48px** for all interactive elements
- Buttons in forms: min height `48px`
- List row actions (flag inactive, rename): wrap in a `<button>` with min `44px` height
- Bottom nav tabs: min height `56px` including padding
- Use `padding` to expand small icons to meet the target size — do not rely on the icon size alone

```css
/* ✅ Correct — small icon, adequate target */
.action-btn { padding: 12px; min-width: 44px; min-height: 44px; }

/* ❌ Wrong — icon is 20px, tap area is 20px */
.action-icon { font-size: 20px; cursor: pointer; }
```

---

## Input Font Size

All inputs must have `font-size: 1rem` (16px) minimum — prevents iOS zoom on focus.

```css
/* ✅ Required on all inputs, selects, textareas */
input, select, textarea { font-size: 1rem; }
```

---

## State Patterns

Every data-driven section must handle all 4 states.

### Loading State
Use a skeleton shimmer or a centered spinner — never a blank section.

```html
<!-- Skeleton row (repeat 3–5x) -->
<div class="skeleton-row">
  <div class="skeleton" style="width:40px;height:40px;border-radius:50%"></div>
  <div style="flex:1">
    <div class="skeleton" style="width:60%;height:14px;margin-bottom:6px"></div>
    <div class="skeleton" style="width:40%;height:12px"></div>
  </div>
</div>
```

```css
.skeleton {
  background: linear-gradient(90deg, var(--bg2) 25%, var(--bg3) 50%, var(--bg2) 75%);
  background-size: 200% 100%;
  animation: shimmer 1.4s infinite;
  border-radius: 4px;
}
@keyframes shimmer { 0% { background-position: 200% 0 } 100% { background-position: -200% 0 } }
```

### Error State
Always show a recoverable message. Include a retry action when the failure is transient.

```html
<div class="state-error">
  <div class="state-icon">⚠</div>
  <p>Couldn't load leaderboard.</p>
  <button class="btn btn-outline" onclick="init()">Try again</button>
</div>
```

### Empty State
Friendly message + a clear next action. Never just a blank list.

```html
<!-- No groups -->
<div class="state-empty">
  <div class="state-icon">👥</div>
  <p>You're not in any group yet.</p>
  <a href="groups.html"><button class="btn btn-gold">Join or create a group</button></a>
</div>
```

```html
<!-- No AI summaries yet -->
<div class="state-empty">
  <div class="state-icon">🤖</div>
  <p>No summaries yet. Summaries are generated nightly after games finish.</p>
</div>
```

### Locked State
Show what the user picked (if anything) + a lock indicator. Don't hide the section.

```html
<!-- Locked prediction -->
<div class="prediction-locked">
  <span class="lock-icon">🔒</span>
  <span class="lock-label">Locked — game kicked off</span>
  <!-- Show their pick if exists -->
  <span class="pick-display">Your pick: 2 – 1</span>
</div>
```

```css
.state-empty, .state-error { text-align:center; padding:3rem 1rem; color:var(--muted); }
.state-icon { font-size:2rem; margin-bottom:.75rem; }
.prediction-locked { display:flex; align-items:center; gap:.5rem; color:var(--muted); font-size:.9rem; }
```

---

## Button Loading State

Disable + change text during async calls. Never leave the user guessing if something is happening.

```js
async function handleSubmit(btn) {
  btn.disabled = true;
  const original = btn.textContent;
  btn.textContent = 'Saving…';
  try {
    await doSomething();
    showToast('Saved!');
  } catch (e) {
    showToast(e.message, 'error');
  } finally {
    btn.disabled = false;
    btn.textContent = original;
  }
}
```

---

## Form Validation

Show errors inline under the field — not only via toast.

```html
<div class="field">
  <label for="username">Username</label>
  <input id="username" type="text" class="field-input">
  <span class="field-error" id="username-error"></span>
</div>
```

```js
function setFieldError(id, message) {
  const el = document.getElementById(`${id}-error`);
  el.textContent = message;
  el.style.display = message ? 'block' : 'none';
  document.getElementById(id).classList.toggle('input-error', !!message);
}
```

```css
.field-error { display:none; color:var(--red); font-size:.8rem; margin-top:.25rem; }
.input-error { border-color:var(--red) !important; }
```

---

## Confirm Step for Destructive Actions

Any irreversible action (flag inactive, account delete) must confirm first.

```js
// Inline confirm — swap button text
async function flagInactive(memberId, btn) {
  if (btn.dataset.confirm !== '1') {
    btn.dataset.confirm = '1';
    btn.textContent = 'Sure?';
    setTimeout(() => { btn.dataset.confirm = ''; btn.textContent = 'Mark inactive'; }, 3000);
    return;
  }
  // proceed
}
```

---

## Accessibility Rules

### Semantic HTML
- Use `<button>` for actions, `<a href>` for navigation — never `<div onclick>`
- One `<h1>` per page (page title), then `<h2>` for sections, `<h3>` for sub-sections
- Use `<nav>`, `<main>`, `<section>`, `<article>` landmarks

### Labels
- Every `<input>` has a `<label for="id">` or `aria-label`
- Icon-only buttons: `aria-label="Close"` etc.
- Flags: `<img src="…" alt="Brazil flag">`

### Modal Accessibility
```js
function openModal(id) {
  const modal = document.getElementById(id);
  modal.classList.add('open');
  // Trap focus
  const focusable = modal.querySelectorAll('button, input, select, textarea, a[href]');
  focusable[0]?.focus();
  modal._onKey = (e) => {
    if (e.key === 'Escape') closeModal(id);
  };
  document.addEventListener('keydown', modal._onKey);
}
function closeModal(id) {
  const modal = document.getElementById(id);
  modal.classList.remove('open');
  document.removeEventListener('keydown', modal._onKey);
}
```

### Color + Meaning
- Never use color as the only indicator:
  - ✅ Win: green color + "W" text or ✓ icon
  - ❌ Loss: red color + "L" text or ✗ icon
  - ❌ Wrong: red border + error message text

---

## App-Specific Do / Don't

### Predictions

| ✅ Do | ❌ Don't |
|-------|---------|
| Hide the prediction list before kickoff (don't even render it) | Render it greyed out — risks leaking via DOM inspection |
| Show "Predictions reveal at kickoff" placeholder | Leave section blank |
| Show `is_auto` badge subtly: small `AUTO` chip | Make it alarming or prominent |

### Leaderboard

| ✅ Do | ❌ Don't |
|-------|---------|
| Highlight current user row: `background: rgba(245,197,24,.08)` | Rely on position to find yourself |
| 🥇🥈🥉 only for top 3, number text for the rest | Use medal emojis for all ranks |
| Inactive members: `opacity: 0.5`, keep in list | Remove inactive members from view |

### Scores

| ✅ Do | ❌ Don't |
|-------|---------|
| Show 90-min score, then "AET 2–1 (pens 4–3)" separately | Add ET/pen goals to the 90-min score |
| Show ET/pen block only when `went_to_extra_time = true` | Always show ET/pen columns |

### Deadlines / Locks

| ✅ Do | ❌ Don't |
|-------|---------|
| Show lock icon + reason + existing pick | Hide the section after deadline |
| Show countdown if < 24h to kickoff | Only show the date string |

---

## Safe Area (iOS / notch phones)

```css
/* Bottom-fixed bars must respect safe area */
.bottom-nav {
  padding-bottom: env(safe-area-inset-bottom);
}
/* Page body must not be hidden under fixed nav */
.page-body {
  padding-bottom: calc(56px + env(safe-area-inset-bottom));
}
```

---

## Contrast Quick Reference

| Combination | Ratio | Pass |
|-------------|-------|------|
| `--text` (#f0f0f0) on `--bg` (#0a0a0a) | 17.5:1 | ✅ AAA |
| `--text` on `--bg2` (#111111) | 15.4:1 | ✅ AAA |
| `--accent` (#f5c518) on `--bg` | 12.1:1 | ✅ AAA |
| `--muted` (#888888) on `--bg` | 4.6:1 | ✅ AA |
| `--muted` on `--bg3` (#1a1a1a) | 4.1:1 | ✅ AA (large text only) |
| White (#fff) on `--bg` | 21:1 | — avoid (breaks dark theme feel) |
