# BDD — Postgres pour GFP

Manifests Kubernetes pour Postgres 16, déployé dans le namespace `gfp` du cluster k3s (voir repo [Kubernetes](https://github.com/tdrula/Kubernetes)).

## Layout

```
kubernetes/
├── postgres-deployment.yaml    Deployment + Service ClusterIP
└── postgres-pvc.yaml           PVC 5Gi sur storageClass local-path (k3s)
```

## Setup initial

```bash
# 1. Créer le secret avec les credentials (une seule fois)
make secret-create
# Input :
#   POSTGRES_DB:       gfp
#   POSTGRES_USER:     gfp
#   POSTGRES_PASSWORD: <choisir>

# 2. Appliquer les manifests
make apply

# 3. Vérifier
make status
```

## Connexion depuis l'API

L'API consomme `DATABASE_URL` (cf. repo `GFP`). Format attendu :

```
postgresql://<user>:<password>@postgres.gfp.svc.cluster.local:5432/<db>?serverVersion=16&charset=utf8
```

Le hostname `postgres.gfp.svc.cluster.local` est résolu par CoreDNS — il pointe sur le `Service postgres` défini ici.

## Choix techniques

- **Deployment** plutôt que **StatefulSet** : 1 seul replica + PVC `RWO` + `strategy: Recreate` suffisent. StatefulSet aurait été pertinent en HA multi-nœuds.
- **`subPath: pgdata`** : évite l'erreur "directory not empty" quand Postgres rencontre `lost+found` à la racine du volume.
- **`storageClassName: local-path`** : storage class par défaut de k3s, provisionne sur le disque du nœud.

## Secret à créer hors-repo

Le secret `postgres-secret` n'est jamais committé. Il contient :

- `POSTGRES_DB`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`

Et est référencé via `envFrom: secretRef` dans le Deployment.
