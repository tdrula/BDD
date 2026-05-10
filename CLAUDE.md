# CLAUDE.md — BDD

Ce repo concerne **la base de données Postgres** consommée par les APIs Symfony (`GFP`) et Go (`GFP_GO`).

## Périmètre — IMPORTANT

- ✅ **Ce repo** : Postgres standalone pour dev local (docker-compose), scripts d'ops, modèle/schéma (à venir)
- ❌ **Pas ici** : les manifests Kubernetes de Postgres — ils vivent dans le repo `Kubernetes/manifests/database/postgres/`

Si on te demande "ajoute Postgres dans le cluster K8s", c'est dans `~/Projects/Kubernetes` qu'il faut aller, pas ici.

## Stack

- **Postgres 16** (image `postgres:16-alpine`)
- **docker-compose** pour le dev local
- Volume Docker : `bdd_postgres_data`
- Credentials par défaut : `gfp / gfp / gfp` (override via `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`)

## Commandes utiles

```bash
make up                                          # démarre Postgres en local
make psql                                        # shell psql
make backup                                      # → ~/Backups/postgres/gfp-TS.sql
make restore FILE=~/Backups/postgres/gfp-X.sql   # restaure
make nuke                                        # détruit le volume (DESTRUCTIF)
```

## Backups

Les dumps vivent **hors du repo**, dans `~/Backups/postgres/`. Jamais committés. Cf. README pour le workflow.

## Migrations

Pas ici. Les migrations Doctrine sont dans le repo `GFP` (couplage fort avec les entités Symfony, exécutées par `make db-migrate` côté GFP).

## Repos liés

- [`GFP`](https://github.com/tdrula/GFP) — API Symfony qui consomme cette BDD
- [`GFP_GO`](https://github.com/tdrula/GFP_GO) — API Go qui consomme aussi cette BDD
- [`Kubernetes`](https://github.com/tdrula/Kubernetes) — orchestration du cluster k3s (où Postgres tourne en prod)

## Convention

Les variables `USER` et `HOME` sont des env vars shell — ne pas utiliser ces noms dans le Makefile (collision). On utilise `PG_USER` et `PG_DB`.
