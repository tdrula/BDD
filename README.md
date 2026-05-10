# BDD — Modèle de données et ops Postgres

Documentation et outils autour de la base Postgres consommée par l'API Symfony (`GFP`) et l'API Go (`GFP_GO`).

## Périmètre du repo

Ce repo **ne contient pas** les manifests Kubernetes de Postgres — ils vivent dans le repo [Kubernetes](https://github.com/tdrula/Kubernetes), sous `manifests/database/postgres/`. Le déploiement de la base et le `make apply-database` se font depuis là-bas.

Ce repo contient (à terme) :

- `docs/` — schéma logique, ERD, conventions de nommage, contraintes
- `scripts/` — scripts de seed, de backup/restore standalone, d'import de jeux de données
- `migrations-notes/` — notes sur les migrations majeures (raisons, impacts perfs)

Les **migrations** Doctrine restent dans le repo `GFP` (couplage fort avec les entités Symfony, exécutées par `make db-migrate`).

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
