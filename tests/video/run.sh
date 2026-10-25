#!/bin/sh
# Script-CLI and seam tests for the video mode (tickets 47 and 48): learn-anything/skills/video/scripts/{plan,narrate,
# render,assemble} under PATH-controlled fakes (no kokoro, say, ffmpeg or Manim needed, no model calls), plus
# file/frontmatter checks that the skill and its wiring exist. Run: sh tests/video/run.sh
# Acceptance criteria -> tests: AC1 "scene count / length" = plan scenes, plan check, plan storyboard;
# AC2 "one process, durations baked" = narrate (kokoro: one uv call), plan bake; AC3 "smoke first, jobs,
# contact sheet" = render clips, render sheet, plan jobs (the one repair pass is a SKILL.md step, seam-checked);
# AC4 "hidden kokoro/say/ffmpeg" = narrate chain, plan gate; AC5 "tier-2 probes" = preflight cairo/pkg-config.
# Ticket 48: T1 "router picks, downgrades with a note, predicts failure" = renderer-pick (row table, preflight.md);
# T2 "failed scene -> fallback rewrite once -> blank, `degraded: sNN blank`" = render one/blank, plan gate <renderer>
# fallback= (the rewrite itself is a SKILL.md step, seam-checked); T3 ">half blank or s01 failing on both -> failed"
# = render verdict, render blank s01; T4 consent text = plan-gate (tests/plan-gate); HyperFrames pin, telemetry off,
# frame streaming on = refs/hyperframes.md seam checks.
here=$(cd "$(dirname "$0")" && pwd)
pl=$here/../../learn-anything
vs=$pl/skills/video/scripts
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fails=0
t() { desc=$1; shift; if "$@"; then echo "ok   $desc"; else echo "FAIL $desc"; fails=$((fails + 1)); fi; }
eq() { [ "$1" = "$2" ]; }
has() { printf '%s\n' "$1" | grep -q -- "$2"; }
lacks() { ! printf '%s\n' "$1" | grep -q -- "$2"; }
code() { # code <want> <cmd...>: run quietly, compare exit status
  want=$1; shift; "$@" >/dev/null 2>&1; [ $? -eq "$want" ]; }

# base PATH: only the plain tools the scripts use, so anything else (uv, say, ffmpeg...) is hidden
base=$tmp/base; mkdir "$base"
for x in sh awk sed grep head tail tr ls mkdir rm mv cp cat basename dirname mktemp xargs sleep wc touch find sort; do
  ln -s "$(command -v $x)" "$base/$x"
done
stub() { printf '#!/bin/sh\n%s\n' "${3:-exit 0}" > "$1/$2"; chmod +x "$1/$2"; }
# fakes <name>...: a fresh dir of fakes; prints its path. LOG (env) collects what ffmpeg, say and uv were asked.
fakes() {
  d=$(mktemp -d "$tmp/f.XXXXXX")
  for n in "$@"; do
    case $n in
      ffmpeg) stub "$d" ffmpeg 'echo "ffmpeg $*" >> "$LOG"
case " $* " in *" -filters "*) [ -z "$FAKE_NOSUBS" ] && echo " T. subtitles       V->V  Render text subtitles"; exit 0;; esac
for a; do o=$a; done; echo x > "$o"';;
      ffprobe) stub "$d" ffprobe 'echo "${FAKE_DUR:-10.5}"';;
      say) stub "$d" say 'echo "say $*" >> "$LOG"
while [ $# -gt 0 ]; do [ "$1" = -o ] && o=$2; shift; done; echo x > "$o"';;
      uv) stub "$d" uv 'echo "uv $*" >> "$LOG"
[ -z "$FAKE_UV_FAIL" ] || exit 1
w=$4; mkdir -p "$w/audio"; s=""
for f in "$w"/narration/s*.txt; do i=$(basename "$f" .txt); echo x > "$w/audio/$i.wav"; s="$s${s:+,
}{\"id\":\"$i\",\"seconds\":${FAKE_SECS:-20.00}}"; done
printf "{\"engine\":\"kokoro\",\"voice\":\"af_bella\",\"scenes\":[\n%s\n]}\n" "$s" > "$w/timing.json"';;
      node) stub "$d" node 'echo v22.3.0';;
      pkg-config) stub "$d" pkg-config '[ "$1" = --exists ] && [ "$2" = cairo ]';;
      nproc) stub "$d" nproc 'echo "$FAKE_CORES"';;
      *) stub "$d" "$n";;
    esac
  done
  echo "$d"
}
full=$(fakes ffmpeg ffprobe say uv pkg-config)
LOG=$tmp/log; export LOG

sb=$tmp/storyboard.md   # three scenes; s02's narration runs over two lines
cat > "$sb" <<'EOF'
## s01
idea: why
visual: two boxes
narration: Hello there. How are you today?

## s02
idea: how
visual: an arrow
narration: One two three
four five six.
## s03
idea: recap
visual: text
narration: Done now.
EOF

# ---- AC1: scene count = round(seconds / 20) within min 2 and max 15
sc() { PATH=$base sh "$vs/plan" scenes "$1"; }
t "120 s = 6 scenes"            eq "$(sc 120)" 6
t "90 s rounds half up to 5"    eq "$(sc 90)" 5
t "50 s = 3 scenes"             eq "$(sc 50)" 3
t "30 s = 2 scenes (1.5 up)"    eq "$(sc 30)" 2
t "10 s is held at the minimum 2"  eq "$(sc 10)" 2
t "600 s is capped at 15"       eq "$(sc 600)" 15
t "'2 min' = 6 scenes"          eq "$(sc '2 min')" 6
t "'5 min' = 15 scenes"         eq "$(sc '5 min')" 15

# storyboard check: count, ids and narration
t "storyboard of 3 scenes matches 60 s"   eq "$(PATH=$base sh "$vs/plan" storyboard "$sb" 60)" "scenes=3"
o=$(PATH=$base sh "$vs/plan" storyboard "$sb" 120); rc=$?
t "wrong count fails and says so"         sh -c "[ $rc -eq 1 ] && printf '%s\n' '$o' | grep -q 'storyboard: 3 scenes, want 6'"
sed 's/^narration: Done now\.//' "$sb" > "$tmp/sb-empty.md"
o=$(PATH=$base sh "$vs/plan" storyboard "$tmp/sb-empty.md" 60)
t "scene without narration is named"      has "$o" 'storyboard: s03 has no narration'
sed 's/^## s03/## s04/' "$sb" > "$tmp/sb-gap.md"
t "non-sequential ids are named"          has "$(PATH=$base sh "$vs/plan" storyboard "$tmp/sb-gap.md" 60)" 'scene 3 is s04, want s03'
w=$tmp/w1; PATH=$base sh "$vs/plan" narration "$sb" "$w"
t "narration split per scene"             eq "$(ls "$w/narration" | tr '\n' ' ')" "s01.txt s02.txt s03.txt "
t "multi-line narration is joined"        eq "$(cat "$w/narration/s02.txt")" "One two three four five six."

# ---- AC1: narrated total within 25% of size, else resync
tj() { printf '{"engine":"kokoro","voice":"v","scenes":[\n{"id":"s01","seconds":%s},\n{"id":"s02","seconds":%s}\n]}\n' "$1" "$2" > "$tmp/tj.json"; }
ck() { tj "$1" "$2"; PATH=$base sh "$vs/plan" check "$3" "$tmp/tj.json"; }
tj 60 60; t "120 vs 120: ok"        code 0 env PATH="$base" sh "$vs/plan" check 120 "$tmp/tj.json"
tj 75 75; t "150 vs 120 (+25%): ok" code 0 env PATH="$base" sh "$vs/plan" check 120 "$tmp/tj.json"
tj 45 45; t "90 vs 120 (-25%): ok"  code 0 env PATH="$base" sh "$vs/plan" check 120 "$tmp/tj.json"
tj 76 76; t "152 vs 120: resync"    code 1 env PATH="$base" sh "$vs/plan" check 120 "$tmp/tj.json"
tj 44 44; t "88 vs 120: resync"     code 1 env PATH="$base" sh "$vs/plan" check 120 "$tmp/tj.json"
tj 60 60; t "'2 min' is 120 s"      code 0 env PATH="$base" sh "$vs/plan" check "2 min" "$tmp/tj.json"
tj 60 60; t "resync line names the totals" has "$(PATH=$base sh "$vs/plan" check 300 "$tmp/tj.json")" '^resync total=120.0 size=300'

# ---- AC3: parallelism = min(2, cores / 4), at least 1
jb() { f=$(fakes nproc); FAKE_CORES=$1 PATH="$f:$base" sh "$vs/plan" jobs; }
t "16 cores: 2 jobs"   eq "$(jb 16)" 2
t "8 cores: 2 jobs"    eq "$(jb 8)" 2
t "7 cores: 1 job"     eq "$(jb 7)" 1
t "4 cores: 1 job"     eq "$(jb 4)" 1
t "2 cores: 1 job (floor)"  eq "$(jb 2)" 1
t "no core count: 1 job"    eq "$(PATH=$base sh "$vs/plan" jobs)" 1

# ---- AC2: measured durations are baked into the scene scripts
mkdir -p "$tmp/sc"
printf 'from manim import *\nDURATION = 0\nclass Clip(Scene): pass\n' > "$tmp/sc/s01.py"
cp "$tmp/sc/s01.py" "$tmp/sc/s02.py"
printf '{"engine":"kokoro","voice":"v","scenes":[\n{"id":"s01","seconds":18.42},\n{"id":"s02","seconds":21.07}\n]}\n' > "$tmp/tb.json"
PATH=$base sh "$vs/plan" bake "$tmp/tb.json" "$tmp/sc" >/dev/null
t "s01 baked"                      grep -qx 'DURATION = 18.42' "$tmp/sc/s01.py"
t "s02 baked"                      grep -qx 'DURATION = 21.07' "$tmp/sc/s02.py"
t "the rest of the script is kept" grep -qx 'class Clip(Scene): pass' "$tmp/sc/s01.py"
printf 'from manim import *\n' > "$tmp/sc/s01.py"
t "a script without DURATION fails" code 1 env PATH="$base" sh "$vs/plan" bake "$tmp/tb.json" "$tmp/sc"

# ---- AC4: tool gate (ffmpeg missing fails the unit at once; manim needs uv, cairo, pkg-config)
gate() { PATH="$1:$base" sh "$vs/plan" gate; }
o=$(gate "$full");                  t "all tools: ok, soft captions" sh -c "printf '%s\n' '$o' | grep -qx ok && printf '%s\n' '$o' | grep -qx captions=soft"
o=$(FAKE_NOSUBS=1 gate "$full");    t "no subtitles filter: sidecar" has "$o" '^captions=sidecar$'
f=$(fakes uv pkg-config say);       o=$(gate "$f"); rc=$?
t "no ffmpeg: failed at once"       sh -c "printf '%s\n' '$o' | grep -qx 'failed: ffmpeg missing, the unit goes to text'"
t "no ffmpeg: exit 1"               code 1 env PATH="$f:$base" sh "$vs/plan" gate
f=$(fakes ffmpeg uv);               t "no pkg-config: names cairo and pkg-config" has "$(gate "$f")" '^failed: manim needs cairo pkg-config$'
f=$(fakes ffmpeg uv); printf '#!/bin/sh\nexit 1\n' > "$f/pkg-config"; chmod +x "$f/pkg-config"
t "no cairo: names cairo"           has "$(gate "$f")" '^failed: manim needs cairo$'
f=$(fakes ffmpeg pkg-config);       t "no uv: names uv"          has "$(gate "$f")" '^failed: manim needs uv$'

# ---- AC4: narration chain kokoro -> say -> none; AC2: all scenes in ONE uv process
nar() { # nar <fakes dir> <work>: run narrate with that PATH, log fresh
  : > "$LOG"; PATH="$1:$base" sh "$vs/narrate" "$sb" "$2" --data-dir "$tmp/data" 2>/dev/null; }
w=$tmp/n1; o=$(nar "$full" "$w")
t "kokoro: engine=kokoro"           has "$o" '^engine=kokoro$'
t "kokoro: no degraded line"        lacks "$o" '^degraded:'
t "kokoro: ONE uv process for 3 scenes" eq "$(grep -c '^uv ' "$LOG")" 1
t "kokoro: no say"                  eq "$(grep -c '^say ' "$LOG")" 0
t "kokoro: timing.json written"     grep -q '"engine":"kokoro"' "$w/timing.json"
f=$(fakes ffmpeg ffprobe say); w=$tmp/n2; o=$(nar "$f" "$w")
t "kokoro hidden (no uv): say"      has "$o" '^engine=say$'
t "say fallback is announced"       has "$o" '^degraded: uv not found, narrated with say$'
t "say: every scene synthesised"    eq "$(grep -c '^say ' "$LOG")" 3
t "say: one voice for all scenes"   eq "$(grep '^say ' "$LOG" | grep -c -- '-v Samantha')" 3
t "say: timing.json from measured durations" sh -c "grep -q '\"engine\":\"say\"' '$w/timing.json' && [ \$(grep -c '\"seconds\":10.50' '$w/timing.json') -eq 3 ]"
f=$(fakes ffmpeg ffprobe say uv); w=$tmp/n3; o=$(FAKE_UV_FAIL=1 nar "$f" "$w")
t "kokoro failing falls back to say" has "$o" '^degraded: kokoro failed, narrated with say$'
t "failed kokoro leaves no half-audio mix" eq "$(ls "$w/audio"/*.wav | wc -l | tr -d ' ')" 3
f=$(fakes ffmpeg ffprobe); w=$tmp/n4; o=$(nar "$f" "$w")
t "kokoro and say hidden: engine=none" has "$o" '^engine=none$'
t "none: announced with the reason"    has "$o" '^degraded: no narration voice (uv not found, say unavailable), silent video'
t "none: no audio files"               eq "$(ls "$w/audio" | wc -l | tr -d ' ')" 0
t "none: estimated at 2.5 words/s"     sh -c "grep -q '\"id\":\"s01\",\"seconds\":2.40' '$w/timing.json'"   # 6 words
f=$(fakes say ffprobe); w=$tmp/n5; o=$(nar "$f" "$w")
t "ffmpeg hidden: say cannot convert, none" has "$o" '^engine=none$'

# ---- AC3: smoke render first, then rest at min(2, cores/4); failures reported
mk() { rm -rf "$1"; mkdir -p "$1/scenes"; for i in 01 02 03 04 05; do echo x > "$1/scenes/s$i.py"; done; }
RL=$tmp/render.log; CONC=$tmp/conc; export RL CONC
cmdok='echo $ID >> $RL; mkdir -p $CONC; touch $CONC/$ID; ls $CONC | wc -l | tr -d " " >> $CONC.max; sleep 0.4; rm $CONC/$ID; echo clip > $OUT'
rc_() { : > "$RL"; rm -rf "$CONC" "$CONC.max"; FAKE_CORES=$2 PATH="$(fakes nproc):$base" sh "$vs/render" clips "$1" py "$3"; }
mk "$tmp/r1"; o=$(rc_ "$tmp/r1" 8 "$cmdok"); rc=$?
t "render: all clips written"         eq "$(ls "$tmp/r1/clips"/*.mp4 | wc -l | tr -d ' ')" 5
t "render: reports rendered=5"        has "$o" '^rendered=5$'
t "render: exit 0"                    eq "$rc" 0
t "render: s01 smoke runs first"      eq "$(head -n 1 "$RL")" s01
t "render: 8 cores run 2 at a time"   eq "$(awk 'm < $1 { m = $1 } END { print m }' "$CONC.max")" 2
mk "$tmp/r2"; rc_ "$tmp/r2" 4 "$cmdok" >/dev/null
t "render: 4 cores run 1 at a time"   eq "$(awk 'm < $1 { m = $1 } END { print m }' "$CONC.max")" 1
mk "$tmp/r3"; o=$(rc_ "$tmp/r3" 8 '[ $ID != s01 ] && echo $ID >> $RL; [ $ID != s01 ] && echo c > $OUT'); rc=$?
t "smoke failure: exit 3"             eq "$rc" 3
t "smoke failure: named"              has "$o" '^smoke-failed=s01$'
t "smoke failure: nothing else rendered" eq "$(grep -c . "$RL")" 0
mk "$tmp/r4"; o=$(rc_ "$tmp/r4" 8 '[ $ID = s03 ] || echo c > $OUT'); rc=$?
t "scene failure: exit 1"             eq "$rc" 1
t "scene failure: named, others kept" sh -c "printf '%s\n' '$o' | grep -qx 'failed=s03' && printf '%s\n' '$o' | grep -qx 'rendered=4'"
# contact sheet
mk "$tmp/r5"; rc_ "$tmp/r5" 8 "$cmdok" >/dev/null
: > "$LOG"; o=$(PATH="$full:$base" sh "$vs/render" sheet "$tmp/r5")
t "sheet: prints the contact image"   has "$o" 'contact.png$'
t "sheet: one frame per clip"         eq "$(ls "$tmp/r5/sheet" | wc -l | tr -d ' ')" 5
t "sheet: tiles them"                 grep -q 'tile=4x4' "$LOG"
t "sheet: no ffmpeg exits 4"          code 4 env PATH="$base" sh "$vs/render" sheet "$tmp/r5"

# ---- T2: the gate is per renderer, and says whether the fallback is usable
export PREFLIGHT_CHROME_APPS=
hf=$(fakes ffmpeg ffprobe say uv pkg-config node chromium)
o=$(PATH="$hf:$base" sh "$vs/plan" gate hyperframes)
t "hyperframes gate: ok with node and chromium" has "$o" '^ok$'
t "hyperframes gate: manim fallback usable"     has "$o" '^fallback=manim$'
t "manim gate: no fallback"                     has "$(gate "$full")" '^fallback=none$'
f=$(fakes ffmpeg node chromium); o=$(PATH="$f:$base" sh "$vs/plan" gate hyperframes)
t "hyperframes without uv: ok"                  has "$o" '^ok$'
t "hyperframes without uv: fallback none"       has "$o" '^fallback=none$'
f=$(fakes ffmpeg node)
t "hyperframes without chromium: names it"      has "$(PATH="$f:$base" sh "$vs/plan" gate hyperframes)" '^failed: hyperframes needs chromium$'
f=$(fakes ffmpeg chromium)
t "hyperframes without node 22: names it"       has "$(PATH="$f:$base" sh "$vs/plan" gate hyperframes)" '^failed: hyperframes needs node22$'
f=$(fakes node chromium)
t "hyperframes without ffmpeg: failed at once"  has "$(PATH="$f:$base" sh "$vs/plan" gate hyperframes)" '^failed: ffmpeg missing'

# ---- T1: the router's renderer rule = scripts/renderer-pick over shared/renderers.md and preflight.md
rp() { sh "$pl/scripts/renderer-pick" "$pl/shared/renderers.md" "$@"; }
pf=$pl/scripts/preflight
pfmd() { d=$(mktemp -d "$tmp/lesson.XXXXXX"); PATH="$1:$base" sh "$pf" "$d" >/dev/null; echo "$d/preflight.md"; }
all=$(pfmd "$(fakes ffmpeg uv pkg-config node chromium)")
t "all tiers: the pick (hyperframes, tier 3)"   eq "$(rp 3 "$all" | tr '\n' ' ')" "renderer: hyperframes tier: 3 "
t "every hyperframes row picks hyperframes"     eq "$(for r in 3 4 5; do rp $r "$all" | head -n 1; done | sort -u)" "renderer: hyperframes"
t "manim rows pick manim at tier 2"             eq "$(for r in 1 2; do rp $r "$all" | tr '\n' ' '; done)" "renderer: manim tier: 2 renderer: manim tier: 2 "
t3off=$(pfmd "$(fakes ffmpeg uv pkg-config)")
o=$(rp 4 "$t3off")
t "pick's tier missing: the fallback, tier 2"   has "$o" '^renderer: manim$'
t "downgrade carries the note"                  has "$o" '^downgraded: renderer manim (hyperframes needs node 22+, headless chromium)$'
t "downgrade writes no prediction"              eq "$(printf '%s\n' "$o" | grep -c predicted)" 0
t "manim row is not downgraded when tier 2 is there" eq "$(rp 1 "$t3off" | wc -l | tr -d ' ')" 2
none=$(pfmd "$(fakes ffmpeg)")
o=$(rp 5 "$none")
t "neither tier: the pick is kept"              has "$o" '^renderer: hyperframes$'
t "neither tier: failure predicted with the gaps" has "$o" '^predicted: node 22+, headless chromium missing$'
t "neither tier: no downgrade"                  eq "$(printf '%s\n' "$o" | grep -c downgraded)" 0
t "manim row without its tier: predicted, no fallback" has "$(rp 2 "$none")" '^predicted: uv, cairo, pkg-config missing$'
nof=$(pfmd "$(fakes node chromium)")
t "no ffmpeg: both tiers unusable, predicted"   has "$(rp 3 "$nof")" '^predicted: ffmpeg missing$'
t "no preflight.md: the pick, no prediction"    eq "$(rp 3 "$tmp/none.md" | tr '\n' ' ')" "renderer: hyperframes tier: 3 "
t "a row that does not exist fails"             code 2 sh "$pl/scripts/renderer-pick" "$pl/shared/renderers.md" 9

# ---- T2: baking reaches an .html scene (DURATION line and data-duration)
mkdir -p "$tmp/hs"
printf '<div data-duration="0">\n<script>\nDURATION = 0\n</script>\n' > "$tmp/hs/s01.html"
PATH=$base sh "$vs/plan" bake "$tmp/tb.json" "$tmp/hs" >/dev/null
t "html scene: DURATION line baked"             grep -qx 'DURATION = 18.42' "$tmp/hs/s01.html"
t "html scene: data-duration baked"             grep -q 'data-duration="18.42"' "$tmp/hs/s01.html"

# ---- T2/T3: render blank and verdict
mk "$tmp/b1"
printf '{"engine":"kokoro","voice":"v","scenes":[\n{"id":"s01","seconds":18.42},\n{"id":"s02","seconds":21.07},\n{"id":"s03","seconds":19.00},\n{"id":"s04","seconds":20.00},\n{"id":"s05","seconds":20.00}\n]}\n' > "$tmp/b1/timing.json"
: > "$LOG"; o=$(PATH="$full:$base" sh "$vs/render" blank "$tmp/b1" s03); rc=$?
t "blank: prints the degraded line"             eq "$o" "degraded: s03 blank"
t "blank: a clip of the scene's D exists"       sh -c "[ $rc -eq 0 ] && [ -s '$tmp/b1/clips/s03.mp4' ] && grep -q 'color=c=0x111827:s=1280x720:r=30:d=19.00' '$LOG'"
t "blank: s03 recorded"                         grep -qx s03 "$tmp/b1/blank.txt"
PATH="$full:$base" sh "$vs/render" blank "$tmp/b1" s03 >/dev/null
t "blank: twice records it once"                eq "$(grep -c s03 "$tmp/b1/blank.txt")" 1
o=$(PATH="$full:$base" sh "$vs/render" blank "$tmp/b1" s01); rc=$?
t "s01 never blanks: failed, exit 3"            sh -c "[ $rc -eq 3 ] && printf '%s\n' '$o' | grep -qx 'failed: s01 failed on both renderers'"
t "s01 never blanks: no clip made"              test ! -e "$tmp/b1/clips/s01.mp4"
t "blank without ffmpeg: exit 4"                code 4 env PATH="$base" sh "$vs/render" blank "$tmp/b1" s02
t "verdict: 1 of 5 blank is ok"                 eq "$(sh "$vs/render" verdict "$tmp/b1")" "ok blank=1/5"
PATH="$full:$base" sh "$vs/render" blank "$tmp/b1" s04 >/dev/null
t "verdict: 2 of 5 blank is ok"                 eq "$(sh "$vs/render" verdict "$tmp/b1")" "ok blank=2/5"
PATH="$full:$base" sh "$vs/render" blank "$tmp/b1" s05 >/dev/null
o=$(sh "$vs/render" verdict "$tmp/b1"); rc=$?
t "verdict: 3 of 5 blank (more than half): failed" sh -c "[ $rc -eq 1 ] && printf '%s\n' '$o' | grep -qx 'failed: 3 of 5 scenes blank'"
printf '{"engine":"kokoro","voice":"v","scenes":[\n{"id":"s01","seconds":10},\n{"id":"s02","seconds":10}\n]}\n' > "$tmp/b1/timing.json"; printf 's02\n' > "$tmp/b1/blank.txt"
t "verdict: exactly half blank is not more than half" code 0 sh "$vs/render" verdict "$tmp/b1"
rm "$tmp/b1/blank.txt"
t "verdict: none blank"                         eq "$(sh "$vs/render" verdict "$tmp/b1")" "ok blank=0/2"

# a scene that failed on the picked renderer is settled alone: render one, then the rest skip a finished s01
mk "$tmp/b2"
: > "$RL"; o=$(rc_ "$tmp/b2" 8 '[ $ID = s01 ] || { echo $ID >> $RL; echo c > $OUT; }'); rc=$?
t "picked renderer fails s01: smoke-failed, exit 3, nothing else" sh -c "[ $rc -eq 3 ] && printf '%s\n' '$o' | grep -qx smoke-failed=s01 && [ ! -s '$RL' ]"
t "failed render leaves no clip behind"         test ! -e "$tmp/b2/clips/s01.mp4"
PATH="$base" sh "$vs/render" one "$tmp/b2" py 'echo c > $OUT' s01; rc=$?
t "fallback rewrite of s01 renders with one"    sh -c "[ $rc -eq 0 ] && [ -s '$tmp/b2/clips/s01.mp4' ]"
: > "$RL"; o=$(rc_ "$tmp/b2" 8 '[ $ID = s01 ] && exit 1; echo $ID >> $RL; [ $ID = s03 ] || echo c > $OUT'); rc=$?
t "re-run skips the finished s01 smoke"         sh -c "! grep -qx s01 '$RL' && grep -qx s02 '$RL'"
t "re-run names the scene that still fails"     sh -c "[ $rc -eq 1 ] && printf '%s\n' '$o' | grep -qx failed=s03 && printf '%s\n' '$o' | grep -qx rendered=4"

# ---- assembly: normalise to D, sentence captions from D, soft track only when the probe allows
aw=$tmp/aw; mkdir -p "$aw/clips" "$aw/audio" "$aw/narration"
printf 'Hello there. How are you today?\n' > "$aw/narration/s01.txt"
printf 'One two three four.\n' > "$aw/narration/s02.txt"
for i in 01 02; do echo c > "$aw/clips/s$i.mp4"; echo a > "$aw/audio/s$i.wav"; done
printf '{"engine":"kokoro","voice":"v","scenes":[\n{"id":"s01","seconds":10.00},\n{"id":"s02","seconds":20.00}\n]}\n' > "$aw/timing.json"
printf -- '- ffmpeg: true (subtitles filter: true)\n' > "$tmp/pf-yes.md"
printf -- '- ffmpeg: true (subtitles filter: false)\n' > "$tmp/pf-no.md"
asm() { : > "$LOG"; PATH="$full:$base" sh "$vs/assemble" "$aw" "$tmp/out.mp4" "$@"; }
o=$(asm --preflight "$tmp/pf-yes.md")
t "assemble: summary line"            eq "$o" "scenes=2 seconds=30 captions=soft narration=kokoro"
t "assemble: mp4 written"             test -s "$tmp/out.mp4"
t "assemble: each clip held/cut to its D" sh -c "grep -q -- '-t 10.00' '$LOG' && grep -q -- '-t 20.00' '$LOG' && grep -q 'tpad=stop_mode=clone:stop_duration=20.00' '$LOG'"
t "assemble: audio padded to D"       grep -q 'apad=whole_dur=10.00' "$LOG"
t "assemble: soft mov_text track"     grep -q 'mov_text' "$LOG"
want="1
00:00:00,000 --> 00:00:03,333
Hello there.

2
00:00:03,333 --> 00:00:10,000
How are you today?

3
00:00:10,000 --> 00:00:30,000
One two three four.
"
t "assemble: sentence SRT from measured durations" eq "$(cat "$tmp/out.srt")" "$(printf '%s' "$want")"
o=$(asm --preflight "$tmp/pf-no.md")
t "no subtitles filter: sidecar only" eq "$o" "scenes=2 seconds=30 captions=sidecar narration=kokoro"
t "sidecar: no mov_text"              lacks "$(cat "$LOG")" 'mov_text'
t "sidecar: srt still written"        test -s "$tmp/out.srt"
o=$(asm); t "no preflight: sidecar"   has "$o" 'captions=sidecar'
rm "$aw/clips/s02.mp4"
t "missing clip: exit 1"              code 1 env PATH="$full:$base" sh "$vs/assemble" "$aw" "$tmp/out.mp4"
echo c > "$aw/clips/s02.mp4"
t "no ffmpeg: exit 4"                 code 4 env PATH="$base" sh "$vs/assemble" "$aw" "$tmp/out.mp4"
# silent video: no audio track, narration script written
sed 's/"kokoro"/"none"/' "$aw/timing.json" > "$aw/t.json" && mv "$aw/t.json" "$aw/timing.json"
o=$(asm --script "$tmp/out.narration.md")
t "silent: narration=none"            has "$o" 'narration=none$'
t "silent: no audio inputs, -an"      sh -c "! grep -q 'audio/' '$LOG' && grep -q -- ' -an ' '$LOG'"
t "silent: narration script written"  sh -c "grep -q '^## s01' '$tmp/out.narration.md' && grep -q 'How are you today' '$tmp/out.narration.md'"

# ---- AC5: preflight reports the tier-2 probes (cairo and pkg-config)
pf=$pl/scripts/preflight
f=$(fakes pkg-config); o=$(PATH="$f:$base" sh "$pf")
t "preflight reports pkg_config and cairo" has "$o" '"pkg_config":true,"cairo":true'
mkdir "$tmp/lesson"; PATH="$f:$base" sh "$pf" "$tmp/lesson" >/dev/null
f=$(fakes); PATH="$f:$base" sh "$pf" "$tmp/lesson" >/dev/null
t "preflight.md names the missing cairo install" grep -q 'brew install cairo pkg-config' "$tmp/lesson/preflight.md"

# ---- seams: the skill, its files and the wiring exist
sk=$pl/skills/video
t "video skill files exist"           sh -c "[ -f '$sk/SKILL.md' ] && [ -f '$sk/narrate.md' ] && [ -f '$sk/assemble.md' ] && [ -f '$sk/refs/manim.md' ]"
fm=$(sed -n '2,/^---$/p' "$sk/SKILL.md")
t "frontmatter: name video"           has "$fm" '^name: video$'
t "frontmatter: hidden"               has "$fm" '^user-invocable: false$'
t "frontmatter: unit-subagent description" has "$fm" 'Runs in a unit subagent; spawns none\.'
t "frontmatter: compatibility line"   has "$fm" '^compatibility: '
for s in plan narrate render assemble kokoro.py; do
  t "script $s exists"                test -f "$vs/$s"
done
t "scripts are executable"            sh -c "[ -x '$vs/plan' ] && [ -x '$vs/narrate' ] && [ -x '$vs/render' ] && [ -x '$vs/assemble' ]"
t "kokoro.py pins its dependency"     grep -q 'kokoro-onnx==' "$vs/kokoro.py"
for k in 'plan gate' 'plan scenes' 'plan storyboard' 'narrate' 'plan check' 'plan bake' 'render clips' 'render sheet' 'assemble'; do
  t "SKILL.md wires '$k'"             grep -q "$k" "$sk/SKILL.md"
done
t "refs/manim.md names the render command" grep -q 'manim\[typst\]==' "$sk/refs/manim.md"
t "router plans video units"          sh -c "grep -q 'renderer-pick' '$pl/skills/router/SKILL.md' && grep -q 'shared/renderers.md' '$pl/skills/router/SKILL.md' && grep -q 'u1-video.mp4' '$pl/skills/router/SKILL.md'"
t "conductor invokes learn-anything:video" grep -q 'learn-anything:video' "$pl/skills/learn/SKILL.md"
t "dispatch gives video an .mp4"      grep -q '`mp4` for video' "$pl/skills/learn/dispatch.md"
t "footer lists the video notes keys" sh -c "grep -q 'video .scenes=<n>., .seconds=<n>., .captions=sidecar|soft|none., .narration=kokoro|say|none.' '$pl/shared/footer.md'"
rf=$sk/refs/hyperframes.md
t "refs/hyperframes.md exists"                  test -f "$rf"
t "hyperframes is pinned to an exact version"   grep -Eq 'hyperframes@[0-9]+\.[0-9]+\.[0-9]+ render' "$rf"
t "hyperframes render never uses @latest"       sh -c "! grep -q 'hyperframes@latest' '$rf'"
t "hyperframes render has telemetry off"        grep -q 'HYPERFRAMES_NO_TELEMETRY=1.*npx' "$rf"
t "hyperframes render has frame streaming on"   grep -q 'HF_CAPTURE_PARALLEL_STREAM=true.*npx' "$rf"
t "hyperframes install lives in the data dir"   grep -q 'npm_config_cache=<data>/npm' "$rf"
rr=$pl/shared/renderers.md
t "renderers.md has five rows"                  eq "$(grep -c '^| [1-5] |' "$rr")" 5
t "three rows pick hyperframes and fall back to manim" eq "$(grep -c '| hyperframes | manim | 3 |' "$rr")" 3
t "two rows pick manim with no fallback"        eq "$(grep -c '| manim | none | 2 |' "$rr")" 2
for k in 'render one' 'render blank' 'render verdict' 'plan gate <renderer>' 'refs/hyperframes.md' 'fallback=manim'; do
  t "SKILL.md wires '$k'"                       grep -q "$k" "$sk/SKILL.md"
done
t "gate step prints the consent line"           grep -q 'consent:' "$pl/skills/learn/gate.md"
t "gate passes the data dir for the kokoro check" grep -q -- '--data-dir ${CLAUDE_PLUGIN_DATA}' "$pl/skills/learn/gate.md"
t "plugin lint passes"                sh "$pl/scripts/lint-skills"

[ "$fails" -eq 0 ] && echo "all passed"
exit "$fails"
