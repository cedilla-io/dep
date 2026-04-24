DEP_STORE_DIR=".@"
DEP_MANIFEST_FILE="@manifest"
DEP_LOCKFILE_FILE="@lock"
DEP_SCRIPTS_FILE="@scripts"
DEP_ENV_FILE="$HOME/.dep/env.sh"
DEP_CONFIG_FILE="$HOME/.dep/config.sh"
DEP_RESERVED="install uninstall global_install global_uninstall"
DEP_TRUST_FILE="trust"
DEP_SSH_FILE="@ssh"
DEP_KNOWN_HOSTS="${DEP_ROOT:-.}/known_hosts"
DEP_VERBOSE="${DEP_VERBOSE:-${DEP_VERBROSE:-0}}"

# --- config ---

if test -f "${DEP_CONFIG_FILE:-}"; then
  . "$DEP_CONFIG_FILE"
fi

DEP_VERSION=$(sed -n '1p' "${DEP_ROOT:-.}/VERSION" 2>/dev/null)
test -n "$DEP_VERSION" || DEP_VERSION="0.0.0"

dep_manifest_path()(
  printf '%s/%s\n' "$1" "$DEP_MANIFEST_FILE"
)

dep_lockfile_path()(
  printf '%s/%s\n' "$1" "$DEP_LOCKFILE_FILE"
)

dep_scripts_path()(
  printf '%s/%s\n' "$1" "$DEP_SCRIPTS_FILE"
)

dep_store_path()(
  printf '%s/%s\n' "$1" "$DEP_STORE_DIR"
)

dep_store_entry_path()(
  printf '%s/%s/%s\n' "$1" "$DEP_STORE_DIR" "$2"
)

dep_find_root()(
  if test "${DEP_GLOBAL:-0}" = 1; then
    root="$HOME/.dep"
    test -f "$(dep_manifest_path "$root")" && echo "$root" && return 0
    return 1
  fi
  dir="$PWD"
  while true; do
    test -f "$(dep_manifest_path "$dir")" && echo "$dir" && return 0
    test "$dir" = "/" && break
    dir="${dir%/*}"
    test -z "$dir" && dir="/"
  done
  return 1
)

dep_verbose_enabled()(
  case "${DEP_VERBOSE:-0}" in
    1|true|TRUE|yes|YES|on|ON) return 0 ;;
  esac
  return 1
)

dep_verbose()(
  dep_verbose_enabled || return 0
  printf '[dep][sync] %s\n' "$*" >&2
)

dep_trim_entry()(
  printf '%s\n' "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
)

# --- semver ---

dep_semver_parts()(
  version=$(dep_trim_entry "$1")

  case "$version" in
    ''|*[!0-9.]*|.*|*.) return 1 ;;
  esac

  old_ifs=$IFS
  IFS=.
  set -- $version
  IFS=$old_ifs

  test "$#" -ge 1 && test "$#" -le 3 || return 1

  major=${1:-0}
  minor=${2:-0}
  patch=${3:-0}

  for part in "$major" "$minor" "$patch"; do
    case "$part" in
      ''|*[!0-9]*) return 1 ;;
    esac
  done

  printf '%s %s %s\n' "$major" "$minor" "$patch"
)

dep_semver_valid()(
  dep_semver_parts "$1" >/dev/null 2>&1
)

dep_semver_ge()(
  left_version=$(dep_trim_entry "$1")
  right_version=$(dep_trim_entry "$2")

  dep_semver_valid "$left_version" || return 2
  dep_semver_valid "$right_version" || return 2

  old_ifs=$IFS
  IFS=.
  set -- $left_version
  IFS=$old_ifs
  left_major=${1:-0}
  left_minor=${2:-0}
  left_patch=${3:-0}

  old_ifs=$IFS
  IFS=.
  set -- $right_version
  IFS=$old_ifs
  right_major=${1:-0}
  right_minor=${2:-0}
  right_patch=${3:-0}

  test "$left_major" -gt "$right_major" && return 0
  test "$left_major" -lt "$right_major" && return 1

  test "$left_minor" -gt "$right_minor" && return 0
  test "$left_minor" -lt "$right_minor" && return 1

  test "$left_patch" -ge "$right_patch"
)

# --- version checks ---

dep_require_manifest_version()(
  required=$(dep_trim_entry "$1")

  test -n "$required" || {
    echo "@manifest incomplet : version manquante (première ligne)"
    return 1
  }

  dep_semver_valid "$required" || {
    echo "@manifest contient une version invalide : $required"
    return 1
  }

  dep_semver_valid "$DEP_VERSION" || {
    echo "VERSION contient une version invalide : $DEP_VERSION"
    return 1
  }

  dep_semver_ge "$DEP_VERSION" "$required" && return 0

  echo "@manifest requiert dep >= $required (courant : $DEP_VERSION) - mettre dep à jour"
  return 1
)

dep_require_lockfile_version()(
  sync_version=$(dep_trim_entry "$1")

  test -n "$sync_version" || return 0

  dep_semver_valid "$sync_version" || {
    echo "@lock contient une version invalide : $sync_version"
    return 1
  }

  dep_semver_ge "$DEP_VERSION" "$sync_version" && return 0

  echo "@lock a été généré par dep $sync_version (courant : $DEP_VERSION) - mettre dep à jour ou régénérer @lock"
  return 1
)

# --- manifest/lock read (plain text) ---

dep_read_version()(
  file="$1"
  test -f "$file" || return 1
  sed -n '1p' "$file"
)

dep_read_entries()(
  file="$1"
  test -f "$file" || return 0
  tail -n +2 "$file" | while IFS= read -r line; do
    line=$(dep_trim_entry "$line")
    case "$line" in
      ''|'#'*) continue ;;
    esac
    printf '%s\n' "$line"
  done
)

# --- manifest/lock write (plain text) ---

dep_write_manifest()(
  file="$1" version="$2" deps="${3-}"

  tmp="${file}.tmp"
  trap 'rm -f "$tmp"' EXIT

  printf '%s\n' "$version" > "$tmp"

  if test -n "$deps"; then
    nl='
'
    old_ifs=$IFS
    IFS=$nl
    set -f
    for entry in $deps; do
      entry=$(dep_trim_entry "$entry")
      test -n "$entry" || continue
      printf '%s\n' "$entry"
    done >> "$tmp"
    set +f
    IFS=$old_ifs
  fi

  mv "$tmp" "$file"
)

dep_write_lockfile()(
  file="$1" version="$2" locks="${3-}"

  tmp="${file}.tmp"
  trap 'rm -f "$tmp"' EXIT

  printf '%s\n' "$version" > "$tmp"

  if test -n "$locks"; then
    nl='
'
    old_ifs=$IFS
    IFS=$nl
    set -f
    for entry in $locks; do
      entry=$(dep_trim_entry "$entry")
      test -n "$entry" || continue
      printf '%s\n' "$entry"
    done >> "$tmp"
    set +f
    IFS=$old_ifs
  fi

  mv "$tmp" "$file"
)

# --- dep entry parsing ---

dep_escape_dq()(
  printf '%s\n' "$1" | sed 's/[\\$`"]/\\&/g'
)

dep_is_ssh_source()(
  source=$(dep_trim_entry "$1")

  case "$source" in
    ssh://*/*) return 0 ;;
    git@*:*/*) return 0 ;;
    /*|./*|../*) return 1 ;;
    *:*/*) return 0 ;;
    *) return 1 ;;
  esac
)

dep_is_https_source()(
  source=$(dep_trim_entry "$1")
  case "$source" in
    https://*/*|http://*/*) return 0 ;;
    *) return 1 ;;
  esac
)

dep_is_git_remote_source()(
  source=$(dep_trim_entry "$1")
  dep_is_ssh_source "$source" && return 0
  dep_is_https_source "$source" && return 0
  return 1
)

dep_parse()(
  entry=$(dep_trim_entry "$1") name=""

  case "$entry" in
    *=*) name="${entry%%=*}"; entry="${entry#*=}" ;;
  esac

  case "$entry" in
    *"#"*) ref="${entry##*#}"; source="${entry%#*}" ;;
    *)
      if dep_is_ssh_source "$entry"; then
        case "$entry" in
          git@*:*)
            ssh_rest="${entry#*:}"
            case "$ssh_rest" in
              *@*) ref="${ssh_rest##*@}"; source="${entry%@$ref}" ;;
              *)   ref=""; source="$entry" ;;
            esac
            ;;
          *@*) ref="${entry##*@}"; source="${entry%@$ref}" ;;
          *)   ref=""; source="$entry" ;;
        esac
      else
        case "$entry" in
          *@*) ref="${entry##*@}"; source="${entry%@*}" ;;
          *)   ref=""; source="$entry" ;;
        esac
      fi
      ;;
  esac

  if test -z "$name"; then
    name="${source##*/}"
    if dep_is_ssh_source "$source"; then
      case "$name" in
        *.git) name="${name%.git}" ;;
      esac
    fi
  fi

  if test -n "$ref" || dep_is_git_remote_source "$source"; then
    proto=git
  else
    proto=fs
  fi

  printf 'name="%s" proto="%s" source="%s" ref="%s"\n' \
    "$(dep_escape_dq "$name")" "$proto" \
    "$(dep_escape_dq "$source")" "$(dep_escape_dq "$ref")"
)

dep_append_line()(
  list="${1-}" line=$(dep_trim_entry "$2")

  if test -z "$line"; then
    test -n "$list" && printf '%s' "$list"
    return 0
  fi

  if test -n "$list"; then
    printf '%s\n%s' "$list" "$line"
  else
    printf '%s' "$line"
  fi
)

# --- filesystem ---

dep_abs_path()(
  path="$1"
  dir="${path%/*}"
  base="${path##*/}"

  test -n "$dir" || dir="/"
  test "$dir" = "$path" && dir='.'

  abs_dir=$(CDPATH= cd -- "$dir" && pwd -P) || return 1

  case "$abs_dir" in
    /) printf '/%s\n' "$base" ;;
    *) printf '%s/%s\n' "$abs_dir" "$base" ;;
  esac
)

dep_resolve_dir()(
  CDPATH= cd -P -- "$1" || return 1
  pwd -P
)

dep_link()(
  target="$1" link="$2"
  link_dir=${link%/*}

  test "$link_dir" = "$link" && link_dir='.'

  mkdir -p "$link_dir"
  rm -f "$link"
  ln -s "$target" "$link"
)

dep_replace_with_link()(
  target="$1" link="$2"
  if test -e "$link" || test -L "$link"; then
    rm -rf "$link"
  fi
  dep_link "$target" "$link"
)

dep_ref_key()(
  ref="$1"
  printf '%s\n' "$ref" | sed 's/[^a-zA-Z0-9._-]/_/g'
)

# --- @scripts ---

dep_is_reserved()(
  name="$1"
  case " $DEP_RESERVED " in
    *" $name "*) return 0 ;;
  esac
  return 1
)

dep_run_hook()(
  pkg_dir="$1"
  hook="$2"

  if test "${DEP_GLOBAL:-0}" = 1; then
    case "$hook" in
      install) hook=global_install ;;
      uninstall) hook=global_uninstall ;;
    esac
  fi

  scripts_path=$(dep_scripts_path "$pkg_dir")
  test -f "$scripts_path" || return 0

  cd "$pkg_dir"
  . "$scripts_path"

  # POSIX : command -v retourne le chemin pour les binaires, le nom pour les fonctions
  hook_path=$(command -v "$hook" 2>/dev/null) || return 0
  case "$hook_path" in
    /*) return 0 ;;
    ?*) "$hook" ;;
  esac
  return 0
)

dep_scripts_user_tasks()(
  file="$1"
  test -f "$file" || return 0

  grep -E '^[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)' "$file" 2>/dev/null |
    sed 's/[[:space:]]*().*$//' |
    while IFS= read -r name; do
      dep_is_reserved "$name" || printf '%s\n' "$name"
    done
)

dep_is_user_task_name()(
  case "$1" in
    [a-zA-Z_][a-zA-Z0-9_]*) return 0 ;;
    *) return 1 ;;
  esac
)

dep_script_has_user_task()(
  file="$1"
  task="$2"

  dep_is_user_task_name "$task" || return 1
  test -f "$file" || return 1
  grep -qE "^${task}[[:space:]]*\\(\\)" "$file" 2>/dev/null
)

dep_dep_user_task_matches()(
  root="$1"
  task="$2"
  store=$(dep_store_path "$root")

  dep_is_user_task_name "$task" || return 0
  test -d "$store" || return 0

  for entry in "$store"/*; do
    dep_name=${entry##*/}
    case "$dep_name" in
      ''|.*|*"#"*) continue ;;
    esac
    test -L "$entry" || test -d "$entry" || continue
    dep_dir=$(dep_resolve_dir "$entry" 2>/dev/null) || continue
    scripts_path=$(dep_scripts_path "$dep_dir")
    dep_script_has_user_task "$scripts_path" "$task" || continue
    printf 'dep_name="%s" dep_scripts_path="%s"\n' \
      "$(dep_escape_dq "$dep_name")" "$(dep_escape_dq "$scripts_path")"
  done
)

dep_dep_user_tasks()(
  root="$1"
  store=$(dep_store_path "$root")

  test -d "$store" || return 0

  for entry in "$store"/*; do
    dep_name=${entry##*/}
    case "$dep_name" in
      ''|.*|*"#"*) continue ;;
    esac
    test -L "$entry" || test -d "$entry" || continue
    dep_dir=$(dep_resolve_dir "$entry" 2>/dev/null) || continue
    scripts_path=$(dep_scripts_path "$dep_dir")
    tasks=$(dep_scripts_user_tasks "$scripts_path")
    test -n "$tasks" || continue

    nl='
'
    old_ifs=$IFS
    IFS=$nl
    set -f
    for task in $tasks; do
      test -n "$task" || continue
      printf 'dep_name="%s" dep_task="%s"\n' \
        "$(dep_escape_dq "$dep_name")" "$(dep_escape_dq "$task")"
    done
    set +f
    IFS=$old_ifs
  done
)

dep_has_scripts()(
  pkg_dir="$1"
  test -f "$(dep_scripts_path "$pkg_dir")"
)

dep_prompt_read()(
  prompt="$1"

  if test -r /dev/tty && test -w /dev/tty; then
    printf '%s' "$prompt" > /dev/tty
    IFS= read -r answer < /dev/tty || return 1
    printf '%s\n' "$answer"
    return 0
  fi

  if test -t 0; then
    printf '%s' "$prompt"
    IFS= read -r answer || return 1
    printf '%s\n' "$answer"
    return 0
  fi

  return 1
)

dep_task_needs_trust()(
  root="$1"
  scripts_path="$2"
  store=$(dep_store_path "$root")
  dep_dir=${scripts_path%/*}

  case "$dep_dir" in
    "$store"/*) return 0 ;;
  esac
  return 1
)

dep_run_user_task()(
  root="$1"
  scripts_path="$2"
  task="$3"
  shift 3

  # `scripts_path` est un chemin vers le fichier `@scripts` (nom historique au pluriel).
  # Ici on exécute une seule tâche utilisateur issue de ce fichier.

  if dep_task_needs_trust "$root" "$scripts_path"; then
    dep_is_trusted "$root" || dep_trust_prompt "$root" || return 1
  fi

  scripts_dir=${scripts_path%/*}
  (
    export scripts_dir 
    export scripts_path
    cd "$scripts_dir" || return 1
    . "$scripts_path"
    cd "$root" || return 1
    "$task" "$@"
  )
)

# --- profile ---

dep_profile_add()(
  name="$1"
  content="$2"
  marker_start="# --- dep:$name ---"
  marker_end="# --- /dep:$name ---"

  mkdir -p "$(dirname "$DEP_ENV_FILE")"
  touch "$DEP_ENV_FILE"

  dep_profile_remove "$name"

  printf '%s\n%s\n%s\n' "$marker_start" "$content" "$marker_end" >> "$DEP_ENV_FILE"
)

dep_profile_remove()(
  name="$1"
  test -f "$DEP_ENV_FILE" || return 0

  marker_start="# --- dep:$name ---"
  marker_end="# --- /dep:$name ---"
  tmp="${DEP_ENV_FILE}.tmp"

  skip=0
  while IFS= read -r line; do
    test "$line" = "$marker_start" && skip=1 && continue
    test "$line" = "$marker_end" && skip=0 && continue
    test "$skip" = 0 && printf '%s\n' "$line"
  done < "$DEP_ENV_FILE" > "$tmp"

  mv "$tmp" "$DEP_ENV_FILE"
)

dep_path_add()(
  dir="$1"
  tag=$(printf '%s' "$dir" | sed 's/[^a-zA-Z0-9_-]/_/g')
  dep_profile_add "path_$tag" "export PATH=\"$dir:\$PATH\""
)

dep_path_remove()(
  dir="$1"
  tag=$(printf '%s' "$dir" | sed 's/[^a-zA-Z0-9_-]/_/g')
  dep_profile_remove "path_$tag"
)

# --- trust ---

dep_is_trusted()(
  root="$1"
  trust_file="$(dep_store_path "$root")/$DEP_TRUST_FILE"
  test -f "$trust_file" || return 1
  read -r line < "$trust_file"
  test "$line" = "YES"
)

dep_revoke_trust()(
  root="$1"
  rm -f "$(dep_store_path "$root")/$DEP_TRUST_FILE"
)

dep_trust_prompt()(
  root="$1"
  dep_is_trusted "$root" && return 0

  store=$(dep_store_path "$root")

  has_scripts=0
  for entry in "$store"/*; do
    case "${entry##*/}" in
      *"#"*) ;;
      *) continue ;;
    esac
    real=$(dep_resolve_dir "$entry" 2>/dev/null) || continue
    test -f "$real/$DEP_SCRIPTS_FILE" && has_scripts=1 && break
  done
  test "$has_scripts" = 0 && return 0

  if test "${DEP_AUTO_TRUST:-0}" = 1; then
    printf 'YES\n' > "$store/$DEP_TRUST_FILE"
    return 0
  fi

  echo
  echo "Des dépendances contiennent un fichier @scripts :"
  for entry in "$store"/*; do
    case "${entry##*/}" in
      *"#"*) ;;
      *) continue ;;
    esac
    real=$(dep_resolve_dir "$entry" 2>/dev/null) || continue
    if test -f "$real/$DEP_SCRIPTS_FILE"; then
      printf '  %s/@scripts\n' "$entry"
    fi
  done
  echo
  echo "Lisez ces fichiers avant de continuer."
  if ! answer=$(dep_prompt_read 'Valider ? [YES] '); then
    echo
    echo
    echo "dep: pas de TTY - relancer avec --trust ou DEP_AUTO_TRUST=1 pour valider les hooks"
    return 1
  fi
  answer=${answer:-YES}

  if test "$answer" = "YES"; then
    printf 'YES\n' > "$store/$DEP_TRUST_FILE"
    echo "dépendances validées"
    return 0
  fi

  echo "non validé — les @scripts ne seront pas exécutés"
  return 1
)

dep_ssh_path()(
  printf '%s/%s\n' "$1" "$DEP_SSH_FILE"
)

# --- git ---

dep_git_remote_url()(
  source=$(dep_trim_entry "$1")

  case "$source" in
    https://*/*|http://*/*) printf '%s\n' "$source" ;;
    ssh://*/*) printf '%s\n' "$source" ;;
    git@*:*/*) printf '%s\n' "$source" ;;
    *:*/*) printf 'git@%s\n' "$source" ;;
    *) return 1 ;;
  esac
)

if ! command -v dep_repo_normalize >/dev/null 2>&1; then
  dep_repo_normalize()(
    source=$(dep_trim_entry "$1")

    case "$source" in
      git@*:*/*)
        host=${source#git@}
        host=${host%%:*}
        path=${source#*:}
        printf '%s/%s\n' "$host" "$path"
        ;;
      ssh://*)
        raw=${source#ssh://}
        raw=${raw#*@}
        host=${raw%%/*}
        path=${raw#*/}
        printf '%s/%s\n' "$host" "$path"
        ;;
      https://*|http://*)
        raw=${source#*://}
        raw=${raw#*@}
        host=${raw%%/*}
        path=${raw#*/}
        printf '%s/%s\n' "$host" "$path"
        ;;
      *:*/*)
        host=${source%%:*}
        path=${source#*:}
        printf '%s/%s\n' "$host" "$path"
        ;;
      *)
        printf '%s\n' "$source"
        ;;
    esac
  )
fi

if ! command -v dep_repo_to_ssh >/dev/null 2>&1; then
  dep_repo_to_ssh()(
    repo=$(dep_repo_normalize "$1")
    host=${repo%%/*}
    path=${repo#*/}
    case "$path" in
      "$repo") return 1 ;;
      *) printf 'git@%s:%s\n' "$host" "$path" ;;
    esac
  )
fi

if ! command -v dep_repo_to_https >/dev/null 2>&1; then
  dep_repo_to_https()(
    repo=$(dep_repo_normalize "$1")
    host=${repo%%/*}
    path=${repo#*/}
    case "$path" in
      "$repo") return 1 ;;
      *) printf 'https://%s/%s\n' "$host" "$path" ;;
    esac
  )
fi

if ! command -v dep_git_source_candidates >/dev/null 2>&1; then
  dep_git_source_candidates()(
    source=$(dep_trim_entry "$1")

    case "$source" in
      git@*:*/*|ssh://*/*|https://*/*|http://*/*)
        dep_git_remote_url "$source"
        return
        ;;
      *:*/*)
        ssh_url=$(dep_repo_to_ssh "$source") || return 1
        https_url=$(dep_repo_to_https "$source") || return 1
        printf '%s\n' "$ssh_url"
        test "$https_url" = "$ssh_url" || printf '%s\n' "$https_url"
        return
        ;;
    esac

    return 1
  )
fi

dep_git_candidates_join()(
  source="$1"
  dep_git_source_candidates "$source" | tr '\n' ',' | sed 's/,$//;s/,/, /g'
)

dep_git_try_candidates()(
  pkg_dir="$1"
  source="$2"
  op="$3"
  shift 3

  candidates=$(dep_git_source_candidates "$source") || return 1

  nl='
'
  old_ifs=$IFS
  IFS=$nl
  set -f
  for source_url in $candidates; do
    if "$op" "$pkg_dir" "$source_url" "$@"; then
      printf '%s\n' "$source_url"
      set +f
      IFS=$old_ifs
      return 0
    fi
  done
  set +f
  IFS=$old_ifs

  return 1
)

dep_git_probe_ref_candidate()(
  pkg_dir="$1"
  source_url="$2"
  ref_name="$3"
  hash_file="$4"

  hash=$(dep_git "$pkg_dir" ls-remote "$source_url" "$ref_name" 2>/dev/null | cut -f1 | head -1)
  test -n "$hash" || return 1
  printf '%s\n' "$hash" > "$hash_file"
)

dep_git_clone_candidate()(
  pkg_dir="$1"
  source_url="$2"
  store="$3"

  dep_git "$pkg_dir" clone --recurse-submodules "$source_url" "$store"
)

dep_git_resolve_remote()(
  pkg_dir="$1"
  source="$2"
  ref_name="$3"
  hash_file="${TMPDIR:-/tmp}/dep.$$.git-hash"

  if source_url=$(dep_git_try_candidates "$pkg_dir" "$source" dep_git_probe_ref_candidate "$ref_name" "$hash_file"); then
    hash=$(sed -n '1p' "$hash_file")
    rm -f "$hash_file"
    printf '%s %s\n' "$source_url" "$hash"
    return 0
  fi

  rm -f "$hash_file"
  return 1
)

dep_git_clone_with_fallback()(
  pkg_dir="$1"
  source="$2"
  store="$3"
  preferred_url="${4-}"
  candidates=$(dep_git_source_candidates "$source") || {
    echo "impossible de préparer les sources git pour $source (fallback ssh/https)"
    return 1
  }

  attempts=""
  tried=""
  if test -n "$preferred_url"; then
    attempts=$(dep_append_line "$attempts" "$preferred_url")
  fi

  nl='
'
  old_ifs=$IFS
  IFS=$nl
  set -f
  for source_url in $candidates; do
    attempts=$(dep_append_line "$attempts" "$source_url")
  done

  for source_url in $attempts; do
    test -n "$source_url" || continue
    case "
$tried
" in
      *"
$source_url
"*) continue ;;
    esac
    tried=$(dep_append_line "$tried" "$source_url")
    rm -rf "$store"
    dep_verbose "clone candidate: $source_url -> $store"
    if dep_git "$pkg_dir" clone --recurse-submodules "$source_url" "$store"; then
      printf '%s\n' "$source_url"
      set +f
      IFS=$old_ifs
      return 0
    fi
  done
  set +f
  IFS=$old_ifs

  rm -rf "$store"
  echo "impossible de cloner $source (fallback ssh/https épuisé)"
  return 1
)

dep_git()(
  pkg_dir="$1"; shift
  hosts=""
  ssh_file="$pkg_dir/$DEP_SSH_FILE"
  if test -f "$ssh_file"; then
    hosts="$ssh_file"
  elif test -f "$DEP_KNOWN_HOSTS"; then
    hosts="$DEP_KNOWN_HOSTS"
  fi
  if test -n "$hosts"; then
    GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=$hosts -o StrictHostKeyChecking=yes" \
      git "$@"
  else
    git "$@"
  fi
)
