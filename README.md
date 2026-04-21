# dep

Gestionnaire de dépendances shell minimaliste. POSIX `sh`, pas de runtime, pas de registre.

## Installation

```sh
curl -sSL https://<hôte>/dep/install.sh | sh
```

Remplacer `<hôte>` par l'URL du miroir. Le script s'installe dans `~/.dep`, crée `~/.local/bin/dep`, et injecte une ligne dans le rc du shell courant (bash, zsh, fish ou `.profile`). Pas de `sudo`, pas de logout.

### Depuis les sources

```sh
sh install.sh        # copie dans ~/.dep, lie dans ~/.local/bin
sh uninstall.sh      # supprime tout
```

### Installation stricte (serveurs privés, SSH verrouillé)

```sh
echo "gitlab.example.com ssh-ed25519 AAAA...">/tmp/k&&GIT_SSH_COMMAND="ssh -oUserKnownHostsFile=/tmp/k" git clone --depth 1 git@gitlab.example.com:group/dep.git /tmp/d&&sh /tmp/d/install.sh;rm -rf /tmp/d /tmp/k
```

Empreinte via `ssh-keyscan -t ed25519 gitlab.example.com`.

Dépendances : `sh` POSIX, `git`, `sed`, `grep`.

## Démarrage rapide

```sh
dep init                              # crée @manifest + .@/
dep add ./libs/mylib                  # dep locale (symlink)
dep add github.com/acme/tool@v1      # dep git (clone shallow)
dep sync                              # installe tout
dep update                            # ré-résout les refs git
dep list                              # affiche le statut
dep remove tool                       # retire une dep
```

## Commandes

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
| `dep <tâche> [args]` | Exécute une tâche du `@scripts` |
| `dep global <cmd>` | Mode global (racine = `~/.dep`) |
| `dep --trust sync` | Sync sans prompt interactif (CI) |
| `dep --version` | Affiche la version |

## Tests

20 scénarios d'intégration (init, add, sync, update, remove, hooks, trust, global, etc.).

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
    lib -> lib#abc1/
    lib#abc1/
```

## @manifest

```
1.0.0                          # version min de dep requise
./libs/core                    # dep locale (symlink)
github.com/acme/tool@v1       # dep git (clone shallow)
```

Texte brut, jamais sourcé. Lignes `#` = commentaires.

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

Les hooks des deps git ne s'exécutent qu'après validation (voir [FAQ](docs/faq.md)).

## Mode global

```sh
dep global init && dep global add github.com/acme/sdk@v1 && dep global sync
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
- [Style](CODING-STYLE.md) — conventions de code
