---
name: Commit means commit only — no push
description: When user says "commit", do not push to remote unless explicitly asked
type: feedback
originSessionId: 81b3cce7-9ecd-4e9b-96b5-3ec88d6dcbf9
---
"commit" = `git add` + `git commit` only. Do NOT run `git push` unless the user explicitly says to push.

**Why:** User called this out after an unwanted push was done during the nightly-summary feature branch work.

**How to apply:** Any time the user says "commit", "commit the files", "commit and add" — stop at the local commit. Never push unless the user says "push", "push to remote", or similar explicit instruction.
