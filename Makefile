DOCKER_COMPOSE = docker compose
CONTAINER = gfp_postgres
DB ?= gfp
USER ?= gfp

GREEN = \033[0;32m
NC = \033[0m

.PHONY: help up down restart logs psql backup backup-list restore ready nuke

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

## —— Backups ——————————————————————————————————————————————————————
# Tous les backups vivent HORS du repo (pas committés) dans ~/Backups/postgres/
BACKUP_DIR = $(HOME)/Backups/postgres

backup: ## Dump la base courante dans ~/Backups/postgres/gfp-YYYYMMDD-HHMMSS.sql
	@mkdir -p $(BACKUP_DIR)
	@ts=$$(date +%Y%m%d-%H%M%S); \
	out=$(BACKUP_DIR)/gfp-$$ts.sql; \
	docker exec $(CONTAINER) pg_dump -U $(USER) -d $(DB) --no-owner --no-acl --clean --if-exists > $$out; \
	echo "$(GREEN)Backup → $$out ($$(du -h $$out | cut -f1))$(NC)"

backup-list: ## Liste les backups disponibles
	@ls -lh $(BACKUP_DIR)/*.sql 2>/dev/null || echo "Aucun backup dans $(BACKUP_DIR)"

restore: ## Restaure depuis un dump : make restore FILE=~/Backups/postgres/gfp-XXXX.sql
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make restore FILE=$(BACKUP_DIR)/gfp-YYYYMMDD-HHMMSS.sql"; \
		echo ""; echo "Backups disponibles :"; \
		ls -1t $(BACKUP_DIR)/*.sql 2>/dev/null | head -5; \
		exit 1; \
	fi
	@echo "$(GREEN)Restoring from $(FILE)...$(NC)"
	docker exec -i $(CONTAINER) psql -U $(USER) -d $(DB) < $(FILE)
	@echo "$(GREEN)Restore done.$(NC)"

## —— Reset complet (destructif) ——————————————————————————————————
nuke: ## Supprime conteneur ET volume (DESTRUCTIF — perd toutes les données locales)
	$(DOCKER_COMPOSE) down -v
