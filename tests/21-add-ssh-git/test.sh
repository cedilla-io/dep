export GIT_AUTHOR_NAME="test"
export GIT_AUTHOR_EMAIL="test@test"
export GIT_COMMITTER_NAME="test"
export GIT_COMMITTER_EMAIL="test@test"

TEST_ROOT="$WORK/t21"
REMOTE_ROOT="$TEST_ROOT/remotes"
SEED_ROOT="$TEST_ROOT/seed"

mkdir -p "$REMOTE_ROOT/acme" "$SEED_ROOT"
write_manifest "$TEST_ROOT/@manifest"
cd "$TEST_ROOT"

export GIT_CONFIG_GLOBAL="$TEST_ROOT/.gitconfig"

git init "$SEED_ROOT/tool" -q
git -C "$SEED_ROOT/tool" checkout -b main -q
printf 'tool main\n' > "$SEED_ROOT/tool/readme.txt"
git -C "$SEED_ROOT/tool" add -A
git -C "$SEED_ROOT/tool" commit -m "init tool" -q
git init --bare "$REMOTE_ROOT/acme/tool" -q
git -C "$SEED_ROOT/tool" remote add origin "$REMOTE_ROOT/acme/tool"
git -C "$SEED_ROOT/tool" push -u origin main -q

git init "$SEED_ROOT/plugin" -q
git -C "$SEED_ROOT/plugin" checkout -b main -q
printf 'plugin main\n' > "$SEED_ROOT/plugin/version.txt"
cat > "$SEED_ROOT/plugin/@scripts" <<'SH'
custom_command()(
  printf 'plugin task ok\n' > custom-command.txt
)
SH
git -C "$SEED_ROOT/plugin" add -A
git -C "$SEED_ROOT/plugin" commit -m "init plugin" -q
git -C "$SEED_ROOT/plugin" checkout -b release/v1 -q
printf 'plugin release\n' > "$SEED_ROOT/plugin/version.txt"
git -C "$SEED_ROOT/plugin" add -A
git -C "$SEED_ROOT/plugin" commit -m "release plugin" -q
git init --bare "$REMOTE_ROOT/acme/plugin.git" -q
git -C "$SEED_ROOT/plugin" remote add origin "$REMOTE_ROOT/acme/plugin.git"
git -C "$SEED_ROOT/plugin" push -u origin main release/v1 -q

git config --global url."file://$REMOTE_ROOT/".insteadOf git@code.test:

$DEP add "code.test:acme/tool@main"
assert ".@/tool@main est un symlink" 'test -L .@/tool@main'
assert "pas de lien court git" '! test -e .@/tool'
assert "contenu clone ssh sans git@" 'test "$(cat .@/tool@main/readme.txt)" = "tool main"'
assert "@lock contient la source ssh sans git@ + ref" 'grep -q "code.test:acme/tool@main#" @lock'

$DEP add "git@code.test:acme/plugin.git@release/v1"
assert ".@/plugin@release_v1 est un symlink" 'test -L .@/plugin@release_v1'
assert "pas de lien court git" '! test -e .@/plugin'
assert "nom dérivé sans suffixe .git" '! test -e .@/plugin.git'
assert "contenu clone ssh avec branche slash" 'test "$(cat .@/plugin@release_v1/version.txt)" = "plugin release"'
assert "@lock contient la source ssh avec git@ + ref" 'grep -q "git@code.test:acme/plugin.git@release/v1#" @lock'
$DEP custom_command
assert "custom command dep exécutée sans ambiguïté" 'test "$(cat custom-command.txt)" = "plugin task ok"'

unset GIT_CONFIG_GLOBAL
