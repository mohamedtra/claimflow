-- Cœur du domaine : le dossier de sinistre et sa machine à états (ADR-004).

CREATE SEQUENCE sinistre.numero_seq START WITH 1 INCREMENT BY 1;  -- partie NNNNNN de SIN-AAAA-NNNNNN

CREATE TABLE sinistre.sinistre (
    id                  uuid          PRIMARY KEY,          -- UUID v7 généré par l'application (ADR-011)
    numero              varchar(16)   NOT NULL UNIQUE,      -- SIN-2026-048213
    contrat_id          uuid          NOT NULL,             -- référence inter-module, sans FK (ADR-001)
    assure_id           uuid          NOT NULL,
    assure_nom          varchar(120)  NOT NULL,             -- dénormalisé pour la recherche
    garantie            varchar(30)   NOT NULL,
    date_survenance     date          NOT NULL,
    date_connaissance   date          NOT NULL,
    declare_le          timestamptz   NOT NULL,
    circonstances       text          NOT NULL CHECK (char_length(circonstances) BETWEEN 20 AND 4000),
    lieu_ligne          varchar(200)  NOT NULL,
    lieu_code_postal    char(5)       NOT NULL,
    lieu_commune        varchar(100)  NOT NULL,
    tiers               varchar(500),
    montant_estime      numeric(12,2) CHECK (montant_estime >= 0),
    statut              varchar(30)   NOT NULL,
    gestionnaire_id     uuid,
    echeance_decision   date,
    declaration_tardive boolean       NOT NULL DEFAULT false,  -- RG-01
    revue_fraude        boolean       NOT NULL DEFAULT false,  -- RG-09
    cloture_le          date,
    version             bigint        NOT NULL DEFAULT 0,      -- RG-13
    CONSTRAINT ck_sinistre_dates CHECK (date_connaissance >= date_survenance),
    CONSTRAINT ck_sinistre_statut CHECK (statut IN (
        'DECLARE', 'EN_INSTRUCTION', 'EN_ATTENTE_PIECES', 'EN_EXPERTISE', 'PROPOSITION',
        'EN_VALIDATION', 'OFFRE_ENVOYEE', 'ACCEPTEE', 'INDEMNISE', 'REFUSE', 'CLASSE_SANS_SUITE',
        'CLOS')),
    CONSTRAINT ck_sinistre_cloture CHECK ((statut = 'CLOS') = (cloture_le IS NOT NULL))
);

-- Corbeille du gestionnaire : ses dossiers ouverts, triés par échéance (US-07).
CREATE INDEX ix_sinistre_corbeille ON sinistre.sinistre (gestionnaire_id, echeance_decision)
    WHERE statut NOT IN ('INDEMNISE', 'REFUSE', 'CLASSE_SANS_SUITE', 'CLOS');

-- Tâche planifiée des échéances (RG-08) : uniquement les dossiers ouverts.
CREATE INDEX ix_sinistre_echeances ON sinistre.sinistre (echeance_decision)
    WHERE statut NOT IN ('INDEMNISE', 'REFUSE', 'CLASSE_SANS_SUITE', 'CLOS');

-- Espace assuré et pagination par curseur (ADR-007).
CREATE INDEX ix_sinistre_assure ON sinistre.sinistre (assure_id, declare_le DESC, id DESC);

-- Barre de recherche : numéro ou nom partiel (US-08).
CREATE INDEX ix_sinistre_numero_trgm ON sinistre.sinistre USING gin (numero gin_trgm_ops);
CREATE INDEX ix_sinistre_nom_trgm    ON sinistre.sinistre USING gin (assure_nom gin_trgm_ops);

-- Signal fraude RG-09 : sinistres d'un contrat sur 12 mois.
CREATE INDEX ix_sinistre_contrat ON sinistre.sinistre (contrat_id, date_survenance);

-- Pièces demandées à l'assuré (US-10).
CREATE TABLE sinistre.demande_piece (
    id          uuid         PRIMARY KEY,
    sinistre_id uuid         NOT NULL REFERENCES sinistre.sinistre (id),
    libelle     varchar(200) NOT NULL,
    demandee_le timestamptz  NOT NULL,
    recue_le    timestamptz
);
CREATE INDEX ix_demande_piece_sinistre ON sinistre.demande_piece (sinistre_id);

-- Idempotence de la déclaration (en-tête Idempotency-Key, conservé 24 h).
CREATE TABLE sinistre.cle_idempotence (
    cle          varchar(64) PRIMARY KEY,
    demandeur_id uuid        NOT NULL,
    sinistre_id  uuid        NOT NULL REFERENCES sinistre.sinistre (id),
    cree_le      timestamptz NOT NULL DEFAULT now()
);
