#!/bin/sh
# Offline tests for ingest's scripts (chunk, fetch-url) on fixtures. fetch-url needs `uv` (and
# network on first run to install its pinned deps); its tests skip without uv.
# Run: sh tests/ingest/run.sh
here=$(cd "$(dirname "$0")" && pwd)
sc=$here/../../learn-anything/skills/ingest/scripts
fx=$here/fixtures
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fails=0
ok() { echo "ok   $1"; }
bad() { echo "FAIL $1"; fails=$((fails + 1)); }
t() { desc=$1; shift; if "$@"; then ok "$desc"; else bad "$desc"; fi; }
key() { sed -n '2,/^---$/p' "$1" | sed '$d' | sed -n "s/^$2:[[:space:]]*//p" | head -n 1; }
entries() { grep -c '^c[0-9][0-9]* |' "$1"; }

# markdown: by headings, index fields, hash of the original, summary placeholder per entry
python3 "$sc/chunk" "$fx/notes-a.md" "$tmp/a" --kind file --origin ./notes-a.md >/dev/null || bad "chunk md ran"
i=$tmp/a/index.md
t "md: chunking headings" test "$(key "$i" chunking)" = headings
t "md: three or more chunk entries" test "$(entries "$i")" -ge 3
t "md: hash is sha256 of the original" test "$(key "$i" hash)" = "sha256:$(shasum -a 256 < "$fx/notes-a.md" | cut -d' ' -f1)"
t "md: frontmatter fields" sh -c "for k in kind origin hash fetched grounded tokens chunking status links; do grep -q \"^\$k:\" '$i' || exit 1; done"
t "md: each entry has a summary slot" test "$(grep -c '^SUMMARY$' "$i")" = "$(entries "$i")"
t "md: entry names an existing chunk file" test -f "$tmp/a/$(grep '^c01 |' "$i" | awk -F' [|] ' '{print $5}')"
t "md: origin is a heading path" grep -q '^c0[0-9] | .* | Git object model > Trees and blobs | ' "$i"

# code file: windows, several chunks, token total is chars/4
python3 "$sc/chunk" "$fx/sample.py" "$tmp/c" --kind file --origin ./sample.py >/dev/null || bad "chunk code ran"
t "code: chunking window" test "$(key "$tmp/c/index.md" chunking)" = window
t "code: several chunks" test "$(entries "$tmp/c/index.md")" -ge 4
t "code: chunks keep every line" test "$(cat "$tmp"/c/chunks/*.txt | wc -c | tr -d ' ')" = "$(wc -c < "$fx/sample.py" | tr -d ' ')"

# plain text: one chunk; empty and binary files are refused
python3 "$sc/chunk" "$fx/plain.txt" "$tmp/p" --kind file --origin ./plain.txt >/dev/null
t "txt: one chunk" test "$(entries "$tmp/p/index.md")" = 1
: > "$tmp/empty.txt"
t "empty file refused" sh -c "! python3 '$sc/chunk' '$tmp/empty.txt' '$tmp/e' --kind file --origin x 2>/dev/null"
printf 'a\0b' > "$tmp/bin.dat"
t "binary file refused" sh -c "! python3 '$sc/chunk' '$tmp/bin.dat' '$tmp/b' --kind file --origin x 2>/dev/null"

# URL pages (saved HTML fixtures)
if command -v uv >/dev/null; then
  out=$(uv run --script "$sc/fetch-url" "$fx/code-heavy.html" https://docs.example.org/init "$tmp/code.md")
  t "code-heavy page: ok" sh -c "echo '$out' | grep -q '\"status\": \"ok\"'"
  t "code-heavy page: all three code blocks kept as fences" test "$(grep -c '^```' "$tmp/code.md")" = 6
  t "code-heavy page: no line-number anchors left" sh -c "! grep -q 'codelineno' '$tmp/code.md'"
  t "code-heavy page: block content intact" grep -q '^\$ uv add requests$' "$tmp/code.md"
  python3 "$sc/chunk" "$tmp/code.md" "$tmp/u" --kind url --origin https://docs.example.org/init >/dev/null
  t "url: chunk by headings" test "$(key "$tmp/u/index.md" chunking)" = headings
  uv run --script "$sc/fetch-url" "$fx/js-shell.html" https://app.example.org/ "$tmp/js.md" >"$tmp/js.out"; rc=$?
  t "js shell: failed, exit 3" test "$rc" = 3
  t "js shell: reported failed, no output file" sh -c "grep -q '\"status\": \"failed\"' '$tmp/js.out' && [ ! -e '$tmp/js.md' ]"
else
  echo "skip: uv not found, fetch-url tests not run"
fi

[ "$fails" -eq 0 ] && echo "ingest scripts: all passed"
exit "$fails"
