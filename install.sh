#!/bin/sh
set -eu

DEP_MARKER_START="# --- dep ---"
DEP_MARKER_END="# --- /dep ---"
DEP_REPO_URL="${DEP_REPO_URL:-https://github.com/cedilla-io/dep.git}"

usage() {
  echo "usage: $0 [-l]" >&2
  echo "  -l    install from the local repository checkout" >&2
  exit 1
}

profile_inject()(
  file="$1"
  content="$2"

  grep -qF "$DEP_MARKER_START" "$file" 2>/dev/null && exit 0

  mkdir -p "$(dirname "$file")"
  touch "$file"
  printf '\n%s\n%s\n%s\n' "$DEP_MARKER_START" "$content" "$DEP_MARKER_END" >> "$file"
)

fish_install()(
  bin="$1"
  dir="$HOME/.config/fish/conf.d"
  mkdir -p "$dir"
  {
    printf '# dep\n'
    printf 'set -gx PATH %s $PATH\n' "$bin"
  } > "$dir/dep.fish"
)

detect_shell()(
  case "${SHELL:-}" in
    */bash) echo bash ;;
    */zsh)  echo zsh ;;
    */fish) echo fish ;;
    *)      echo posix ;;
  esac
)

ensure_install_sources()(
  dir="$1"

  test -f "$dir/dep" &&
  test -f "$dir/VERSION" &&
  test -f "$dir/commands/sync.sh" &&
  test -f "$dir/uninstall.sh" &&
  test -f "$dir/config.sh" &&
  exit 0

  echo "invalid install source directory: $dir" >&2
  echo "missing one or more required files (dep, VERSION, commands/sync.sh, uninstall.sh, config.sh)" >&2
  exit 1
)

main()(
  case "$#" in
    0)
      mode="remote"
      ;;
    1)
      test "$1" = "-l" || usage
      mode="local"
      ;;
    *)
      usage
      ;;
  esac

  tmp=""
  if test "$mode" = "local"; then
    dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
  else
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/dep.install.XXXXXX")
    trap 'test -n "$tmp" && rm -rf "$tmp"' EXIT INT TERM HUP
    dir="$tmp/src"

    echo "sources dep introuvables localement, récupération depuis $DEP_REPO_URL"
    git clone --recursive "$DEP_REPO_URL" "$dir"
  fi

  ensure_install_sources "$dir"

  dest="${HOME}/.dep"
  bin="${HOME}/.local/bin"

  if test -d "$dest"; then
    old_uninstall="$dest/uninstall.sh"
    if test -f "$old_uninstall"; then
      echo "ancienne version détectée, désinstallation..."
      sh "$old_uninstall" || true
    else
      rm -rf "$dest"
      rm -f "$bin/dep"
    fi
  fi

  mkdir -p "$dest/commands"
  cp "$dir/dep" "$dest/dep"
  cp "$dir/VERSION" "$dest/VERSION"
  cp "$dir"/commands/*.sh "$dest/commands/"
  if test -f "$dir/known_hosts"; then
    cp "$dir/known_hosts" "$dest/known_hosts"
  fi
  if ! test -f "$dest/config.sh"; then
    cp "$dir/config.sh" "$dest/config.sh"
  fi
  cp "$dir/uninstall.sh" "$dest/uninstall.sh"

  chmod +x "$dest/dep"
  chmod +x "$dest"/commands/*.sh
  chmod +x "$dest/uninstall.sh"

  mkdir -p "$bin"
  rm -f "$bin/dep"
  {
    printf '#!/bin/sh\n'
    printf 'exec "%s/dep" "$@"\n' "$dest"
  } > "$bin/dep"
  chmod +x "$bin/dep"

  if ! test -f "$dest/env.sh"; then
    {
      printf '#!/bin/sh\n'
      printf '# généré par dep\n'
      printf 'export PATH="%s:$PATH"\n' "$bin"
    } > "$dest/env.sh"
    chmod +x "$dest/env.sh"
  fi

  source_line=". \"$dest/env.sh\""
  shell=$(detect_shell)

  case "$shell" in
    bash)
      profile_inject "$HOME/.bashrc" "$source_line"
      activate=". ~/.dep/env.sh"
      ;;
    zsh)
      profile_inject "$HOME/.zshrc" "$source_line"
      activate=". ~/.dep/env.sh"
      ;;
    fish)
      fish_install "$bin"
      activate="source ~/.config/fish/conf.d/dep.fish"
      ;;
    *)
      profile_inject "$HOME/.profile" "$source_line"
      activate=". ~/.dep/env.sh"
      ;;
  esac

  echo "dep installé dans $bin/dep"
  echo "pour l'activer dans ce shell : $activate"
  echo "les nouveaux shells l'auront automatiquement."
)

main "$@"
