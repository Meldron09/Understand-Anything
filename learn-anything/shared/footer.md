# Footer

Every unit skill ends its result with this block, and the conductor parses it. The whole result is at most about 150 words including the footer; anything over about 100 words goes to disk and returns as a path.

```
status: done | degraded | failed
artifact: <path to the lesson artifact>
reason: <only on degraded or failed>
notes: <comma-separated key=value; keys below>
```

Notes keys: text `words=<n>`, `ungrounded=true`, `native_pages=<n>`, `short=<why>`; quiz `items=<n>`, `not browser-tested`; interactive `widgets=<n>`, `not browser-tested`, `ungrounded=true`, `short=<why>`. The conductor surfaces notes to the learner only for `short=`, `rendered=none` and `ungrounded=true`.
