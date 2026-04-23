ORIG_HOME="$HOME"
export HOME="$WORK/t20/fakehome"
mkdir -p "$HOME"

export GIT_AUTHOR_NAME="test"
export GIT_AUTHOR_EMAIL="test@test"
export GIT_COMMITTER_NAME="test"
export GIT_COMMITTER_EMAIL="test@test"

# créer un repo avec global_uninstall
git init "$WORK/repos/reinstall-tool" -q
write_manifest "$WORK/repos/reinstall-tool/@manifest"
printf 'tool data\n' > "$WORK/repos/reinstall-tool/tool.txt"

cat > "$WORK/repos/reinstall-tool/@scripts" <<'EOF'
global_install()(
  printf 'installed\n' > "$HOME/.dep-marker"
)

global_uninstall()(
  rm -f "$HOME/.dep-marker"
)
EOF

git -C "$WORK/repos/reinstall-tool" add -A
git -C "$WORK/repos/reinstall-tool" commit -m "init" -q

# première install
export DEP_AUTO_TRUST=1
sh "$DEP_ROOT/install.sh" -l 2>/dev/null

"$HOME/.local/bin/dep" global init 2>/dev/null
"$HOME/.local/bin/dep" global add "$WORK/repos/reinstall-tool@master" 2>/dev/null

assert "marker créé par global_install" 'test -f "$HOME/.dep-marker"'

# réinstallation — doit exécuter global_uninstall puis réinstaller
sh "$DEP_ROOT/install.sh" -l 2>/dev/null

assert "global_uninstall exécuté lors de la réinstall" '! test -f "$HOME/.dep-marker"'
assert "dep toujours installé" 'test -x "$HOME/.local/bin/dep"'
assert "@manifest global préservé" '! test -f "$HOME/.dep/@manifest"'

# nettoyage
sh "$DEP_ROOT/uninstall.sh" 2>/dev/null

export HOME="$ORIG_HOME"
