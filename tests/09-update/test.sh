write_manifest "$WORK/t09/@manifest" "$WORK/repos/lib-a@master"
cd "$WORK/t09"

$DEP sync
hash1=$(readlink .@/lib-a)

# ajouter un commit dans lib-a
printf 'new content\n' > "$WORK/repos/lib-a/new.txt"
git -C "$WORK/repos/lib-a" add -A && git -C "$WORK/repos/lib-a" commit -m "update" -q

$DEP update
hash2=$(readlink .@/lib-a)

assert "le hash a change apres update" 'test "$hash1" != "$hash2"'
assert "nouveau fichier present" 'test -f .@/lib-a/new.txt'
assert "@lock régénéré" 'test -f @lock'
