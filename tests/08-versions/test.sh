mkdir -p "$WORK/t08/mod-a" "$WORK/t08/mod-b"
write_manifest "$WORK/t08/@manifest" './mod-a' './mod-b'
write_manifest "$WORK/t08/mod-a/@manifest" "$WORK/repos/lib-c@v1"
write_manifest "$WORK/t08/mod-b/@manifest" "$WORK/repos/lib-c@v2"

cd "$WORK/t08"
$DEP sync

assert "mod-a/.@ pointe sur le store racine" 'test -L mod-a/.@'
assert "mod-b/.@ pointe sur le store racine" 'test -L mod-b/.@'
assert "mod-a voit v1 via alias de branche" 'test "$(cat mod-a/.@/lib-c@v1/version.txt)" = "v1"'
assert "mod-b voit v2 via alias de branche" 'test "$(cat mod-b/.@/lib-c@v2/version.txt)" = "v2"'
assert "nom canonique existe toujours" 'test -L .@/lib-c || test -d .@/lib-c'
assert "deux dossiers #hash dans le store" 'test $(ls -d .@/lib-c#* 2>/dev/null | wc -l) -eq 2'
