# test sans auto-trust
ORIG_AUTO_TRUST="${DEP_AUTO_TRUST:-}"
unset DEP_AUTO_TRUST

git init "$WORK/repos/trust-pkg" -q
write_manifest "$WORK/repos/trust-pkg/@manifest"

# ajouter un @scripts avec hook install
cat > "$WORK/repos/trust-pkg/@scripts" <<'HOOKEOF'
install()(
  printf 'trusted-hook\n' > "$PWD/.hook-ran"
)
HOOKEOF

git -C "$WORK/repos/trust-pkg" add -A
git -C "$WORK/repos/trust-pkg" commit -m "init" -q

# --- sans trust : hooks ne tournent pas ---
write_manifest "$WORK/t18/@manifest" "$WORK/repos/trust-pkg@master"
cd "$WORK/t18"

$DEP sync </dev/null 2>/dev/null || true

assert "dep clonée" 'test -L .@/trust-pkg'
assert "pas de fichier trust" '! test -f .@/trust'
assert "hook non exécuté sans trust" '! test -f .@/trust-pkg/.hook-ran'

if command -v script >/dev/null 2>&1; then
  write_manifest "$WORK/t18tty/@manifest" "$WORK/repos/trust-pkg@master"
  cd "$WORK/t18tty"

  script_cmd="$DEP sync"
  printf 'YES\n' | script -qfec "$script_cmd" /dev/null >/dev/null 2>&1

  assert "trust interactif crée le fichier" 'test -f .@/trust'
  assert "trust interactif hook exécuté" 'test -f .@/trust-pkg/.hook-ran'
fi

cd "$WORK/t18"

# --- avec trust : hooks tournent ---
printf 'YES\n' > .@/trust
$DEP sync </dev/null 2>/dev/null

assert "hook exécuté avec trust" 'test -f .@/trust-pkg/.hook-ran'
assert "hook contenu" 'test "$(cat .@/trust-pkg/.hook-ran)" = "trusted-hook"'

# --- remove respecte trust ---
$DEP remove trust-pkg 2>/dev/null
assert "dep supprimée" '! test -L .@/trust-pkg'

# --- auto-trust ---
export DEP_AUTO_TRUST=1
write_manifest "$WORK/t18b/@manifest" "$WORK/repos/trust-pkg@master"
cd "$WORK/t18b"

$DEP sync 2>/dev/null
assert "auto-trust crée le fichier" 'test -f .@/trust'
assert "auto-trust hook exécuté" 'test -f .@/trust-pkg/.hook-ran'

# --- pas de @scripts = pas de prompt trust ---
unset DEP_AUTO_TRUST

git init "$WORK/repos/noscripts-pkg" -q
write_manifest "$WORK/repos/noscripts-pkg/@manifest"
printf 'data\n' > "$WORK/repos/noscripts-pkg/data.txt"
git -C "$WORK/repos/noscripts-pkg" add -A
git -C "$WORK/repos/noscripts-pkg" commit -m "init" -q

write_manifest "$WORK/t18c/@manifest" "$WORK/repos/noscripts-pkg@master"
cd "$WORK/t18c"
$DEP sync </dev/null 2>/dev/null
assert "pas de @scripts = pas de trust requis" '! test -f .@/trust'
assert "clone ok sans @scripts" 'test -f .@/noscripts-pkg/data.txt'

# --- update révoque trust ---
export DEP_AUTO_TRUST=1
write_manifest "$WORK/t18d/@manifest" "$WORK/repos/trust-pkg@master"
cd "$WORK/t18d"
$DEP sync 2>/dev/null
assert "trust initial" 'test -f .@/trust'

rm -f .@/trust-pkg/.hook-ran
$DEP update 2>/dev/null
assert "trust révoqué puis re-validé après update" 'test -f .@/trust'
assert "hook re-exécuté après update" 'test -f .@/trust-pkg/.hook-ran'

# restaurer
export DEP_AUTO_TRUST="${ORIG_AUTO_TRUST:-1}"
