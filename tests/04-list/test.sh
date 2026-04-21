mkdir -p "$WORK/t04/libs/x"
write_manifest "$WORK/t04/@manifest" './libs/x'
cd "$WORK/t04"

$DEP sync
out=$($DEP list)
assert "affiche x ok" 'echo "$out" | grep -q "x.*ok"'
