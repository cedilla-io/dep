mkdir -p "$WORK/t06/libs/mylib" "$WORK/t06/src/deep/nested"
write_manifest "$WORK/t06/@manifest" './libs/mylib'
printf 'data\n' > "$WORK/t06/libs/mylib/file.txt"

cd "$WORK/t06/src/deep/nested"
$DEP sync
assert "sync depuis sous-dossier crée le symlink" 'test -L "$WORK/t06/.@/mylib"'

cd "$WORK/t06/src/deep/nested"
out=$($DEP list)
assert "list depuis sous-dossier fonctionne" 'echo "$out" | grep -q "mylib.*ok"'
