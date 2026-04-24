unset GITHUB_TOKEN
. "$DEP_ROOT/commands/_lib.sh"
. "$DEP_ROOT/clone-strategies/github-ci.sh"

candidates_no_token=$(dep_git_source_candidates "github.com:acme/tool")
first_no_token=$(printf '%s\n' "$candidates_no_token" | sed -n '1p')
second_no_token=$(printf '%s\n' "$candidates_no_token" | sed -n '2p')

assert "github-ci sans token: ssh en premier" 'test "$first_no_token" = "git@github.com:acme/tool"'
assert "github-ci sans token: https en second" 'test "$second_no_token" = "https://github.com/acme/tool"'
assert "github-ci sans token: https non tokenise" 'test "$(dep_repo_to_https "github.com:acme/tool")" = "https://github.com/acme/tool"'

GITHUB_TOKEN="secret-token"
export GITHUB_TOKEN

candidates_with_token=$(dep_git_source_candidates "github.com:acme/tool")
first_with_token=$(printf '%s\n' "$candidates_with_token" | sed -n '1p')
second_with_token=$(printf '%s\n' "$candidates_with_token" | sed -n '2p')

assert "github-ci avec token: https en premier" 'test "$first_with_token" = "https://x-access-token:secret-token@github.com/acme/tool"'
assert "github-ci avec token: ssh en second" 'test "$second_with_token" = "git@github.com:acme/tool"'
assert "github-ci avec token: https tokenise" 'test "$(dep_repo_to_https "github.com:acme/tool")" = "https://x-access-token:secret-token@github.com/acme/tool"'
