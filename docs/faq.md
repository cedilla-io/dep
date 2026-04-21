# FAQ

**Pourquoi `@manifest` et `@lock` comme noms ?**
Le préfixe `@` les rend visibles (pas cachés) et les trie en premier dans un `ls`. Pas de collision avec des noms de fichier usuels.

**Pourquoi `.@/` comme store ?**
Le point le rend caché. Le `@` le distingue des dossiers applicatifs.

**Pourquoi du shell POSIX et pas bash ?**
Portabilité maximale. dash est disponible partout, y compris dans les conteneurs minimaux et les CI sans bash.

**Pourquoi `f()(...)` au lieu de `f() { ... }` ?**
La forme subshell isole automatiquement les variables. Pas besoin de `local` (qui n'est pas POSIX).

**Pourquoi pas de résolution de conflit de version ?**
Si `mod-a` veut `lib@v1` et `mod-b` veut `lib@v2`, les deux clones coexistent. Chaque consommateur voit sa version, sans casse silencieuse.

**Que se passe-t-il si je lance `dep` depuis un sous-dossier ?**
dep remonte l'arborescence jusqu'à trouver un `@manifest`.

**Le `@manifest` est-il exécutable ?**
Non. Texte brut, lu ligne par ligne, jamais sourcé.

**Comment versionner un projet dep ?**
`@manifest`, `@lock`, `@scripts` : commités. `.@/` : dans le `.gitignore`.

**`dep update` vs `dep sync` ?**
`sync` respecte le `@lock`. `update` supprime le `@lock`, révoque le trust, puis relance `sync`.

**Comment retirer une dep sans supprimer du store ?**
Éditer `@manifest` à la main, puis `dep sync`.

**Pourquoi le prompt de validation ?**
Le `@scripts` d'une dep git est du shell sourcé par dep. Le prompt force l'inspection avant exécution.

**Comment révoquer la confiance ?**
Supprimer `.@/trust` ou lancer `dep unsync`.

**Les clones SSH échouent ?**
Le `known_hosts` global (`~/.dep/known_hosts`) couvre github.com, gitlab.com, bitbucket.org, codeberg.org. Pour un serveur privé : `ssh-keyscan host >> @ssh`.

**Puis-je utiliser dep dans un CI ?**
`sh install.sh && dep --trust sync` ou `DEP_AUTO_TRUST=1 dep sync`.
