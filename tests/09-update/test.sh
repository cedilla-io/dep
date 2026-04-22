write_manifest "$WORK/t09/@manifest" "$WORK/repos/lib-a@master"
cd "$WORK/t09"

$DEP sync
hash1=$(readlink .@/lib-a@master)

# ajouter un commit dans lib-a
printf 'new content\n' > "$WORK/repos/lib-a/new.txt"
git -C "$WORK/repos/lib-a" add -A && git -C "$WORK/repos/lib-a" commit -m "update" -q

$DEP sync
hash2=$(readlink .@/lib-a@master)
assert "sync conserve le hash du lock" 'test "$hash1" = "$hash2"'
assert "nouveau fichier absent tant que lock conservé" '! test -f .@/lib-a@master/new.txt'

$DEP update
hash3=$(readlink .@/lib-a@master)

assert "le hash a change apres update" 'test "$hash2" != "$hash3"'
assert "nouveau fichier present" 'test -f .@/lib-a@master/new.txt'
assert "@lock régénéré" 'test -f @lock'
