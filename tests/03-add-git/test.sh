write_manifest "$WORK/t03/@manifest"
cd "$WORK/t03"

$DEP add "$WORK/repos/lib-a@master"
assert ".@/lib-a est un symlink" 'test -L .@/lib-a'
assert "symlink pointe vers un dossier #hash" 'readlink .@/lib-a | grep -q "#"'
assert "contenu clone" 'test "$(cat .@/lib-a/readme.txt)" = "hello from lib-a"'
assert "@lock contient le hash" 'grep -q "#" @lock'
