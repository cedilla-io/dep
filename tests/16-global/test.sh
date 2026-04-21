ORIG_HOME="$HOME"
export HOME="$WORK/t16/fakehome"
mkdir -p "$HOME"

$DEP global init
assert "@manifest global créé" 'test -f "$HOME/.dep/@manifest"'

mkdir -p "$WORK/t16/mylib"
printf 'global lib\n' > "$WORK/t16/mylib/lib.txt"

$DEP global add "$WORK/t16/mylib"
assert "dep ajoutée au @manifest global" 'grep -q "mylib" "$HOME/.dep/@manifest"'
assert "symlink global" 'test -L "$HOME/.dep/.@/mylib"'

out=$($DEP global list)
assert "list global affiche mylib" 'echo "$out" | grep -q "mylib.*ok"'

$DEP global remove mylib
assert "mylib supprimé du store global" '! test -L "$HOME/.dep/.@/mylib"'

export HOME="$ORIG_HOME"
