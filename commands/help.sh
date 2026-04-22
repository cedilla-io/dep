dep_help_help()(
  echo "  help       Affiche l'aide"
)

dep_help()(
  echo "Dep v$DEP_VERSION"
  echo
  echo "Usage:"
  echo "  dep [global] [--trust] <commande> [options]"
  echo "  dep --version | -v"
  echo
  echo "Commandes:"

  for f in "$DEP_ROOT"/commands/*.sh; do
    test -f "$f" || continue
    cmd=$(basename "$f" .sh)
    case "$cmd" in _*) continue ;; esac
    help="dep_${cmd}_help"
    command -v "$help" >/dev/null 2>&1 && "$help" && continue
    echo "  $cmd"
  done

  root=$(dep_find_root 2>/dev/null) || return 0
  scripts_path=$(dep_scripts_path "$root")
  tasks=$(dep_scripts_user_tasks "$scripts_path")
  dep_tasks=$(dep_dep_user_tasks "$root")
  test -z "$tasks$dep_tasks" && return 0

  if test -n "$tasks"; then
    echo
    echo "Tâches du projet:"
    printf '%s\n' "$tasks" | while IFS= read -r t; do
      test -n "$t" && echo "  $t"
    done
  fi

  if test -n "$dep_tasks"; then
    echo
    echo "Tâches des dépendances:"
    printf '%s\n' "$dep_tasks" | while IFS= read -r entry; do
      test -n "$entry" || continue
      eval "$entry"
      printf '  %s (%s)\n' "$dep_task" "$dep_name"
    done
  fi
)
