dep_add_help()(
  echo "  add        Ajoute une dépendance au @manifest"
)

dep_add()(
  test -z "${1:-}" && echo "usage: dep add <source[@ref]>" && return 1
  root=$(dep_find_root) || { echo "pas de @manifest - lancer dep init d'abord"; return 1; }
  manifest_path=$(dep_manifest_path "$root")
  cd "$root"

  manifest_version=$(dep_read_version "$manifest_path")
  dep_require_manifest_version "$manifest_version" || return 1

  eval "$(dep_parse "$1")"
  wanted="$name"

  deps=$(dep_read_entries "$manifest_path")

  nl='
'
  old_ifs=$IFS
  IFS=$nl
  set -f
  for dep in $deps; do
    test -n "$dep" || continue
    eval "$(dep_parse "$dep")"
    test "$name" = "$wanted" && echo "'$wanted' déjà présent" && return 1
  done
  set +f
  IFS=$old_ifs

  deps=$(dep_append_line "$deps" "$1")

  dep_write_manifest "$manifest_path" "$manifest_version" "$deps"

  echo "ajouté: $1"
  dep_sync
)
