#!/bin/sh
# Script-CLI tests for learn-anything/scripts/preflight under controlled PATH values: a scratch bin
# holds symlinks to grep/sed/mkdir plus stub tools, so each probe is tested with and without its tool.
# Run: sh tests/preflight/run.sh
here=$(cd "$(dirname "$0")" && pwd)
pf="$here/../../learn-anything/scripts/preflight"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
fails=0
base=$tmp/base; mkdir "$base"
for t in grep sed mkdir; do ln -s "$(command -v $t)" "$base/$t"; done

# stub <dir> <name> [body]: an executable that runs body (default: exit 0)
stub() { printf '#!/bin/sh\n%s\n' "${3:-exit 0}" > "$1/$2"; chmod +x "$1/$2"; }
# bin <name>...: a fresh PATH dir with the named stubs; prints its path

bin() {
  d=$(mktemp -d "$tmp/bin.XXXXXX")
  for t in "$@"; do
    case $t in
      ffmpeg) stub "$d" ffmpeg 'echo " T. subtitles       V->V  Render text subtitles"';;
      ffmpeg-nosub) stub "$d" ffmpeg 'echo " T. scale V->V"';;
      pkg-config-nocairo) stub "$d" pkg-config 'exit 1';;
      pkg-config) stub "$d" pkg-config '[ "$1" = --exists ] && [ "$2" = cairo ]';;
      node21) stub "$d" node 'echo v21.9.0';;
      node22) stub "$d" node 'echo v22.3.0';;
      *) stub "$d" "$t";;
    esac
  done
  echo "$d"
}
run() { PATH="$base:$1" PREFLIGHT_CHROME_APPS="" /bin/sh "$pf" $2 2>&1; echo "rc=$?"; }
# expect <name> <pathdir> <substring> [folder]
expect() {
  out=$(run "$2" "$4")
  case $out in *"$3"*) echo "ok   $1";; *) echo "FAIL $1: lacks '$3'"; echo "$out"; fails=$((fails + 1));; esac
}

e=$(bin)
expect "empty PATH: exit zero"             "$e" 'rc=0'
expect "empty PATH: tier 0 only"           "$e" '"tiers":{"0":true,"1":false,"2":false,"3":false}'
expect "uv gives tier 1"                   "$(bin uv)" '"1":true,"2":false'
expect "ffmpeg without uv is not tier 2"   "$(bin ffmpeg pkg-config)" '"2":false'
expect "uv+ffmpeg+cairo gives tier 2"      "$(bin uv ffmpeg pkg-config)" '"2":true'
expect "ffmpeg subtitles filter detected"  "$(bin ffmpeg)" '"ffmpeg_subtitles":true'
expect "ffmpeg without subtitles filter"  "$(bin ffmpeg-nosub)" '"ffmpeg_subtitles":false'
expect "pkg-config with cairo"             "$(bin pkg-config)" '"pkg_config":true,"cairo":true'
expect "pkg-config without cairo"          "$(bin pkg-config-nocairo)" '"pkg_config":true,"cairo":false'
expect "node 21 is too old"                "$(bin node21)" '"node22":false,"node_version":"21.9.0"'
expect "node 22 accepted"                  "$(bin node22)" '"node22":true,"node_version":"22.3.0"'
expect "node 22 + chromium gives tier 3"   "$(bin node22 chromium)" '"3":true'
expect "node 22 alone is not tier 3"       "$(bin node22)" '"3":false'
expect "chrome on PATH counts"             "$(bin google-chrome)" '"chromium":true'
expect "marp detected"                     "$(bin marp)" '"marp":true,"npx":false'
expect "npx detected"                      "$(bin npx)" '"marp":false,"npx":true'
expect "pdftotext detected"                "$(bin pdftotext)" '"pdftotext":true'
expect "say detected"                      "$(bin say)" '"say":true'
expect "no say"                            "$e" '"say":false'

# preflight.md content, and nothing is written without a folder argument
f=$tmp/lesson/nested
expect "writes preflight.md"               "$e" 'rc=0' "$f"
for want in 'brew install uv' 'brew install ffmpeg' 'brew install cairo pkg-config' 'brew install node' \
            'brew install --cask google-chrome' 'brew install poppler' '~40 MB'; do
  if grep -qF -- "$want" "$f/preflight.md"; then echo "ok   missing report names '$want'"
  else echo "FAIL missing report lacks '$want'"; fails=$((fails + 1)); fi
done
all=$(bin uv ffmpeg pkg-config node22 chromium marp pdftotext say)
run "$all" "$tmp/full" >/dev/null
if grep -q 'brew install' "$tmp/full/preflight.md"; then echo "FAIL nothing missing but install commands listed"; fails=$((fails + 1))
else echo "ok   no install commands when nothing is missing"; fi
[ -z "$(ls "$e")" ] && echo "ok   nothing installed or created on PATH" || { echo "FAIL PATH dir changed"; fails=$((fails + 1)); }

[ "$fails" -eq 0 ] && echo "all passed"
exit "$fails"
