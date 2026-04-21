dep_update_help()(
  echo "  update     Met à jour les dépendances du projet"
)

dep_update()(
  root=$(dep_find_root) || { echo "pas de @manifest trouvé"; return 1; }
  lockfile_path=$(dep_lockfile_path "$root")
  cd "$root"
  rm -f "$lockfile_path"
  dep_revoke_trust "$root"
  dep_sync "$@"
)
