# dep — configuration globale
# ce fichier est sourcé par dep au démarrage (installé dans ~/.dep/config.sh)
# les variables d'environnement ont priorité sur ce fichier

# Stratégie de clone par défaut (dev): SSH puis fallback HTTPS.
# En GitHub Actions, activer automatiquement la stratégie CI.
#
# Override possible via DEP_CLONE_STRATEGY:
#   DEP_CLONE_STRATEGY=default-dev
#   DEP_CLONE_STRATEGY=github-ci

strategy=${DEP_CLONE_STRATEGY:-}
if test -z "$strategy"; then
  if test "${GITHUB_ACTIONS:-}" = "true"; then
    strategy="github-ci"
  else
    strategy="default-dev"
  fi
fi

case "$strategy" in
  github-ci)
    if test -f "${DEP_ROOT:-.}/clone-strategies/github-ci.sh"; then
      . "${DEP_ROOT:-.}/clone-strategies/github-ci.sh"
    elif test -f "${DEP_ROOT:-.}/clone-strategies/default-dev.sh"; then
      . "${DEP_ROOT:-.}/clone-strategies/default-dev.sh"
    fi
    ;;
  default-dev|*)
    if test -f "${DEP_ROOT:-.}/clone-strategies/default-dev.sh"; then
      . "${DEP_ROOT:-.}/clone-strategies/default-dev.sh"
    fi
    ;;
esac
