dep_unsync_help()(
  echo "  unsync     Nettoie le store (sans toucher au @manifest)"
)

dep_unsync()(
  root=$(dep_find_root) || { echo "pas de @manifest trouvé"; return 1; }
  store_path=$(dep_store_path "$root")
  cd "$root"

  if test -z "${1:-}"; then
    for entry in "$store_path"/*; do
      test -e "$entry" || continue
      rm -rf "$entry"
    done
    echo "store nettoyé"
  else
    rm -rf "$store_path/$1" "$store_path/$1@"* "$store_path/$1#"*
    echo "'$1' retiré du store"
  fi
)
