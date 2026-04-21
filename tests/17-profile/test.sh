ORIG_HOME="$HOME"
export HOME="$WORK/t17/fakehome"
mkdir -p "$HOME/.dep"

# source lib pour avoir les primitives
. "$DEP_ROOT/commands/_lib.sh"

dep_profile_add "mytool" 'export MYTOOL_HOME="$HOME/.dep/.@/mytool"'
assert "env.sh existe" 'test -f "$HOME/.dep/env.sh"'
assert "bloc mytool présent" 'grep -q "dep:mytool" "$HOME/.dep/env.sh"'
assert "contenu mytool" 'grep -q "MYTOOL_HOME" "$HOME/.dep/env.sh"'

dep_profile_add "sdk" 'export SDK_HOME="$HOME/.dep/.@/sdk"'
assert "bloc sdk présent" 'grep -q "dep:sdk" "$HOME/.dep/env.sh"'

dep_profile_remove "mytool"
assert "bloc mytool retiré" '! grep -q "dep:mytool" "$HOME/.dep/env.sh"'
assert "bloc sdk intact" 'grep -q "dep:sdk" "$HOME/.dep/env.sh"'

dep_path_add "/usr/local/foo/bin"
assert "path ajouté" 'grep -q "/usr/local/foo/bin" "$HOME/.dep/env.sh"'

dep_path_remove "/usr/local/foo/bin"
assert "path retiré" '! grep -q "/usr/local/foo/bin" "$HOME/.dep/env.sh"'

dep_profile_remove "sdk"
assert "env.sh vide" 'test ! -s "$HOME/.dep/env.sh" || ! grep -q "[a-zA-Z]" "$HOME/.dep/env.sh"'

export HOME="$ORIG_HOME"
