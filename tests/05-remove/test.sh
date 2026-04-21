write_manifest "$WORK/t05/@manifest"
cd "$WORK/t05"

$DEP add "$WORK/repos/lib-a@master"
$DEP remove lib-a
assert "symlink supprimé" 'test ! -L .@/lib-a'
assert "store nettoyé" '! ls .@/lib-a#* 2>/dev/null'
assert "@manifest ne contient plus lib-a" '! grep -q "lib-a" @manifest'
