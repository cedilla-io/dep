dep_list_help()(
  echo "  list       Liste les dépendances du projet"
)

dep_list()(
  root=$(dep_find_root) || { echo "pas de @manifest trouvé"; return 1; }
  manifest_path=$(dep_manifest_path "$root")
  lockfile_path=$(dep_lockfile_path "$root")
  cd "$root"

  manifest_version=$(dep_read_version "$manifest_path")
  dep_require_manifest_version "$manifest_version" || return 1

  if test -f "$lockfile_path"; then
    lock_version=$(dep_read_version "$lockfile_path")
    dep_require_lockfile_version "$lock_version" || return 1
  fi

  deps=$(dep_read_entries "$manifest_path")

  nl='
'
  old_ifs=$IFS
  IFS=$nl
  set -f
  for dep in $deps; do
    test -n "$dep" || continue
    eval "$(dep_parse "$dep")"
    status="manquant"
    if test "$proto" = "git"; then
      ref_name="${ref:-HEAD}"
      ref_key=$(dep_ref_key "$ref_name")
      test -L ".@/$name@$ref_key" || test -d ".@/$name@$ref_key" && status="ok"
    else
      if test -L ".@/$name" || test -d ".@/$name"; then
        status="ok"
      fi
    fi
    printf "  %-20s %s\n" "$name" "$status"
  done
  set +f
  IFS=$old_ifs
)
