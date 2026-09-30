COMPOSE := docker compose -f infra/docker/docker-compose.yml

.PHONY: help up up-app down reset api web test test-api test-web lint

help: ## Affiche cette aide
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-10s %s\n", $$1, $$2}'

up: ## Démarre l'infrastructure locale (PostgreSQL, Keycloak, stockage, Mailpit, ClamAV)
	$(COMPOSE) up -d

up-app: ## Démarre toute la pile en conteneurs, API et SPA comprises
	$(COMPOSE) --profile app up -d --build

down: ## Arrête les conteneurs (les données sont conservées)
	$(COMPOSE) --profile app down

reset: ## Arrête tout et supprime les données locales
	$(COMPOSE) --profile app down -v

api: ## Lance l'API avec le profil local et le jeu de démonstration
	mvn -f api/pom.xml spring-boot:run -Dspring-boot.run.profiles=local

web: ## Lance la SPA en mode développement
	npm --prefix web run dev

test: test-api test-web ## Lance tous les tests

test-api: ## Tests unitaires, d'architecture et d'intégration (Docker requis)
	mvn -B -f api/pom.xml verify

test-web: ## Lint, contrôle de types et tests de la SPA
	npm --prefix web run lint && npm --prefix web run type-check && npm --prefix web test

lint: ## Contrat d'API et messages de commit
	npm run lint:api
