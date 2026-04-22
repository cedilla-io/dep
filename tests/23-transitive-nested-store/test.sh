mkdir -p "$WORK/t23/a" "$WORK/t23/b" "$WORK/t23/c" "$WORK/t23/x"
printf 'deep\n' > "$WORK/t23/c/deep.txt"

write_manifest "$WORK/t23/@manifest" './a' './x'
write_manifest "$WORK/t23/a/@manifest" '../b' "$WORK/repos/lib-a@master"
write_manifest "$WORK/t23/b/@manifest" '../c'
write_manifest "$WORK/t23/c/@manifest" "$WORK/repos/lib-b@master"
write_manifest "$WORK/t23/x/@manifest" '../c'
cd "$WORK/t23"

$DEP sync

assert "a/.@ est un dossier local" 'test -d a/.@ && ! test -L a/.@'
assert "b/.@ est un dossier local" 'test -d b/.@ && ! test -L b/.@'
assert "x/.@ est un dossier local" 'test -d x/.@ && ! test -L x/.@'
assert "a/.@/b existe" 'test -L a/.@/b'
assert "a/.@/lib-a@master existe" 'test -L a/.@/lib-a@master'
assert "b/.@/c existe" 'test -L b/.@/c'
assert "x/.@/c existe" 'test -L x/.@/c'
assert "c/.@/lib-b@master existe" 'test -L c/.@/lib-b@master'
assert "transitives partagées pointent au meme c" 'test "$(CDPATH= cd -P b/.@/c && pwd -P)" = "$(CDPATH= cd -P x/.@/c && pwd -P)"'
assert "c transitif accessible depuis a" 'test "$(cat a/.@/b/.@/c/deep.txt)" = "deep"'
