mkdir -p "$WORK/t13/manifest-too-new" "$WORK/t13/lock-too-new"

write_manifest_with_version "$WORK/t13/manifest-too-new/@manifest" '99.0.0' './a'
mkdir -p "$WORK/t13/manifest-too-new/a"
cd "$WORK/t13/manifest-too-new"
out=$($DEP list 2>&1 || true)
assert "refuse @manifest plus récent" 'echo "$out" | grep -q "@manifest requiert dep >= 99.0.0"'

write_manifest "$WORK/t13/lock-too-new/@manifest" './a'
write_lockfile_with_version "$WORK/t13/lock-too-new/@lock" '99.0.0' './a'
mkdir -p "$WORK/t13/lock-too-new/a"
cd "$WORK/t13/lock-too-new"
out=$($DEP list 2>&1 || true)
assert "refuse @lock plus récent" 'echo "$out" | grep -q "@lock a été généré par dep 99.0.0"'