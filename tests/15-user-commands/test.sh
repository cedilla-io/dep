mkdir -p "$WORK/t15"

write_manifest "$WORK/t15/@manifest"

cat > "$WORK/t15/@scripts" <<'EOF'
build()(
  echo "built ok"
)

deploy()(
  echo "deployed $1"
)
EOF

cd "$WORK/t15"

out=$($DEP build)
assert "build exécuté" 'test "$out" = "built ok"'

out=$($DEP deploy prod)
assert "deploy avec arg" 'test "$out" = "deployed prod"'

out=$($DEP help 2>&1)
assert "help liste build" 'echo "$out" | grep -q "build"'
assert "help liste deploy" 'echo "$out" | grep -q "deploy"'
assert "help ne liste pas install" '! echo "$out" | grep -qw "install"'

mkdir -p "$WORK/t15/dep-tools"
write_manifest "$WORK/t15/dep-tools/@manifest"

cat > "$WORK/t15/dep-tools/helper.sh" <<'EOF'
TOOL_MSG="helper ok"
EOF

cat > "$WORK/t15/dep-tools/@scripts" <<'EOF'
DEP_TASKS_DIR=$PWD
. ./helper.sh

lint()(
  echo "$DEP_TASKS_DIR|$PWD|$TOOL_MSG"
)
EOF

write_manifest "$WORK/t15/@manifest" "./dep-tools"
$DEP sync

out=$($DEP lint)
assert "commande d'une dep exécutée depuis le projet appelant" \
  'test "$out" = "$WORK/t15/dep-tools|$WORK/t15|helper ok"'

out=$($DEP help 2>&1)
assert "help liste la tâche de dep" 'echo "$out" | grep -q "lint (dep-tools)"'
