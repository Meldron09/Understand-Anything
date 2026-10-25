#!/bin/sh
# Script-CLI tests for degradation to text (ticket 45): learn-anything/scripts/degrade-words (size to words)
# and plan-unit (record degraded/failed in plan.md, list them for the close), plus seam checks that the
# conductor and text skills wire them in. Files only, no model calls. Run: sh tests/degrade/run.sh
here=$(cd "$(dirname "$0")" && pwd)
pl=$here/../../learn-anything
dw=$pl/scripts/degrade-words
pu=$pl/scripts/plan-unit
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fails=0
. "$here/../lib.sh"
block() { sed -n "/^## $2\$/,/^\$/p" "$1"; }   # one unit's block

# AC1: size conversion matches the spec examples; the other modes follow the router's rates
t "2 min of video = 400 words"   eq "$(sh "$dw" '2 min')" "400 words"
t "12 slides = 3600 words"       eq "$(sh "$dw" '12 slides')" "3600 words"
t "10 quiz items = 1000 words"   eq "$(sh "$dw" '10 items')" "1000 words"
t "3 widgets = 3000 words"       eq "$(sh "$dw" '3 widgets')" "3000 words"
t "a text size passes through"   eq "$(sh "$dw" '1800 words')" "1800 words"
t "odd slide count rounds"       eq "$(sh "$dw" '5 slides')" "1500 words"
t "unknown size: exit 2"         sh -c "sh '$dw' '4 parsecs' >/dev/null 2>&1; [ \$? -eq 2 ]"

# a plan with a quiz unit that failed, a slides unit that degraded on its own, and a done text unit
cat > "$tmp/plan.md" <<'EOF'
---
lesson: x
budget: 30
---
## u1
mode: text
focus: f1
slices: [s1#c01]
size: 1800 words
tier: 0
status: pending

## u2
mode: quiz
focus: f2
slices: [s1#c02]
size: 10 items
tier: 0
status: pending

## u3
mode: interactive
focus: f3
slices: [s1#c03]
size: 2 widgets
tier: 0
status: pending
EOF
p=$tmp/plan.md
sh "$pu" set "$p" u1 done lesson/u1-text.md

# AC2: degraded: <reason>, artifact = the text file, original mode and size kept, other units untouched
sh "$pu" set "$p" u2 "degraded: item generation failed" lesson/u2-text.md
t "u2 status degraded with reason"   test "$(block "$p" u2 | grep -c '^status: degraded: item generation failed$')" = 1
t "u2 artifact is the text file"     test "$(block "$p" u2 | grep '^artifact:')" = "artifact: lesson/u2-text.md"
t "u2 keeps its original mode"       test "$(block "$p" u2 | grep '^mode:')" = "mode: quiz"
t "u2 keeps its original size"       test "$(block "$p" u2 | grep '^size:')" = "size: 10 items"
t "u2 keeps focus and slices"        sh -c "block() { sed -n '/^## u2\$/,/^\$/p' '$p'; }; block | grep -q '^focus: f2' && block | grep -q '^slices: \[s1#c02\]'"
t "u1 untouched by u2's record"      test "$(block "$p" u1 | grep -c '^status: done$')" = 1
t "u3 still pending"                 test "$(block "$p" u3 | grep -c '^status: pending$')" = 1
t "one status line per unit"         test "$(grep -c '^status:' "$p")" = 3

# re-recording replaces rather than duplicating the artifact line
sh "$pu" set "$p" u2 "degraded: item generation failed" lesson/u2-text.md
t "re-record: a single artifact line" test "$(block "$p" u2 | grep -c '^artifact:')" = 1

# a video unit's footer reason already carries `degraded:` lines: recorded once, not `degraded: degraded:`
sh "$pu" set "$p" u1 "degraded: degraded: s03 blank; degraded: narrated with say" lesson/u1-video.mp4
t "no doubled degraded prefix"       test "$(block "$p" u1 | grep '^status:')" = "status: degraded: s03 blank; narrated with say"
sh "$pu" set "$p" u1 done lesson/u1-text.md

# AC3: a re-dispatch that also fails is failed: <reason>, no artifact line added
sh "$pu" set "$p" u3 "failed: text write failed"
t "u3 status failed with reason"     test "$(block "$p" u3 | grep -c '^status: failed: text write failed$')" = 1
t "u3 keeps its original mode"       test "$(block "$p" u3 | grep '^mode:')" = "mode: interactive"
t "u3 has no artifact"               test "$(block "$p" u3 | grep -c '^artifact:')" = 0
t "unknown unit: exit 2"             sh -c "sh '$pu' set '$p' u9 done >/dev/null 2>&1; [ \$? -eq 2 ]"

# AC4: the close lists every degraded or failed unit with its reason, and only those
o=$(sh "$pu" report "$p")
t "report lists the degraded unit"   sh -c "printf '%s\n' '$o' | grep -qx 'u2 | quiz | degraded: item generation failed | lesson/u2-text.md'"
t "report lists the failed unit"     sh -c "printf '%s\n' '$o' | grep -qx 'u3 | interactive | failed: text write failed | -'"
t "report omits done units"          test "$(printf '%s\n' "$o" | wc -l | tr -d ' ')" = 2
sh "$pu" set "$p" u2 done lesson/u2-quiz.html; sh "$pu" set "$p" u3 done lesson/u3-interactive.html
t "report on a clean plan: none"     eq "$(sh "$pu" report "$p")" none

# a degraded unit is never re-run: resume-check does not count it as pending
sh "$pu" set "$p" u2 "degraded: x" lesson/u2-text.md
mkdir -p "$tmp/cwd/learn-anything/lsn"; cp "$p" "$tmp/cwd/learn-anything/lsn/plan.md"
printf -- '---\nlesson: lsn\n---\n' > "$tmp/cwd/learn-anything/lsn/brief.md"; echo 'declined: true' > "$tmp/cwd/learn-anything/lsn/check.md"
t "degraded unit is not pending on resume" sh -c "cd '$tmp/cwd' && ! sh '$pl/scripts/resume-check' list | grep -q lsn"

# seams: the conductor and text skills wire the scripts in, and the brief documents the table
learn=$pl/skills/learn/SKILL.md
t "conductor calls degrade-words"    grep -q 'scripts/degrade-words' "$learn"
t "conductor records via plan-unit"  grep -q 'scripts/plan-unit set' "$learn"
t "conductor closes via plan-unit report" grep -q 'scripts/plan-unit report' "$learn"
t "conductor re-dispatches to text"  grep -q 'learn-anything:text' "$learn"
t "dispatch documents the rates"     sh -c "grep -q '2 min. = 400 words' '$pl/skills/learn/dispatch.md' && grep -q '12 slides. = 3600 words' '$pl/skills/learn/dispatch.md' && grep -q '10 items. = 1000 words' '$pl/skills/learn/dispatch.md'"
t "dispatch has the text re-dispatch brief" grep -q '^## Text re-dispatch' "$pl/skills/learn/dispatch.md"
t "text skill lets the brief override size and focus" grep -q 'line in your brief wins' "$pl/skills/text/SKILL.md"

[ "$fails" -eq 0 ] && echo "all passed"
exit "$fails"
