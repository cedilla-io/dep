#!/bin/sh

if ! command -v assert >/dev/null 2>&1; then
  assert()(
    if eval "$2"; then
      printf "  ok  %s\n" "$1"
    else
      printf "  ERR %s\n" "$1"
      return 1
    fi
  )
fi

TEST_SCRIPT=${test:-$0}
TEST_DIR=$(CDPATH= cd -- "$(dirname -- "$TEST_SCRIPT")" && pwd)
SANDBOX="$TEST_DIR/sandbox"
WORKSPACE="$SANDBOX/workspace"
REPOS="$SANDBOX/repos"
DEP_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd)
DEP=${DEP:-$DEP_ROOT/dep}
DEP_TOOL_VERSION=$(sed -n '1p' "$DEP_ROOT/VERSION")
export DEP_AUTO_TRUST=1

write_manifest()(
  file="$1"
  shift

  mkdir -p "$(dirname -- "$file")"

  {
    printf '%s\n' "$DEP_TOOL_VERSION"
    for dep do
      printf '%s\n' "$dep"
    done
  } > "$file"
)

git_commit_all()(
  repo="$1"
  message="$2"

  git -C "$repo" add -A
  git -C "$repo" commit -m "$message" -q
)

git_init_main()(
  repo="$1"

  git init "$repo" -q
  git -C "$repo" checkout -b main -q
)

rm -rf "$SANDBOX"

mkdir -p \
  "$WORKSPACE/apps/demo-app" \
  "$WORKSPACE/services/api" \
  "$WORKSPACE/packages/shared" \
  "$REPOS"

printf 'demo app\n' > "$WORKSPACE/apps/demo-app/app.txt"
printf 'api service\n' > "$WORKSPACE/services/api/api.txt"
printf 'shared package\n' > "$WORKSPACE/packages/shared/shared.txt"

write_manifest "$WORKSPACE/@manifest" \
  './apps/demo-app' \
  './services/api' \
  "$REPOS/tool@main"

write_manifest "$WORKSPACE/apps/demo-app/@manifest" \
  '../../packages/shared' \
  "$REPOS/helpers@main"

write_manifest "$WORKSPACE/services/api/@manifest" \
  "$REPOS/theme@stable"

git_init_main "$REPOS/theme"
write_manifest "$REPOS/theme/@manifest" "$REPOS/helpers@main"
printf 'theme stable\n' > "$REPOS/theme/theme.txt"
git_commit_all "$REPOS/theme" 'init theme'
git -C "$REPOS/theme" tag stable

git_init_main "$REPOS/helpers"
write_manifest "$REPOS/helpers/@manifest" \
  "$REPOS/theme@stable"
printf 'helpers package\n' > "$REPOS/helpers/helper.txt"
git_commit_all "$REPOS/helpers" 'init helpers'

git_init_main "$REPOS/tool"
write_manifest "$REPOS/tool/@manifest" \
  "$REPOS/helpers@main"

# ajouter un hook install au repo tool
cat > "$REPOS/tool/@scripts" <<'HOOKEOF'
install()(
  printf 'tool-hook-ran\n' > "$PWD/.hook-ran"
)
HOOKEOF

printf 'tool package\n' > "$REPOS/tool/tool.txt"
git_commit_all "$REPOS/tool" 'init tool'

cd "$WORKSPACE"
$DEP sync

assert 'root expose demo-app api tool' 'test -L .@/demo-app && test -L .@/api && test -L .@/tool'
assert 'root expose shared helpers theme' 'test -L .@/shared && test -L .@/helpers && test -L .@/theme'
assert 'demo-app voit shared' 'test "$(cat apps/demo-app/.@/shared/shared.txt)" = "shared package"'
assert 'demo-app voit helpers git' 'test "$(cat apps/demo-app/.@/helpers/helper.txt)" = "helpers package"'
assert 'api voit theme git' 'test "$(cat services/api/.@/theme/theme.txt)" = "theme stable"'
assert 'tool git voit helpers git' 'test "$(cat .@/tool/.@/helpers/helper.txt)" = "helpers package"'
assert 'helpers git voit theme git' 'test "$(cat .@/helpers/.@/theme/theme.txt)" = "theme stable"'
assert 'theme git voit helpers git' 'test "$(cat .@/theme/.@/helpers/helper.txt)" = "helpers package"'
assert 'store contient des clones git' 'ls -d .@/tool#* .@/helpers#* .@/theme#* >/dev/null 2>&1'
assert 'hook install de tool exécuté' 'test -f .@/tool/.hook-ran'

out=$($DEP list)
assert 'list affiche demo-app' 'echo "$out" | grep -q "demo-app.*ok"'
assert 'list affiche tool' 'echo "$out" | grep -q "tool.*ok"'
assert 'list affiche api' 'echo "$out" | grep -q "api.*ok"'

printf 'scénario conservé dans %s\n' "$SANDBOX"