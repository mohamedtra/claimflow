#!/bin/bash
# Exécuté une seule fois, à la création des données PostgreSQL de l'instance. Même structure que
# infra/docker/postgres/init.sql, mais les mots de passe viennent de l'environnement (générés au
# premier déploiement et rangés dans SSM par deployer.sh).
set -euo pipefail

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" \
  -v mdp_claimflow="$CLAIMFLOW_PASSWORD" \
  -v mdp_app="$CLAIMFLOW_APP_PASSWORD" \
  -v mdp_keycloak="$KEYCLOAK_DB_PASSWORD" <<'SQL'
-- Propriétaire du schéma : utilisé par Flyway uniquement.
CREATE ROLE claimflow LOGIN PASSWORD :'mdp_claimflow';
-- Compte de l'application : aucun droit de structure, pas de modification de l'audit (ADR-010).
CREATE ROLE claimflow_app LOGIN PASSWORD :'mdp_app';

CREATE DATABASE claimflow OWNER claimflow;
REVOKE ALL ON DATABASE claimflow FROM PUBLIC;
GRANT CONNECT ON DATABASE claimflow TO claimflow_app;

CREATE ROLE keycloak LOGIN PASSWORD :'mdp_keycloak';
CREATE DATABASE keycloak OWNER keycloak;
SQL
