#!/bin/sh
# PDF e2e: (1) conductor on a 25-page PDF with an outline (large: two-phase path) and on a scanned
# PDF (page pointers only, still plans); (2) the text skill on a short PDF whose cached text is
# broken around an equation reads pages natively and its footer records native_pages of 1-3.
# Needs the `claude` CLI, a login and uv; skips (exit 0) without them. Run: sh tests/ingest/e2e-pdf.sh
here=$(cd "$(dirname "$0")" && pwd)
plugin=$here/../../learn-anything
sc=$plugin/skills/ingest/scripts
fx=$here/fixtures
command -v claude >/dev/null && command -v uv >/dev/null || { echo "skip: claude CLI or uv not found"; exit 0; }
tmp=$(mktemp -d); [ -n "$KEEP" ] || trap 'rm -rf "$tmp"' EXIT
fails=0
ok() { echo "ok   $1"; }
bad() { echo "FAIL $1"; fails=$((fails + 1)); }
t() { desc=$1; shift; if "$@"; then ok "$desc"; else bad "$desc"; fi; }
key() { sed -n '2,/^---$/p' "$1" | sed '$d' | sed -n "s/^$2:[[:space:]]*//p" | head -n 1; }
setup() { # setup <dir> <mkpdf args...>: lesson folder with the brief and ./notes/book.pdf
  d=$1; shift; mkdir -p "$d/notes" "$d/learn-anything/pdf-basics"
  python3 "$here/mkpdf.py" "$d/notes/book.pdf" "$@"
  cp "$fx/brief-pdf.md" "$d/learn-anything/pdf-basics/brief.md"
}
conductor() { (cd "$1" && claude -p "/learn-anything:learn pdf-basics" --plugin-dir "$plugin" --permission-mode acceptEdits \
  --allowedTools Skill Read Write Edit Bash Agent > "$1/conductor.out" 2>&1); }

# 1a: large PDF with an outline
setup "$tmp/big" 25 --outline
conductor "$tmp/big" || { cat "$tmp/big/conductor.out"; bad "conductor run (large)"; }
l=$tmp/big/learn-anything/pdf-basics; i=$l/sources/s1/index.md
t "large: chunked by outline" test "$(key "$i" chunking)" = outline
t "large: summaries merged, no slot left" sh -c "[ -f '$i' ] && ! grep -q '^SUMMARY\$' '$i'"
t "large: summaries at most 25 words" sh -c "awk '/^c[0-9]+ \\|/ {want=1; next} want {want=0; if (NF == 0 || NF > 25) bad=1} END {exit bad}' '$i'"
t "large: work folder cleaned" test ! -e "$l/work/ingest-s1"
t "large: plan lists a slice of s1" grep -q '^slices: \[s1#' "$l/plan.md"

# 1b: scanned PDF
setup "$tmp/scan" 20 --scanned
conductor "$tmp/scan" || { cat "$tmp/scan/conductor.out"; bad "conductor run (scanned)"; }
l=$tmp/scan/learn-anything/pdf-basics
t "scanned: source ok, no chunk text" sh -c "[ \"$(key "$l/sources/s1/index.md" status)\" = ok ] && [ -z \"\$(ls '$l/sources/s1/chunks')\" ]"
t "scanned: still plans" grep -q '^slices: \[s1#' "$l/plan.md"

# 2: text skill on a short PDF with a broken equation
setup "$tmp/eq" 8 --equation
l=$tmp/eq/learn-anything/pdf-basics
uv run --script "$sc/chunk-pdf" "$tmp/eq/notes/book.pdf" "$l/sources/s1" --origin ./notes/book.pdf >/dev/null
sed -i.bak 's/^SUMMARY$/Quadratic roots formula: the equation for x in terms of a, b and c./' "$l/sources/s1/index.md"
cat > "$l/plan.md" <<PLAN
---
lesson: pdf-basics
budget: 5
planned: 4
inputs: {}
---
## u1
mode: text
focus: the roots formula equation and the discriminant
slices: [s1#c01]
size: 400 words
tier: 0
status: pending
PLAN
(cd "$tmp/eq" && claude -p "Invoke skill learn-anything:text for one lesson unit.
lesson: ./learn-anything/pdf-basics
brief: ./learn-anything/pdf-basics/brief.md
plan: ./learn-anything/pdf-basics/plan.md
unit: u1
slices: [s1#c01]
work: ./learn-anything/pdf-basics/work/u1
artifact: ./learn-anything/pdf-basics/lesson/u1-text.md
Task: the roots formula equation and the discriminant. Write only the artifact and the work dir, spawn nothing, reply in at most 150 words ending with the footer." \
  --plugin-dir "$plugin" --permission-mode acceptEdits --allowedTools Skill Read Write Edit Bash > "$tmp/eq/text.out" 2>&1)
t "equation: artifact written" test -f "$l/lesson/u1-text.md"
n=$(sed -n 's/.*native_pages=\([0-9][0-9]*\).*/\1/p' "$tmp/eq/text.out" | tail -n 1)
t "equation: footer records native_pages 1 to 3" sh -c "[ -n '$n' ] && [ '$n' -ge 1 ] && [ '$n' -le 3 ]"

[ "$fails" -eq 0 ] && echo "pdf e2e: all passed"
[ -n "$KEEP" ] && echo "scratch: $tmp"
exit "$fails"
