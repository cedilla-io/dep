unset DEP_CLONE_STRATEGY

# Charge d'abord _lib pour obtenir les fonctions de base,
# puis config.sh qui doit sélectionner la stratégie CI.
. "$DEP_ROOT/commands/_lib.sh"

GITHUB_ACTIONS=true
GITHUB_TOKEN="ci-token"
export GITHUB_ACTIONS GITHUB_TOKEN
. "$DEP_ROOT/config.sh"

candidates=$(dep_git_source_candidates "github.com:acme/tool")
first=$(printf '%s\n' "$candidates" | sed -n '1p')
second=$(printf '%s\n' "$candidates" | sed -n '2p')

assert "config auto CI: https tokenisé en premier" 'test "$first" = "https://x-access-token:ci-token@github.com/acme/tool"'
assert "config auto CI: ssh en second" 'test "$second" = "git@github.com:acme/tool"'

unset GITHUB_ACTIONS GITHUB_TOKEN
