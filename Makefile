NAMESPACE = gfp

GREEN = \033[0;32m
NC = \033[0m

.PHONY: help apply secret-create status psql backup

help: ## Liste les cibles
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-18s$(NC) %s\n", $$1, $$2}'

apply: ## Applique le PVC + Deployment + Service Postgres
	kubectl apply -f kubernetes/

secret-create: ## Crée le secret postgres-secret (à lancer une fois)
	@read -p "POSTGRES_DB: " db; \
	read -p "POSTGRES_USER: " user; \
	read -s -p "POSTGRES_PASSWORD: " pass; echo; \
	kubectl -n $(NAMESPACE) create secret generic postgres-secret \
		--from-literal=POSTGRES_DB=$$db \
		--from-literal=POSTGRES_USER=$$user \
		--from-literal=POSTGRES_PASSWORD=$$pass

status: ## État du Postgres dans le cluster
	kubectl -n $(NAMESPACE) get pods,svc,pvc -l app=postgres

psql: ## Ouvre psql dans le pod Postgres
	kubectl -n $(NAMESPACE) exec -it deploy/postgres -- psql -U $$POSTGRES_USER

backup: ## Dump rapide vers ./backup-$(shell date +%Y%m%d-%H%M%S).sql
	kubectl -n $(NAMESPACE) exec deploy/postgres -- pg_dumpall -U $$POSTGRES_USER > backup-$$(date +%Y%m%d-%H%M%S).sql
