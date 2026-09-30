-- Le compte applicatif (claimflow_app) n'est pas propriétaire des tables : il ne peut ni modifier
-- le schéma ni altérer le journal d'audit. Le rôle est créé par l'infrastructure
-- (infra/docker/postgres/init.sql en local, Terraform sur AWS) ; les migrations s'exécutent avec
-- le compte propriétaire.

GRANT USAGE ON SCHEMA contrat, parametrage, sinistre, document, expertise, indemnisation, audit
    TO claimflow_app;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA
    contrat, parametrage, sinistre, document, expertise, indemnisation
    TO claimflow_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA sinistre TO claimflow_app;

-- Audit : lecture et ajout seulement (ADR-010).
GRANT SELECT, INSERT ON audit.entree_audit TO claimflow_app;

-- Les tables créées par les migrations futures reçoivent les mêmes droits.
ALTER DEFAULT PRIVILEGES IN SCHEMA contrat, parametrage, sinistre, document, expertise, indemnisation
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO claimflow_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA audit GRANT SELECT, INSERT ON TABLES TO claimflow_app;

