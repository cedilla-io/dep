mkdir -p "$WORK/t25/lib"
write_manifest "$WORK/t25/@manifest" "./lib"

out_default=$(cd "$WORK/t25" && "$DEP" sync 2>&1)
assert "pas de logs verbose par défaut" "! printf '%s' \"$out_default\" | grep -q '\\[dep\\]\\[sync\\]'"

out_verbose=$(cd "$WORK/t25" && DEP_VERBROSE=1 "$DEP" sync 2>&1)
assert "logs verbose activés via DEP_VERBROSE" "printf '%s' \"$out_verbose\" | grep -q '\\[dep\\]\\[sync\\] link fs'"

out_verbose_ok=$(cd "$WORK/t25" && DEP_VERBOSE=1 "$DEP" sync 2>&1)
assert "logs verbose activés via DEP_VERBOSE" "printf '%s' \"$out_verbose_ok\" | grep -q '\\[dep\\]\\[sync\\] link fs'"
