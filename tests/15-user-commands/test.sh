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
