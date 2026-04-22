mkdir -p "$WORK/t07/a" "$WORK/t07/b"
printf 'hello b\n' > "$WORK/t07/b/data.txt"
write_manifest "$WORK/t07/@manifest" './a'
write_manifest "$WORK/t07/a/@manifest" '../b'
cd "$WORK/t07"

$DEP sync
assert ".@/a symlink" 'test -L .@/a'
assert ".@/b symlink (transitive)" 'test -L .@/b'
assert "a/.@ est un vrai dossier" 'test -d a/.@ && ! test -L a/.@'
assert "a/.@/b symlink" 'test -L a/.@/b'
assert "a peut acceder a b" 'test "$(cat a/.@/b/data.txt)" = "hello b"'
