# BDD — Modèle de données et ops Postgres

Documentation et outils autour de la base Postgres consommée par l'API Symfony (`GFP`) et l'API Go (`GFP_GO`).

## Périmètre du repo

Ce repo concerne tout ce qui touche à la **base de données elle-même** : faire tourner Postgres en local, documenter le modèle, scripts d'ops.

Il **ne contient pas** les manifests Kubernetes — ils vivent dans le repo [Kubernetes](https://github.com/tdrula/Kubernetes), sous `manifests/database/postgres/`. Le déploiement *en cluster* se fait depuis là-bas.

Contenu :

- `docker-compose.yml` + `Makefile` — Postgres standalone pour dev local
- `init/` — scripts SQL exécutés au premier démarrage du container (seed, extensions…)
- (à venir) `docs/` — schéma logique, ERD, conventions
- (à venir) `scripts/` — backup/restore standalone, imports de jeux de données

Les **migrations Doctrine** restent dans le repo `GFP` (couplage fort avec les entités Symfony, exécutées par `make db-migrate`).

## Lancer Postgres en local

```bash
make up
make ready          # attend que Postgres accepte des connexions
make psql           # shell psql interactif
make logs           # tail des logs
make down           # arrête (données conservées dans le volume)
make nuke           # arrête + supprime le volume (perd toutes les données)
```

Override des credentials par défaut :

```bash
POSTGRES_DB=foo POSTGRES_USER=bar POSTGRES_PASSWORD=baz make up
```

L'API Symfony (`GFP`) et l'API Go (`GFP_GO`) consomment ce Postgres via `DATABASE_URL`. Voir leurs `.env.local` respectifs.

## Backups

Les backups vivent **hors du repo** dans `~/Backups/postgres/` (jamais committés).

```bash
make backup                                              # crée ~/Backups/postgres/gfp-YYYYMMDD-HHMMSS.sql
make backup-list                                         # liste les backups disponibles
make restore FILE=~/Backups/postgres/gfp-XXXXXX.sql      # restaure depuis un dump
```

Workflow typique :

```bash
# Avant de toucher à la BDD
make backup

# Si quelque chose foire
make nuke           # détruit le container + volume
make up             # repart sur du frais
make restore FILE=$(ls -1t ~/Backups/postgres/*.sql | head -1)
```

Le dump est généré avec `--no-owner --no-acl --clean --if-exists` : restorable dans n'importe quelle base/user, idempotent (drop + recreate les tables).

## Connexion depuis les APIs

Format DATABASE_URL injecté via le Secret `gfp-secret` (cf. README du repo Kubernetes) :

| API | Format URL | Driver |
|---|---|---|
| Symfony | `postgresql://user:pass@host:5432/db?serverVersion=16&charset=utf8` | Doctrine DBAL |
| Go | `postgres://user:pass@host:5432/db?sslmode=disable` | pgx |

Hostname interne du cluster : `postgres.gfp.svc.cluster.local` (résolu par CoreDNS).

## Choix techniques (résumé)

- **Postgres 16** sur image `postgres:16-alpine`
- **Storage** : PVC 5Gi sur `local-path` (storage class par défaut de k3s)
- **Deployment** plutôt que **StatefulSet** (1 replica suffit ici, RWO + `strategy: Recreate`)
- **`subPath: pgdata`** sur le mount pour éviter l'erreur "directory not empty"
- Credentials en **Secret** `postgres-secret`, jamais committés
