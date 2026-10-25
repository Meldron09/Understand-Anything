# Shared helpers for the deterministic suites. Source after `fails=0`: . "$here/../lib.sh"
#   t <desc> <cmd...>   run cmd; print `ok   desc` or `FAIL desc` and count the failure in $fails
#   has <text> <regex>  text matches the grep pattern
#   eq <a> <b>          strings are equal
t() { desc=$1; shift; if "$@"; then echo "ok   $desc"; else echo "FAIL $desc"; fails=$((fails + 1)); fi; }
has() { printf '%s\n' "$1" | grep -q -- "$2"; }
eq() { [ "$1" = "$2" ]; }
