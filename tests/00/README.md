# Test 00

Ce scénario construit un gros graphe E2E dans `tests/00/sandbox/`.

- plusieurs sous-projets fs dans `workspace/`
- plusieurs repos git locaux dans `repos/`
- `@manifest` et `@lock` à la racine des paquets
- dépendances transitives fs + git
- cycle git entre `helpers` et `theme`
- une seule chaîne par dep, sans alias `name=source`
- scénario réduit pour garder un `workspace/.@` lisible
- aucun nettoyage en fin de test

Le test reconstruit le scénario au début de chaque exécution, puis laisse l'état final en place pour inspection.