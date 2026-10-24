#!/bin/sh
# Sources e2e: run the conductor on a canned brief with two local Markdown files and one refused
# .docx, then assert on files; then a run where every source fails must stop. Needs the `claude`
# CLI and a working login; skips (exit 0) without it. Run: sh tests/ingest/e2e.sh   Keep: KEEP=1
here=$(cd "$(dirname "$0")" && pwd)
plugin=$here/../../learn-anything
fx=$here/fixtures
command -v claude >/dev/null || { echo "skip: claude CLI not found"; exit 0; }
tmp=$(mktemp -d); [ -n "$KEEP" ] || trap 'rm -rf "$tmp"' EXIT
fails=0
ok() { echo "ok   $1"; }
bad() { echo "FAIL $1"; fails=$((fails + 1)); }
t() { desc=$1; shift; if "$@"; then ok "$desc"; else bad "$desc"; fi; }
key() { sed -n '2,/^---$/p' "$1" | sed '$d' | sed -n "s/^$2:[[:space:]]*//p" | head -n 1; }
# run <scratch dir>: conductor on the lesson already in place there
run() { (cd "$1" && claude -p "/learn-anything:learn git-basics" --plugin-dir "$plugin" \
  --permission-mode acceptEdits --allowedTools Skill Read Write Edit Bash > "$1/conductor.out" 2>&1); }
# summaries: every chunk entry is followed by a line of 1-25 words that is not the SUMMARY slot
summaries_ok() {
  awk '/^c[0-9]+ \|/ {e++; want=1; next} want {want=0; if (NF == 0 || NF > 25 || $0 == "SUMMARY") bad=1; n++}
       END {exit (bad || e == 0 || n != e)}' "$1"
}

# run 1: two good sources, one refused
d=$tmp/one; mkdir -p "$d/notes" "$d/learn-anything/git-basics"
cp "$fx/notes-a.md" "$fx/notes-b.md" "$fx/handout.docx" "$d/notes/"
cp "$fx/brief-sources.md" "$d/learn-anything/git-basics/brief.md"
run "$d" || { cat "$d/conductor.out"; bad "conductor run 1"; }
l=$d/learn-anything/git-basics
for n in 1 2; do
  i=$l/sources/s$n/index.md
  t "s$n index exists" test -f "$i"
  t "s$n status ok" test "$(key "$i" status)" = ok
  t "s$n hash is sha256 of the original" test "$(key "$i" hash)" = "sha256:$(shasum -a 256 < "$d/$(key "$i" origin)" | cut -d' ' -f1)"
  t "s$n has chunk entries" test "$(grep -c '^c[0-9][0-9]* | .* | .* | [0-9][0-9]* | ' "$i")" -ge 3
  t "s$n summaries present, at most 25 words" summaries_ok "$i"
done
t "s3 failed" test "$(key "$l/sources/s3/index.md" status)" = failed
t "failed source named in the run output" grep -q 'handout.docx' "$d/conductor.out"
p=$l/plan.md
t "plan unit lists slices as a list" grep -q '^slices: \[.*\]' "$p"
t "plan slices come from s1 and s2" sh -c "grep '^slices:' '$p' | grep -q 's1#' && grep '^slices:' '$p' | grep -q 's2#'"
t "plan slices never name the failed source" sh -c "! grep '^slices:' '$p' | grep -q 's3#'"
t "unit done" sh -c "sed -n '/^## u1\$/,\$p' '$p' | grep -q '^status: done'"
t "artifact exists" test -f "$l/lesson/u1-text.md"

# run 2: every source fails -> stop, no plan
d=$tmp/two; mkdir -p "$d/notes" "$d/learn-anything/git-basics"
cp "$fx/handout.docx" "$d/notes/"
sed 's#^sources:.*#sources: [./notes/handout.docx, ./notes/missing.md]#' "$fx/brief-sources.md" > "$d/learn-anything/git-basics/brief.md"
run "$d"
l=$d/learn-anything/git-basics
t "all-failed: no plan.md" test ! -e "$l/plan.md"
t "all-failed: no lesson artifact" test ! -e "$l/lesson/u1-text.md"
t "all-failed: both sources recorded failed" test "$(grep -l '^status: failed' "$l"/sources/s*/index.md | wc -l | tr -d ' ')" = 2

[ "$fails" -eq 0 ] && echo "sources e2e: all passed"
[ -n "$KEEP" ] && echo "scratch: $tmp"
exit "$fails"
