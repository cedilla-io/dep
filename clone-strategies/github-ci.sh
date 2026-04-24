# GitHub CI clone strategy.
# - With GITHUB_TOKEN: prefer tokenized HTTPS, then SSH fallback.
# - Without GITHUB_TOKEN: prefer SSH first, then plain HTTPS fallback.

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

  case "$host" in
    github.com)
      if test -n "${GITHUB_TOKEN:-}"; then
        printf 'https://x-access-token:%s@%s/%s\n' "$GITHUB_TOKEN" "$host" "$path"
      else
        printf 'https://%s/%s\n' "$host" "$path"
      fi
      ;;
    *)
      printf 'https://%s/%s\n' "$host" "$path"
      ;;
  esac
)

dep_git_source_candidates()(
  source=$(dep_trim_entry "$1")

  case "$source" in
    https://*/*|http://*/*)
      dep_git_remote_url "$source"
      ;;
    git@*:*/*|ssh://*/*)
      dep_git_remote_url "$source"
      ;;
    *:*/*)
      https_url=$(dep_repo_to_https "$source") || return 1
      ssh_url=$(dep_repo_to_ssh "$source") || return 1
      if test -n "${GITHUB_TOKEN:-}"; then
        printf '%s\n' "$https_url"
        test "$ssh_url" = "$https_url" || printf '%s\n' "$ssh_url"
      else
        printf '%s\n' "$ssh_url"
        test "$https_url" = "$ssh_url" || printf '%s\n' "$https_url"
      fi
      ;;
    *)
      return 1
      ;;
  esac
)
