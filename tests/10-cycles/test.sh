mkdir -p "$WORK/t10/x" "$WORK/t10/y"
write_manifest "$WORK/t10/@manifest" './x'
write_manifest "$WORK/t10/x/@manifest" '../y'
write_manifest "$WORK/t10/y/@manifest" '../x'
printf 'hello\n' > "$WORK/t10/x/data.txt"
printf 'world\n' > "$WORK/t10/y/data.txt"
cd "$WORK/t10"

$DEP sync
assert "sync termine sans boucle infinie" 'true'
assert ".@/x existe" 'test -L .@/x'
assert ".@/y existe (transitif)" 'test -L .@/y'
