mkdir -p "$WORK/t14/mylib"
printf 'lib content\n' > "$WORK/t14/mylib/lib.txt"

write_manifest "$WORK/t14/@manifest" './mylib'

# mylib has its own @scripts with install hook
write_manifest "$WORK/t14/mylib/@manifest"

cat > "$WORK/t14/mylib/@scripts" <<'EOF'
install()(
  printf 'mylib-installed\n' > "$PWD/.hook-ran"
)

uninstall()(
  rm -f "$PWD/.hook-ran"
)
EOF

cd "$WORK/t14"
$DEP sync

assert "mylib hook ran" 'test -f "$WORK/t14/mylib/.hook-ran"'
assert "mylib hook content" 'test "$(cat "$WORK/t14/mylib/.hook-ran")" = "mylib-installed"'

$DEP remove mylib

assert "uninstall hook nettoyé" '! test -f "$WORK/t14/mylib/.hook-ran"'
assert "symlink supprimé" '! test -L .@/mylib'
