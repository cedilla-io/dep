export GIT_AUTHOR_NAME="test"
export GIT_AUTHOR_EMAIL="test@test"
export GIT_COMMITTER_NAME="test"
export GIT_COMMITTER_EMAIL="test@test"

TEST_ROOT="$WORK/t26"
REMOTE_ROOT="$TEST_ROOT/remotes"
SEED_ROOT="$TEST_ROOT/seed"

mkdir -p "$REMOTE_ROOT/acme" "$SEED_ROOT"
write_manifest "$TEST_ROOT/@manifest"
cd "$TEST_ROOT"

export GIT_CONFIG_GLOBAL="$TEST_ROOT/.gitconfig"

# 1) HTTPS explicite

git init "$SEED_ROOT/http-tool" -q
git -C "$SEED_ROOT/http-tool" checkout -b main -q
printf 'http tool\n' > "$SEED_ROOT/http-tool/readme.txt"
git -C "$SEED_ROOT/http-tool" add -A
git -C "$SEED_ROOT/http-tool" commit -m "init http tool" -q
git init --bare "$REMOTE_ROOT/acme/http-tool.git" -q
git -C "$SEED_ROOT/http-tool" remote add origin "$REMOTE_ROOT/acme/http-tool.git"
git -C "$SEED_ROOT/http-tool" push -u origin main -q

git config --global url."file://$REMOTE_ROOT/".insteadOf https://code.test/

$DEP add "https://code.test/acme/http-tool.git@main"
assert "https explicite: lien ref" 'test -L .@/http-tool@main'
assert "https explicite: contenu" 'test "$(cat .@/http-tool@main/readme.txt)" = "http tool"'
assert "https explicite: lock source" 'grep -q "https://code.test/acme/http-tool.git@main#" @lock'

# 2) source implicite => ssh puis https fallback

git init "$SEED_ROOT/fallback-tool" -q
git -C "$SEED_ROOT/fallback-tool" checkout -b main -q
printf 'fallback tool\n' > "$SEED_ROOT/fallback-tool/version.txt"
git -C "$SEED_ROOT/fallback-tool" add -A
git -C "$SEED_ROOT/fallback-tool" commit -m "init fallback tool" -q
git init --bare "$REMOTE_ROOT/acme/fallback-tool.git" -q
git -C "$SEED_ROOT/fallback-tool" remote add origin "$REMOTE_ROOT/acme/fallback-tool.git"
git -C "$SEED_ROOT/fallback-tool" push -u origin main -q

export GIT_SSH_COMMAND='ssh -o BatchMode=yes -o ConnectTimeout=1'

$DEP add "code.test:acme/fallback-tool@main"
assert "fallback: lien ref" 'test -L .@/fallback-tool@main'
assert "fallback: contenu" 'test "$(cat .@/fallback-tool@main/version.txt)" = "fallback tool"'
assert "fallback: lock conserve source" 'grep -q "code.test:acme/fallback-tool@main#" @lock'

unset GIT_CONFIG_GLOBAL
unset GIT_SSH_COMMAND
