mkdir -p "$WORK/t02/libs/mylib"
printf 'contenu mylib\n' > "$WORK/t02/libs/mylib/data.txt"
write_manifest "$WORK/t02/@manifest"
cd "$WORK/t02"

$DEP add "./libs/mylib"
assert ".@/mylib est un symlink" 'test -L .@/mylib'
assert "symlink pointe vers le bon contenu" 'test "$(cat .@/mylib/data.txt)" = "contenu mylib"'
assert "@manifest contient la dep" 'grep -q "./libs/mylib" @manifest'
assert "@lock existe" 'test -f @lock'
assert "@lock première ligne = version" 'test "$(head -1 @lock)" = "$DEP_TOOL_VERSION"'
