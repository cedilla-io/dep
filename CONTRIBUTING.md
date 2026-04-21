# Contribuer

Merci de l'intérêt porté à dep.

## Avant de coder

- Lire [CODING-STYLE.md](CODING-STYLE.md) — POSIX `sh` strict, subshell `f()(...)`, pas de `local`, pas de bashismes.
- Pour un changement non-trivial, ouvrir une issue d'abord.

## Tester

```sh
dash tests/run.sh
```

Les 20 scénarios doivent passer sur `dash` (pas seulement sur `bash`). Ajouter un test pour toute nouvelle fonctionnalité ou correction de bug.

## Envoyer une MR / PR

- Un changement logique = une MR.
- Messages de commit concis, à l'impératif (`ajoute X`, `corrige Y`).
- Pas de reformatage massif non lié au changement.
- Mettre à jour `CHANGELOG.md` sous `## [Unreleased]` si la modification est visible par l'utilisateur.

## Licence

Toute contribution est placée sous la même licence que le projet ([GPL-3.0](LICENCE.txt)).
