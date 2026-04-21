mkdir -p "$WORK/t11/a" "$WORK/t11/b"
write_manifest "$WORK/t11/@manifest" './a' './b'
cd "$WORK/t11"

$DEP sync
assert "a et b presents" 'test -L .@/a && test -L .@/b'

$DEP remove a
assert "a supprimé" 'test ! -L .@/a'
assert "b toujours present" 'test -L .@/b'
assert "@manifest ne contient plus a" '! grep -q "./a" @manifest'
assert "@manifest contient toujours b" 'grep -q "./b" @manifest'
