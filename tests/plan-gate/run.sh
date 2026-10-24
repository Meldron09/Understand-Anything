#!/bin/sh
# Script-CLI tests for learn-anything/scripts/plan-gate: skip / show / refuse verdicts, totals.
# Run: sh tests/plan-gate/run.sh
here=$(cd "$(dirname "$0")" && pwd)
pg=$here/../../learn-anything/scripts/plan-gate
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fails=0
t() { desc=$1; shift; if "$@"; then echo "ok   $desc"; else echo "FAIL $desc"; fails=$((fails + 1)); fi; }
has() { printf '%s\n' "$1" | grep -q -- "$2"; }

# plan <name> <block>...: a lesson dir whose plan.md holds the given unit blocks
plan() {
  d=$tmp/$1; shift; mkdir -p "$d"
  printf -- '---\nlesson: x\nbudget: 30\nplanned: 27\ninputs: {brief: sha256:aa}\n---\n' > "$d/plan.md"
  for b in "$@"; do printf '%s\n' "$b" >> "$d/plan.md"; done
  echo "$d"
}
text() { printf '## u%s\nmode: text\nfocus: f\nslices: [s1#c01]\nsize: 1800 words\ntier: 0\nstatus: pending\n' "$1"; }
video() { printf '## u%s\nmode: video\nrenderer: hyperframes\nfocus: f\nslices: [s1#c01]\nsize: %s min\ntier: 3\nstatus: pending\npredicted: node missing\n' "$1" "$2"; }

d=$(plan one "$(text 1)"); o=$("$pg" "$d")
t "one text unit at tier 0: skipped" has "$o" '^gate: skip$'
t "one unit: no subagents" has "$o" 'units=1 subagents=0'

d=$(plan two "$(text 1)" "$(text 2)"); o=$("$pg" "$d")
t "two units: shown" has "$o" '^gate: show$'
t "two units: one line per unit" test "$(printf '%s\n' "$o" | grep -c '^u[0-9] |')" = 2
t "two units: subagents counted" has "$o" 'units=2 subagents=2'

d=$(plan vid "$(video 1 2)"); o=$("$pg" "$d")
t "lone video unit (tier 3): shown" has "$o" '^gate: show$'
t "unit line carries the predicted flag" has "$o" '^u1 | video | hyperframes | 2 min | tier 3 | predicted: node missing$'
t "totals: video minutes and highest tier" has "$o" 'video_min=2 highest_tier=3'

# download size: only missing pieces up to the highest tier; failed sources and links listed
cat > "$d/preflight.md" <<'EOF'
## Missing

- uv (tier 1): `brew install uv` (~40 MB)
- cairo and pkg-config (tier 2): `brew install cairo pkg-config` (~60 MB)
- Node 22+ (tier 3): `brew install node` (~80 MB)
- pdftotext (PDF text, optional): `brew install poppler` (~30 MB)
EOF
mkdir -p "$d/sources/s1" "$d/sources/s2"
printf -- '---\nstatus: ok\nlinks: [https://a.example/x, https://b.example/y]\n---\n' > "$d/sources/s1/index.md"
printf -- '---\nstatus: failed\nlinks: []\n---\n' > "$d/sources/s2/index.md"
o=$("$pg" "$d")
t "download sums the tiers the plan needs" has "$o" 'download=~180 MB'
t "failed source listed" has "$o" 'failed_sources=1 (s2)'
t "outbound links listed" has "$o" '^links: s1: \[https://a.example/x'
d1=$(plan lowtier "$(text 1)" "$(text 2)"); cp "$d/preflight.md" "$d1/"
t "tier-0 plan downloads nothing" has "$("$pg" "$d1")" 'download=~0 MB'

# caps: refused, never shrunk
set --; i=1; while [ $i -le 9 ]; do set -- "$@" "$(text $i)"; i=$((i + 1)); done
d=$(plan nine "$@"); o=$("$pg" "$d")
t "9 units: refused" has "$o" '^gate: refuse (9 units, cap 8)$'
t "9 units: plan left untouched" test "$(grep -c '^## u' "$d/plan.md")" = 9
set --; i=1; while [ $i -le 8 ]; do set -- "$@" "$(text $i)"; i=$((i + 1)); done
t "8 units: allowed" has "$("$pg" "$(plan eight "$@")")" '^gate: show$'
t "6 video minutes: refused" has "$("$pg" "$(plan v6 "$(video 1 3)" "$(video 2 3)")")" '^gate: refuse (6 video minutes, cap 5)$'
t "5 video minutes: allowed" has "$("$pg" "$(plan v5 "$(video 1 3)" "$(video 2 2)")")" '^gate: show$'
d=$(plan marked "$(text 1)"); sed -i.bak 's/^budget:/over-cap: router says cut\nbudget:/' "$d/plan.md"
t "router's over-cap mark is honoured" has "$("$pg" "$d")" '^gate: refuse (router marked it: router says cut)$'

"$pg" "$tmp/none" 2>/dev/null; t "no plan.md: exit 2" test $? = 2

[ "$fails" -eq 0 ] && echo "plan-gate: all passed"
exit "$fails"
