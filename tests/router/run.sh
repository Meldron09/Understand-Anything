#!/bin/sh
# Deterministic multi-unit planning tests: scripts/plan-size (order, budget split, caps), plan-gate on the
# resulting plans (8-unit cap) and plan-unit next (dispatch rounds of at most 3). Files only, no model calls.
# Run: sh tests/router/run.sh
here=$(cd "$(dirname "$0")" && pwd)
pl=$here/../../learn-anything
ps=$pl/scripts/plan-size
pg=$pl/scripts/plan-gate
pu=$pl/scripts/plan-unit
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fails=0
. "$here/../lib.sh"

# mkplan <name> <budget> <mode>...: a lesson dir whose plan.md is built from plan-size's lines
mkplan() {
  n=$1 b=$2; shift 2; d=$tmp/$n; mkdir -p "$d"
  sh "$ps" "$b" "$@" | awk -v b="$b" '
    /^planned:/ { printf "---\nlesson: x\nbudget: %s\nplanned: %s\ninputs: {brief: sha256:aa}\n---\n", b, $2; next }
    /^over-cap:/ { next }
    { t = ($2 == "text" || $2 == "quiz" || $2 == "slides" || $2 == "interactive") ? 0 : 2
      printf "## %s\nmode: %s\nfocus: f\nslices: [s1#c01]\nsize: %s %s\ntier: %d\nstatus: pending\n\n", $1, $2, $3, $4, t }' > "$d/plan.md"
  echo "$d"
}

# five modes (more than 3 units), given out of order: explainers first, quiz last
o=$(sh "$ps" 30 quiz video text interactive slides)
t "five units, explainer modes first then quiz" eq "$(printf '%s\n' "$o" | awk '/^u/ { printf "%s ", $2 }')" "text slides interactive video quiz "
t "unit ids follow plan order" eq "$(printf '%s\n' "$o" | awk '/^u/ { printf "%s ", $1 }')" "u1 u2 u3 u4 u5 "
t "planned is 90% of the budget" has "$o" '^planned: 27$'
t "no over-cap on a fitting plan" sh -c "! printf '%s\n' '$o' | grep -q '^over-cap'"
t "budget is split, not repeated per unit (text gets a fifth of 27 min)" has "$o" '^u1 text 1080 words$'
# the minutes the sizes add up to stay within planned
mins=$(printf '%s\n' "$o" | awk '/^u/ {
  if ($2 == "text") m += $3 / 200; else if ($2 == "slides") m += $3 * 1.5; else if ($2 == "interactive") m += $3 * 5
  else if ($2 == "video") m += $3; else m += $3 / 2 } END { print m }')
t "sizes add up to at most planned (27 min)" test "$(echo "$mins" | awk '{ print ($1 <= 27) }')" = 1
t "and use most of it (at least 25 min)" test "$(echo "$mins" | awk '{ print ($1 >= 25) }')" = 1
mins=$(sh "$ps" 60 text text text slides | awk '/^u/ { if ($2 == "text") m += $3 / 200; else m += $3 * 1.5 } END { print m }')
t "several units of one mode share the budget (54 min planned, 4 units)" test "$(echo "$mins" | awk '{ print ($1 <= 54 && $1 >= 51) }')" = 1
t "same-mode units keep input order and get equal shares" eq "$(sh "$ps" 60 text text | awk '/^u/ { printf "%s:%s ", $1, $3 }')" "u1:5400 u2:5400 "
t "a single mode keeps the whole planned budget" has "$(sh "$ps" 30 text)" '^u1 text 5400 words$'
t "a 5-minute single quiz keeps the old rate (9 items)" has "$(sh "$ps" 5 quiz)" '^u1 quiz 9 items$'
t "unknown mode: exit 2" sh -c "sh '$ps' 30 text podcast >/dev/null 2>&1; [ \$? -eq 2 ]"
t "over 5 video minutes is flagged, not shrunk" has "$(sh "$ps" 30 video)" '^over-cap: 27 video minutes, cap 5$'
t "9 units is flagged over-cap" has "$(sh "$ps" 90 text text text text text text text text text)" '^over-cap: 9 units, cap 8$'

# plan-gate on a five-unit plan: shown, not refused; one subagent per unit
d=$(mkplan five 30 text slides interactive video quiz); g=$(sh "$pg" "$d")
t "five-unit plan: gate shows it" has "$g" '^gate: show$'
t "five-unit plan: totals count 5 units, 5 subagents" has "$g" 'units=5 subagents=5'

# dispatch rounds of at most 3
t "round 1 of 5 pending units: u1 u2 u3" eq "$(sh "$pu" next "$d/plan.md" | tr '\n' ' ')" "u1 u2 u3 "
for u in u1 u2 u3; do sh "$pu" set "$d/plan.md" $u done lesson/$u.md; done
t "round 2: the remaining u4 u5" eq "$(sh "$pu" next "$d/plan.md" | tr '\n' ' ')" "u4 u5 "
sh "$pu" set "$d/plan.md" u4 failed
t "a failed unit is not pending: round 3 is u5 only" eq "$(sh "$pu" next "$d/plan.md" | tr '\n' ' ')" "u5 "
sh "$pu" set "$d/plan.md" u5 done lesson/u5.md
t "no pending units: no round" eq "$(sh "$pu" next "$d/plan.md")" ""

# the 8-unit cap: eight pass the gate, nine are refused (the router writes the plan as sized)
d=$(mkplan eight 90 text text text text text text text text); g=$(sh "$pg" "$d")
t "8 units: gate shows" has "$g" '^gate: show$'
t "8 units: rounds of 3, 3, 2" eq "$(sh "$pu" next "$d/plan.md" | wc -l | tr -d ' ')" 3
d=$(mkplan nine 90 text text text text text text text text text)
t "9 units: gate refuses" has "$(sh "$pg" "$d")" '^gate: refuse (9 units, cap 8)$'
t "9 units: plan keeps all 9 blocks" eq "$(grep -c '^## u' "$d/plan.md")" 9

# the skill files wire the scripts in and carry no tracer leftovers
t "router skill runs plan-size" grep -q 'scripts/plan-size' "$pl/skills/router/SKILL.md"
t "conductor takes its rounds from plan-unit next" grep -q 'plan-unit next' "$pl/skills/learn/SKILL.md"
t "no 'not built' text left in any skill or shared file" sh -c "! grep -rliE 'not built|built so far|later tickets?|exists so far|tracer scope' '$pl/skills' '$pl/shared' --include=*.md"

[ "$fails" -eq 0 ] && echo "router: all passed"
exit "$fails"
