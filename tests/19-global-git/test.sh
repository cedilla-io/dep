ORIG_HOME="$HOME"
ORIG_AUTO_TRUST="${DEP_AUTO_TRUST:-}"
export HOME="$WORK/t19/fakehome"
mkdir -p "$HOME"

export GIT_AUTHOR_NAME="test"
export GIT_AUTHOR_EMAIL="test@test"
export GIT_COMMITTER_NAME="test"
export GIT_COMMITTER_EMAIL="test@test"

# repo git avec @scripts (global_install)
git init "$WORK/repos/global-tool" -q
write_manifest "$WORK/repos/global-tool/@manifest"
printf 'global tool content\n' > "$WORK/repos/global-tool/tool.txt"

cat > "$WORK/repos/global-tool/@scripts" <<'EOF'
global_install()(
  printf 'global-installed\n' > "$PWD/.hook-ran"
)

global_uninstall()(
  rm -f "$PWD/.hook-ran"
)
EOF

git -C "$WORK/repos/global-tool" add -A
git -C "$WORK/repos/global-tool" commit -m "init" -q

# --- sans trust : hook ne tourne pas ---
unset DEP_AUTO_TRUST

$DEP global init
if command -v setsid >/dev/null 2>&1; then
  setsid "$DEP" global add "$WORK/repos/global-tool@master" </dev/null 2>/dev/null || true
else
  $DEP global add "$WORK/repos/global-tool@master" </dev/null 2>/dev/null || true
fi

assert "dep git globale clonée" 'test -L "$HOME/.dep/.@/global-tool@master"'
assert "pas de lien court git global" '! test -e "$HOME/.dep/.@/global-tool"'
assert "contenu cloné" 'test "$(cat "$HOME/.dep/.@/global-tool@master/tool.txt")" = "global tool content"'
assert "pas de trust" '! test -f "$HOME/.dep/.@/trust"'
assert "hook non exécuté sans trust" '! test -f "$HOME/.dep/.@/global-tool@master/.hook-ran"'

# --- avec trust : hook tourne ---
printf 'YES\n' > "$HOME/.dep/.@/trust"
$DEP global sync </dev/null 2>/dev/null

assert "global_install exécuté avec trust" 'test -f "$HOME/.dep/.@/global-tool@master/.hook-ran"'
assert "contenu hook" 'test "$(cat "$HOME/.dep/.@/global-tool@master/.hook-ran")" = "global-installed"'

# --- remove respecte trust ---
$DEP global remove global-tool 2>/dev/null
assert "hook uninstall exécuté" '! test -f "$HOME/.dep/.@/global-tool@master/.hook-ran"'
assert "dep supprimée" '! test -L "$HOME/.dep/.@/global-tool@master"'

# --- auto-trust global ---
export DEP_AUTO_TRUST=1
$DEP global add "$WORK/repos/global-tool@master" 2>/dev/null

assert "auto-trust global crée le fichier" 'test -f "$HOME/.dep/.@/trust"'
assert "auto-trust global hook exécuté" 'test -f "$HOME/.dep/.@/global-tool@master/.hook-ran"'

# --- global list ---
out=$($DEP global list)
assert "list global affiche global-tool" 'echo "$out" | grep -q "global-tool.*ok"'

export HOME="$ORIG_HOME"
export DEP_AUTO_TRUST="${ORIG_AUTO_TRUST:-1}"
