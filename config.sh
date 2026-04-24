# dep — configuration globale
# ce fichier est sourcé par dep au démarrage (installé dans ~/.dep/config.sh)
# les variables d'environnement ont priorité sur ce fichier

# Stratégie de clone par défaut (dev): SSH puis fallback HTTPS.
# En GitHub Actions, activer automatiquement la stratégie CI.
#
# Override possible via DEP_CLONE_STRATEGY:
#   DEP_CLONE_STRATEGY=default-dev
#   DEP_CLONE_STRATEGY=github-ci

strategy=${DEP_CLONE_STRATEGY:-default-dev}


. "${DEP_ROOT:-.}/clone-strategies/$strategy.sh"
