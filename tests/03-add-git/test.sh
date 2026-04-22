write_manifest "$WORK/t03/@manifest"
cd "$WORK/t03"

$DEP add "$WORK/repos/lib-a@master"
assert ".@/lib-a@master est un symlink" 'test -L .@/lib-a@master'
assert "symlink pointe vers un dossier #hash" 'readlink .@/lib-a@master | grep -q "#"'
assert "contenu clone" 'test "$(cat .@/lib-a@master/readme.txt)" = "hello from lib-a"'
assert "@lock contient le hash" 'grep -q "#" @lock'
