mkdir -p "$WORK/t22"
write_manifest "$WORK/t22/@manifest" "$WORK/repos/lib-a@master"
cd "$WORK/t22"

$DEP sync
assert "dep git installée" 'test -L .@/lib-a@master'
assert "hash présent" 'test $(ls -d .@/lib-a#* 2>/dev/null | wc -l) -eq 1'

write_manifest "$WORK/t22/@manifest"
$DEP sync
assert "alias supprimé après retrait du manifest" '! test -e .@/lib-a@master'
assert "hash supprimé après retrait du manifest" 'test $(ls -d .@/lib-a#* 2>/dev/null | wc -l) -eq 0'
