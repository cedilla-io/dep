# Pourquoi dep ?

## Le problème

Vous avez plusieurs projets qui dépendent de scripts shell partagés, d'outils internes, de snippets de config. Aujourd'hui vos options sont :

- **`git submodule`** — fonctionne, mais douloureux : `git clone --recursive` oublié, détachement de HEAD silencieux, pas de hooks, pas de lockfile digne de ce nom.
- **Copier-coller** — rapide au début, cauchemar à la troisième divergence.
- **`npm` / `cargo` / `pip`** — 400 Mo de `node_modules` pour lier trois fichiers `.sh`. Et il faut un runtime lourd là où vous ne vouliez aucun.
- **Scripts d'installation maison** — chacun réinvente la roue, sans verrouillage de version, sans audit, sans uniformité.

## La réponse de dep

Un gestionnaire de dépendances **pour les gens qui n'en voulaient pas**.

- **Zéro runtime.** POSIX `sh`. Marche sur `dash`, dans Alpine, dans BusyBox, en CI minimale, en conteneur sans `bash`.
- **`@manifest` est du texte brut, jamais sourcé.** `cat @manifest` : vous avez tout compris. Zéro exécution implicite, zéro vecteur d'injection.
- **Pas de résolution de conflit de version.** Si `mod-a` veut `lib@v1` et `mod-b` veut `lib@v2`, les deux clones coexistent. Aucune casse silencieuse, aucun algo de satisfaction de contraintes à déboguer.
- **Trust model explicite.** Les `@scripts` d'une dep git ne s'exécutent qu'après validation humaine. L'inverse de `npm install`.
- **Per-user, pas de `sudo`.** Installation dans `~/.local/bin`, aucune écriture hors du home.

## Ce que dep n'est pas

- **Pas un remplaçant de `npm` / `cargo` / `pip`.** Si vous faites du Node ou du Rust, restez sur leurs outils.
- **Pas un registre.** Pas de `dep publish`. Les dépendances sont des URLs git ou des chemins fs.
- **Pas une solution à la résolution transitive de versions.** C'est un choix assumé.

## À qui dep s'adresse

- DevOps / SREs qui gèrent des scripts shell partagés entre projets.
- Mainteneurs de dotfiles, de pipelines CI, d'outils internes d'équipe.
- Toute équipe qui a dit un jour : *« j'aimerais bien un `npm install` pour nos scripts bash, mais sans npm ».*

Si vous avez déjà tapé `git submodule update --init --recursive` trois fois cette semaine, `dep` est pour vous.
