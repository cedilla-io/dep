# dep

Gestionnaire de dépendances shell minimaliste. POSIX `sh`, pas de runtime, pas de registre.

## Installation

```sh
curl  -sSL https://raw.githubusercontent.com/cedilla-io/dep/refs/heads/master/install.sh | sh
```

Le script s'installe dans `~/.dep`, crée `~/.local/bin/dep`, et injecte une ligne dans le rc du shell courant (bash, zsh, fish ou `.profile`).


## Toutes les commandes

| Commande | Description |
|---|---|
| `dep init` | Crée `@manifest` et `.@/` |
| `dep add <source[@ref]>` | Ajoute une dépendance et lance `sync` |
| `dep sync` | Installe les deps du `@manifest` |
| `dep update` | Supprime `@lock`, révoque le trust, relance `sync` |
| `dep remove <nom>` | Retire du `@manifest`, `@lock` et store |
| `dep unsync [nom]` | Nettoie le store sans toucher au `@manifest` |
| `dep list` | Affiche les deps et leur statut |
| `dep help` | Aide + tâches disponibles |
| `dep <tâche> [args]` | Exécute une tâche du projet ou d'une dep |
| `dep global <cmd>` | Mode global (racine = `~/.dep`) |
| `dep --trust sync` | Sync sans prompt interactif (CI) |
| `dep --version` | Affiche la version |


## Moyens de fetch

```sh
dep add ./libs/mylib                 # dep locale (symlink)
dep add ./libs/mylib@branch          # dep locale (via git clone)
dep add github.com:acme/tool@v1      # selon la strategie
dep add git@github.com:acme/tool.git # dep git SSH explicite
dep add https://github.com/acme/tool.git@main # dep git HTTPS explicite
```

## Lancer les tests

```sh
dash tests/run.sh
```

## Structure

```
projet/
  @manifest           # deps (texte brut, jamais sourcé)
  @lock               # versions résolues (généré)
  @scripts            # hooks + tâches (seul fichier sourcé)
  @ssh                # empreintes SSH (format known_hosts)
  .@/                 # store (gitignorer)
    lib@v1 -> lib#abc1/  # Dans le cas d'une dep locale sans git
    lib#abc1/
```

### Store partagé (règle unique)

`dep` utilise **un seul store** par projet : `projet/.@/`.

- Pour la racine du projet, `.@/` est un dossier réel.
- Pour chaque dépendance qui a son propre `@manifest`, son `.@/` est un **lien symbolique unique** vers le store racine.
- `dep` n'écrit pas de mini-store imbriqué dans les deps (`dep/.@/lib -> ...`), afin d'éviter les arborescences éclatées.

Concrètement :

```
.@/
  somedep@v1 -> ./somedep#<hash-v1>
  somedep@v2 -> ./somedep#<hash-v2>
  localdep -> /abs/path/localdep
  somedep#<hash>/
    .@/ -> ../../.@
```

Le lien court `name` est réservé aux deps **filesystem locales**.
Pour les deps git, `dep` n'expose pas de lien court canonique : il faut utiliser
`name@ref`.

## Résolution et conflits de versions

Politique actuelle (simple et explicite) :

- Toutes les versions git demandées sont clonées dans le store (`name#hash`).
- Chaque dépendance git résolue crée un alias branché : `.@/name@ref -> .@/name#hash`.
- En cas de conflit (`mod-a` demande `lib@v1`, `mod-b` demande `lib@v2`), les deux hashes **et** les deux alias `lib@v1` / `lib@v2` coexistent.

Implication : la gestion fine de compatibilité (ex: semver entre modules) reste volontairement à la charge de l'utilisateur/projet.

## Changement de @manifest : algorithme de sync (haut niveau)

À chaque `dep sync` :

1. Lire `@manifest` (texte brut), valider la version minimale de `dep`.
2. Résoudre chaque entrée :
   - fs: créer/mettre à jour `.@/name -> target`.
   - git: résoudre `ref -> hash`, cloner `name#hash` si absent, puis pointer `.@/name@ref -> .@/name#hash`.
3. Réécrire `@lock` depuis l'état réellement résolu.
4. Descendre récursivement dans les deps ayant un `@manifest`.
5. Exécuter les hooks `install` après phase de trust (pour les deps git).

Effet pratique : toute modification du `@manifest` est détectée/recalculée automatiquement par la reconstruction du lock et des liens pendant `sync`.

### Règle de cohérence `@manifest` / `@lock`

- `dep sync` traite `@lock` comme la source de vérité des hashes déjà résolus.
- Tant que `@lock` contient une entrée pour une dep git donnée, `sync` **conserve ce hash** (même si la branche distante a avancé).
- `dep update` supprime `@lock` puis relance la résolution : c'est l'opération explicite pour avancer les hashes.

## Projet sans Git

`dep` fonctionne sans dépôt Git local :

- `@manifest` / `@lock` restent les sources de vérité.
- Si le projet n'est pas versionné, ces fichiers continuent de fonctionner de la même manière.
- Recommandation : garder `.@/` ignoré (fichiers générés), et versionner `@manifest` (+ `@lock` si vous voulez figer les hashes).

## format @manifest

```
1.0.0                          # version min de dep requise
./libs/core                    # dep locale (symlink)
github.com:acme/tool@v1       # dep git SSH (clone shallow)
```
Texte brut. Lignes `#` = commentaires.

### Stratégie Git configurable (hooks)

`dep` source `~/.dep/config.sh` au démarrage. Vous pouvez y surcharger:

- `dep_repo_to_ssh(repo)` pour produire l'URL SSH.
- `dep_repo_to_https(repo)` pour produire l'URL HTTPS.
- `dep_git_source_candidates(source)` pour forcer un ordre de fallback.

Des stratégies prêtes à l'emploi sont fournies dans `clone-strategy/`:

- `clone-strategy/default-dev.sh` (par défaut) : SSH puis HTTPS
- `clone-strategy/github-ci.sh` : HTTPS tokenisé GitHub en priorité

## @scripts

```sh
install()(
  echo "post-sync"
)

build()(
  make -C src
)
```

Hooks réservés : `install`, `uninstall`, `global_install`, `global_uninstall`.
Tout le reste = tâche utilisateur (`dep build`).
Les tâches du projet sont prioritaires ; si plusieurs deps exposent le même nom, dep refuse avec une erreur d'ambiguïté.

Les hooks des deps git ne s'exécutent qu'après validation (voir [FAQ](docs/faq.md)).

## Mode global

```sh
dep global init && dep global add github.com:acme/sdk@v1 && dep global sync
```

Hooks : `global_install` / `global_uninstall`. Primitives : `dep_profile_add`, `dep_path_add`, etc.

## CI

```sh
sh install.sh && dep --trust sync
# ou
DEP_AUTO_TRUST=1 dep sync
```

## Documentation

- [FAQ](docs/faq.md) — questions fréquentes
- [Style](CODING_STYLE.md) — conventions de code
