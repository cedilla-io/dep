# Example custom git resolution strategy for dep.
# Source this file from ~/.dep/config.sh, e.g.:
#   . "$DEP_ROOT/docs/git-strategy.example.sh"
# or copy the functions directly into ~/.dep/config.sh.

# Optional: normalize custom source syntaxes into host/path(.git).
# dep_repo_normalize()(
#   printf '%s\n' "$1"
# )

# Convert a repo identifier (host/path) to an SSH URL.
dep_repo_to_ssh()(
  repo=$(dep_repo_normalize "$1")
  host=${repo%%/*}
  path=${repo#*/}

  case "$host" in
    gitlab.com) printf 'git@%s:%s\n' "$host" "${path%.git}.git" ;;
    github.com) printf 'git@%s:%s\n' "$host" "${path%.git}.git" ;;
    *) printf 'git@%s:%s\n' "$host" "${path%.git}.git" ;;
  esac
)

# Convert a repo identifier (host/path) to an HTTPS URL.
# Useful for token-based auth by host.
dep_repo_to_https()(
  repo=$(dep_repo_normalize "$1")
  host=${repo%%/*}
  path=${repo#*/}
  path="${path%.git}.git"

  case "$host" in
    gitlab.com)
      printf 'https://oauth2:%s@%s/%s\n' "${GITLAB_TOKEN:-}" "$host" "$path"
      ;;
    github.com)
      printf 'https://x-access-token:%s@%s/%s\n' "${GITHUB_TOKEN:-}" "$host" "$path"
      ;;
    *)
      printf 'https://%s/%s\n' "$host" "$path"
      ;;
  esac
)

# Optional full strategy override (default: ssh first, then https for host:path/repo sources).
# dep_git_source_candidates()(
#   source="$1"
#   printf '%s\n' "$(dep_repo_to_https "$source")"
# )
