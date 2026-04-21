#!/bin/sh
set -eu

DEP_MARKER_START="# --- dep ---"
DEP_MARKER_END="# --- /dep ---"

profile_remove()(
  file="$1"
  test -f "$file" || return 0
  grep -qF "$DEP_MARKER_START" "$file" || return 0

  tmp="${file}.dep-tmp"
  skip=0
  while IFS= read -r line; do
    test "$line" = "$DEP_MARKER_START" && skip=1 && continue
    test "$line" = "$DEP_MARKER_END" && skip=0 && continue
    test "$skip" = 0 && printf '%s\n' "$line"
  done < "$file" > "$tmp"
  mv "$tmp" "$file"
  echo "nettoyé $file"
)

run_uninstall_hooks()(
  root="$1"
  store="$root/.@"
  test -d "$store" || return 0

  # vérifier le trust
  trust_file="$store/trust"
  trusted=0
  if test -f "$trust_file"; then
    read -r line < "$trust_file"
    test "$line" = "YES" && trusted=1
  fi

  for entry in "$store"/*; do
    test -d "$entry" || continue
    name="${entry##*/}"
    # suivre les symlinks, ignorer les dossiers #hash
    case "$name" in *"#"*) continue ;; esac
    real=$(CDPATH= cd -P -- "$entry" 2>/dev/null && pwd -P) || continue
    test -f "$real/@scripts" || continue

    # deps dans le store = git → vérifier trust
    case "$real" in
      "$store"/*)
        test "$trusted" = 1 || continue
        ;;
    esac

    (
      cd "$real"
      . "$real/@scripts"

      hook_path=$(command -v global_uninstall 2>/dev/null) || true
      case "$hook_path" in
        /*|'') ;;
        ?*) global_uninstall ;;
      esac
    ) 2>/dev/null || true
  done
)

main()(
  dest="${HOME}/.dep"
  bin="${HOME}/.local/bin"

  run_uninstall_hooks "$dest"

  profile_remove "$HOME/.profile"
  profile_remove "$HOME/.bash_profile"
  profile_remove "$HOME/.bashrc"
  profile_remove "$HOME/.zshrc"
  profile_remove "$HOME/.zprofile"
  rm -f "$HOME/.config/fish/conf.d/dep.fish"

  rm -rf "$dest"
  rm -f "$bin/dep"

  echo "dep désinstallé"
)

main "$@"
