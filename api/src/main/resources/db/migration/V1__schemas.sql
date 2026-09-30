-- Un schéma par module (ADR-001). Aucune clé étrangère ne traverse deux schémas.
CREATE SCHEMA contrat;
CREATE SCHEMA parametrage;
CREATE SCHEMA sinistre;
CREATE SCHEMA document;
CREATE SCHEMA expertise;
CREATE SCHEMA indemnisation;
CREATE SCHEMA audit;

-- Recherche tolérante aux fautes sur le numéro et le nom de l'assuré (US-08).
-- pg_trgm est une extension « de confiance » : le propriétaire de la base peut l'installer.
CREATE EXTENSION IF NOT EXISTS pg_trgm;
