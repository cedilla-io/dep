# Coding style shell

Conventions pour le code de dep.

## Fonctions

Toujours utiliser le pattern subshell :

```bash
# oui
ma_fonction()(
  echo "isolé"
)

# non
ma_fonction() {
  echo "pas isolé"
}
```

La forme `f()(...)` exécute le corps dans un sous-shell.
Les variables sont automatiquement isolées, pas besoin de `local`.

## Variables

- pas de `local` (pas portable)
- pas de préfixe underscore (`_var`)
- noms courts et explicites

## Conditions

Utiliser `test` explicitement :

```bash
# oui
test -f "$file" && echo "existe"
test "$a" = "$b"
test -z "$var"

# non
[ -f "$file" ]
[[ "$a" == "$b" ]]
```

## Pattern matching

Utiliser `case` :

```bash
case "$entry" in
  *@*) echo "git" ;;
  *)   echo "fs" ;;
esac
```

## Retour de valeurs

Les fonctions subshell ne peuvent pas modifier les variables du parent.
Utiliser `printf` / `echo` + `eval` ou substitution :

```bash
dep_parse()(
  printf 'name="%s" proto="%s"\n' "$name" "$proto"
)

eval "$(dep_parse "$entry")"
```

## Formatage

- indentation : 2 espaces
- pas de couleurs / codes ANSI
- accents autorisés dans la sortie utilisateur
- privilégier l'ASCII étendu pour le texte courant ; pas d'UTF exotique
- pas d'emoji

## @manifest, @lock et @scripts

Le `@manifest` et le `@lock` sont du **texte brut** — jamais sourcés par dep.

```
1.0.0
./libs/mylib
github.com/acme/tool@v1
```

- Première ligne : version (minimale pour `@manifest`, exacte pour `@lock`).
- Lignes suivantes : une dépendance par ligne.
- `#` pour les commentaires, lignes vides ignorées.

Le `@scripts` est le seul fichier shell sourcé par dep. Il contient les hooks et les tâches :

```sh
install()(
  echo "post-sync"
)

build()(
  make -C src
)
```

### Noms réservés dans @scripts

`install`, `uninstall`, `global_install`, `global_uninstall`.

Tout le reste = tâche utilisateur (visible dans `dep help`, exécutable via `dep <tâche>`).

## Scripts d'entrée

Les scripts executables utilisent le pattern :

```bash
#!/bin/sh
set -eu

main()(
  # ...
)

main "$@"
```
