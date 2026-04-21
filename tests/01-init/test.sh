mkdir -p "$WORK/t01"
cd "$WORK/t01"

$DEP init
assert "crée @manifest" 'test -f @manifest'
assert "@manifest première ligne = version" 'test "$(head -1 @manifest)" = "$DEP_TOOL_VERSION"'

out=$($DEP init 2>&1 || true)
assert "refuse de réinitialiser" 'echo "$out" | grep -q "initialisé"'
