# Default developer clone strategy: try SSH first, then HTTPS fallback.
# This file is intended to be sourced from ~/.dep/config.sh.

dep_repo_to_ssh()(
  repo=$(dep_repo_normalize "$1")
  host=${repo%%/*}
  path=${repo#*/}
  case "$path" in
    "$repo") return 1 ;;
  esac
  printf 'git@%s:%s\n' "$host" "$path"
)

dep_repo_to_https()(
  repo=$(dep_repo_normalize "$1")
  host=${repo%%/*}
  path=${repo#*/}
  case "$path" in
    "$repo") return 1 ;;
  esac
  printf 'https://%s/%s\n' "$host" "$path"
)

dep_git_source_candidates()(
  source=$(dep_trim_entry "$1")

  case "$source" in
    git@*:*/*|ssh://*/*|https://*/*|http://*/*)
      dep_git_remote_url "$source"
      ;;
    *:*/*)
      ssh_url=$(dep_repo_to_ssh "$source") || return 1
      https_url=$(dep_repo_to_https "$source") || return 1
      printf '%s\n' "$ssh_url"
      test "$https_url" = "$ssh_url" || printf '%s\n' "$https_url"
      ;;
    *)
      return 1
      ;;
  esac
)
