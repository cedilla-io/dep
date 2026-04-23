dep_init_help()(
  echo "  init       Initialise un nouveau projet"
)

dep_init()(
  if test "${DEP_GLOBAL:-0}" = 1; then
    target="$HOME/.dep"
  else
    target="$PWD"
  fi

  manifest_path=$(dep_manifest_path "$target")
  store_path=$(dep_store_path "$target")

  test -f "$manifest_path" && echo "déjà initialisé" && return 1
  mkdir -p "$store_path"
  dep_write_manifest "$manifest_path" "$DEP_VERSION" ""
  echo "initialisé (@manifest créé)"

  if ! test -f ".gitignore"; then
      touch ".gitignore";
  fi;
  lc=$(grep ".@" .gitignore  | wc -l)

  if test "$lc" = "0"; then
    echo ".@" >> ".gitignore";
  fi;
)
