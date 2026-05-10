DOCKER_COMPOSE = docker compose
CONTAINER = gfp_postgres
DB ?= gfp
USER ?= gfp

GREEN = \033[0;32m
NC = \033[0m

.PHONY: help up down restart logs psql backup ready

help: ## Liste les cibles
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-12s$(NC) %s\n", $$1, $$2}'

## —— Lifecycle ————————————————————————————————————————————————————
up: ## Démarre Postgres en local (port 5432)
	$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)Postgres available on localhost:5432$(NC)"

down: ## Arrête Postgres (les données restent dans le volume)
	$(DOCKER_COMPOSE) down

restart: down up ## Redémarre

ready: ## Attend que Postgres soit prêt à accepter des connexions
	@for i in 1 2 3 4 5 6 7 8 9 10; do \
		docker exec $(CONTAINER) pg_isready -U $(USER) >/dev/null 2>&1 && echo "ready" && exit 0; \
		sleep 1; \
	done; \
	echo "timeout"; exit 1

## —— Ops ——————————————————————————————————————————————————————————
logs: ## Tail des logs Postgres
	$(DOCKER_COMPOSE) logs -f postgres

psql: ## Ouvre un shell psql sur la base
	docker exec -it $(CONTAINER) psql -U $(USER) -d $(DB)

backup: ## Dump dans ./backup-YYYYMMDD-HHMMSS.sql
	@ts=$$(date +%Y%m%d-%H%M%S); \
	docker exec $(CONTAINER) pg_dumpall -U $(USER) > backup-$$ts.sql; \
	echo "$(GREEN)Backup écrit dans ./backup-$$ts.sql$(NC)"

## —— Reset complet (destructif) ——————————————————————————————————
nuke: ## Supprime conteneur ET volume (DESTRUCTIF — perd toutes les données locales)
	$(DOCKER_COMPOSE) down -v
