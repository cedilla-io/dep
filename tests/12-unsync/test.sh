mkdir -p "$WORK/t12/a" "$WORK/t12/b"
write_manifest "$WORK/t12/@manifest" './a' './b'
cd "$WORK/t12"

$DEP sync
assert "a et b installés" 'test -L .@/a && test -L .@/b'

$DEP unsync a
assert "a retiré du store" 'test ! -L .@/a'
assert "b toujours dans le store" 'test -L .@/b'
assert "@manifest intact" 'grep -q "./a" @manifest && grep -q "./b" @manifest'

$DEP unsync
assert "store entièrement nettoyé" 'test ! -L .@/a && test ! -L .@/b'
assert "@manifest toujours intact" 'grep -q "./a" @manifest'
