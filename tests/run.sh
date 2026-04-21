#!/bin/sh

if test "${DEP_TESTS_UNDER_DASH:-0}" != 1; then
  command -v dash >/dev/null 2>&1 || {
    echo "dash est requis pour lancer les tests"
    exit 1
  }
  DEP_TESTS_UNDER_DASH=1 exec dash "$0" "$@"
fi

set -eu

DIR="$(cd "$(dirname "$0")" && pwd)"

export DEP_ROOT="$(cd "$DIR/.." && pwd)"
export DEP="$DEP_ROOT/dep"
export DEP_TOOL_VERSION=$(sed -n '1p' "$DEP_ROOT/VERSION")
export DEP_AUTO_TRUST=1
work_id=0
while :; do
  WORK="${TMPDIR:-/tmp}/dep.$$.$work_id"
  mkdir "$WORK" 2>/dev/null && break
  work_id=$((work_id + 1))
done
export WORK
trap 'rm -rf "$WORK"' EXIT

assert()(
  if eval "$2"; then
    printf "  ok  %s\n" "$1"
  else
    printf "  ERR %s\n" "$1"
    return 1
  fi
)

write_manifest_with_version()(
  file="$1"
  version="$2"
  shift 2

  mkdir -p "$(dirname -- "$file")"
  {
    printf '%s\n' "$version"
    for dep do
      printf '%s\n' "$dep"
    done
  } > "$file"
)

write_manifest()(
  file="$1"
  shift

  write_manifest_with_version "$file" "$DEP_TOOL_VERSION" "$@"
)

write_lockfile_with_version()(
  file="$1"
  sync_version="$2"
  shift 2

  mkdir -p "$(dirname -- "$file")"
  {
    printf '%s\n' "$sync_version"
    for lock do
      printf '%s\n' "$lock"
    done
  } > "$file"
)

write_lockfile()(
  file="$1"
  sync_version="$2"
  shift 2

  write_lockfile_with_version "$file" "$sync_version" "$@"
)

# setup repos

git init "$WORK/repos/lib-a" -q
printf 'hello from lib-a\n' > "$WORK/repos/lib-a/readme.txt"
git -C "$WORK/repos/lib-a" add -A && git -C "$WORK/repos/lib-a" commit -m "init" -q

git init "$WORK/repos/lib-b" -q
write_manifest "$WORK/repos/lib-b/@manifest"
printf 'hello from lib-b\n' > "$WORK/repos/lib-b/readme.txt"
git -C "$WORK/repos/lib-b" add -A && git -C "$WORK/repos/lib-b" commit -m "init" -q

git init "$WORK/repos/lib-c" -q
printf 'v1\n' > "$WORK/repos/lib-c/version.txt"
git -C "$WORK/repos/lib-c" add -A && git -C "$WORK/repos/lib-c" commit -m "v1" -q
git -C "$WORK/repos/lib-c" tag v1
git -C "$WORK/repos/lib-c" checkout -b v2 -q
printf 'v2\n' > "$WORK/repos/lib-c/version.txt"
git -C "$WORK/repos/lib-c" add -A && git -C "$WORK/repos/lib-c" commit -m "v2" -q

# run each test

for test in "$DIR"/*/test.sh; do
  name=$(basename "$(dirname "$test")")
  printf "\n--- %s\n" "$name"
  (
    . "$test"
  )
done

printf "\n--- tous les tests ont passé\n"
