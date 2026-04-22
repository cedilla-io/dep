dep_remove_help()(
  echo "  remove     Retire une dépendance du @manifest et du store"
)

dep_remove()(
  target="$1"
  test -z "$target" && echo "usage: dep remove <nom>" && return 1
  root=$(dep_find_root) || { echo "pas de @manifest trouvé"; return 1; }
  manifest_path=$(dep_manifest_path "$root")
  lockfile_path=$(dep_lockfile_path "$root")
  cd "$root"

  if test -f "$manifest_path"; then
    manifest_version=$(dep_read_version "$manifest_path")
    dep_require_manifest_version "$manifest_version" || return 1

    deps=$(dep_read_entries "$manifest_path")
    new_deps=""
    nl='
'
    old_ifs=$IFS
    IFS=$nl
    set -f
    for dep in $deps; do
      test -n "$dep" || continue
      eval "$(dep_parse "$dep")"
      test "$name" = "$target" && continue
      new_deps=$(dep_append_line "$new_deps" "$dep")
    done
    set +f
    IFS=$old_ifs

    dep_write_manifest "$manifest_path" "$manifest_version" "$new_deps"
  fi

  if test -f "$lockfile_path"; then
    lock_version=$(dep_read_version "$lockfile_path")
    dep_require_lockfile_version "$lock_version" || return 1

    locks=$(dep_read_entries "$lockfile_path")
    new_locks=""
    nl='
'
    old_ifs=$IFS
    IFS=$nl
    set -f
    for lock in $locks; do
      test -n "$lock" || continue
      eval "$(dep_parse "$lock")"
      test "$name" = "$target" && continue
      new_locks=$(dep_append_line "$new_locks" "$lock")
    done
    set +f
    IFS=$old_ifs

    dep_write_lockfile "$lockfile_path" "$DEP_VERSION" "$new_locks"
  fi

  dep_path=$(dep_store_entry_path "$root" "$target")
  if ! test -L "$dep_path" && ! test -d "$dep_path"; then
    for entry in ".@/$target@"*; do
      test -L "$entry" || test -d "$entry" || continue
      dep_path="$entry"
      break
    done
  fi
  if test -L "$dep_path" || test -d "$dep_path"; then
    real_path=$(dep_resolve_dir "$dep_path" 2>/dev/null) || true
    if test -n "$real_path" && dep_has_scripts "$real_path"; then
      store=$(dep_store_path "$root")
      case "$real_path" in
        "$store"/*) dep_is_trusted "$root" && dep_run_hook "$real_path" uninstall ;;
        *) dep_run_hook "$real_path" uninstall ;;
      esac
    fi
  fi

  rm -rf ".@/$target" ".@/$target@"* ".@/$target#"*
  echo "'$target' supprimé"
)
