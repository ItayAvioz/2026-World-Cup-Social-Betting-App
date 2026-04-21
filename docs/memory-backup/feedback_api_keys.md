---
name: feedback_api_keys
description: API keys live only in Supabase vault — never ask for key values, never put in frontend or .env
type: feedback
---

API keys (FOOTBALL_API_KEY, theoddsapi) live ONLY in Supabase Edge Function secrets (vault). This is confirmed correct architecture.

**Why:** EFs read them via `Deno.env.get()` — never exposed to client. Not in frontend code, not in .env files, not in git.

**How to apply:** Never ask the user for the actual key values. Never suggest putting them anywhere other than the vault. If keys are missing, just remind the user to run:
```bash
supabase secrets set FOOTBALL_API_KEY=<key> --project-ref ftryuvfdihmhlzvbpfeu
supabase secrets set theoddsapi=<key> --project-ref ftryuvfdihmhlzvbpfeu
```
Then real-time testing can be done whenever the user is ready. Do not treat missing keys as a blocker that needs to be resolved immediately.
