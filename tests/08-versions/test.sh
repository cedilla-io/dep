mkdir -p "$WORK/t08/mod-a" "$WORK/t08/mod-b"
write_manifest "$WORK/t08/@manifest" './mod-a' './mod-b'
write_manifest "$WORK/t08/mod-a/@manifest" "$WORK/repos/lib-c@v1"
write_manifest "$WORK/t08/mod-b/@manifest" "$WORK/repos/lib-c@v2"

cd "$WORK/t08"
$DEP sync

assert "mod-a/.@/lib-c existe" 'test -L mod-a/.@/lib-c || test -d mod-a/.@/lib-c'
assert "mod-b/.@/lib-c existe" 'test -L mod-b/.@/lib-c || test -d mod-b/.@/lib-c'
assert "mod-a voit v1" 'test "$(cat mod-a/.@/lib-c/version.txt)" = "v1"'
assert "mod-b voit v2" 'test "$(cat mod-b/.@/lib-c/version.txt)" = "v2"'
assert "deux dossiers #hash dans le store" 'test $(ls -d .@/lib-c#* 2>/dev/null | wc -l) -eq 2'
