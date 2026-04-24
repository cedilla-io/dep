# dep — configuration globale
# ce fichier est sourcé par dep au démarrage (installé dans ~/.dep/config.sh)
# les variables d'environnement ont priorité sur ce fichier

# Stratégie de clone par défaut (dev): SSH puis fallback HTTPS.
# Décommenter la ligne CI pour forcer HTTPS tokenisé GitHub.
if test -f "${DEP_ROOT:-.}/clone-strategies/default-dev.sh"; then
  . "${DEP_ROOT:-.}/clone-strategies/default-dev.sh"
fi
# if test -f "${DEP_ROOT:-.}/clone-strategies/github-ci.sh"; then
#   . "${DEP_ROOT:-.}/clone-strategies/github-ci.sh"
# fi
