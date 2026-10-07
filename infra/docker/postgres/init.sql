-- Exécuté une seule fois, à la création du volume PostgreSQL local.
-- Sur AWS (dev), le même script existe avec des mots de passe générés sur l'instance et rangés dans
-- SSM (infra/terraform/envs/dev/fichiers/init-postgres.sh). Ceux ci-dessous ne servent qu'en local.

-- Propriétaire du schéma : utilisé par Flyway uniquement.
CREATE ROLE claimflow LOGIN PASSWORD 'claimflow-dev';
-- Compte de l'application : aucun droit de structure, pas de modification de l'audit (ADR-010).
CREATE ROLE claimflow_app LOGIN PASSWORD 'claimflow-app-dev';

CREATE DATABASE claimflow OWNER claimflow;
REVOKE ALL ON DATABASE claimflow FROM PUBLIC;
GRANT CONNECT ON DATABASE claimflow TO claimflow_app;

-- Base dédiée à Keycloak.
CREATE ROLE keycloak LOGIN PASSWORD 'keycloak-dev';
CREATE DATABASE keycloak OWNER keycloak;
