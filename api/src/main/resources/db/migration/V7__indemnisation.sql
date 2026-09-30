CREATE TABLE indemnisation.proposition (
    id                 uuid          PRIMARY KEY,
    sinistre_id        uuid          NOT NULL,              -- référence inter-module, sans FK
    statut             varchar(20)   NOT NULL CHECK (statut IN (
                           'BROUILLON', 'EN_VALIDATION', 'REJETEE', 'OFFRE_ENVOYEE', 'ACCEPTEE', 'CONTESTEE')),
    dommage_retenu     numeric(12,2) NOT NULL CHECK (dommage_retenu >= 0),
    vetuste            numeric(12,2) NOT NULL CHECK (vetuste >= 0),
    plafond            numeric(12,2) NOT NULL CHECK (plafond > 0),
    franchise          numeric(12,2) NOT NULL CHECK (franchise >= 0),
    montant            numeric(12,2) NOT NULL CHECK (montant >= 0),       -- RG-05 : jamais négatif
    propose_par        uuid          NOT NULL,
    valide_par         uuid,
    message_assure     varchar(2000),
    offre_envoyee_le   timestamptz,
    motif_contestation varchar(2000),
    cree_le            timestamptz   NOT NULL,
    version            bigint        NOT NULL DEFAULT 0,
    CONSTRAINT ck_proposition_quatre_yeux CHECK (valide_par IS NULL OR valide_par <> propose_par),  -- RG-06
    CONSTRAINT ck_proposition_contestation CHECK ((statut = 'CONTESTEE') = (motif_contestation IS NOT NULL)) -- RG-14
);
CREATE INDEX ix_proposition_sinistre ON indemnisation.proposition (sinistre_id, cree_le DESC);
-- Validations en attente du responsable (US-18).
CREATE INDEX ix_proposition_a_valider ON indemnisation.proposition (cree_le) WHERE statut = 'EN_VALIDATION';
-- Relance de l'assuré sans réponse (RG-14).
CREATE INDEX ix_proposition_offres ON indemnisation.proposition (offre_envoyee_le) WHERE statut = 'OFFRE_ENVOYEE';

CREATE TABLE indemnisation.ligne_calcul (
    id             uuid          PRIMARY KEY,
    proposition_id uuid          NOT NULL REFERENCES indemnisation.proposition (id) ON DELETE CASCADE,
    ordre          smallint      NOT NULL,
    poste          varchar(200)  NOT NULL,
    source         varchar(100)  NOT NULL,
    montant        numeric(12,2) NOT NULL,
    CONSTRAINT uq_ligne_calcul_ordre UNIQUE (proposition_id, ordre)
);

-- Ordres de virement émis vers le système de paiement (US-20).
CREATE TABLE indemnisation.ordre_virement (
    id             varchar(64)   PRIMARY KEY,
    proposition_id uuid          NOT NULL UNIQUE REFERENCES indemnisation.proposition (id),
    montant        numeric(12,2) NOT NULL CHECK (montant > 0),
    statut         varchar(20)   NOT NULL CHECK (statut IN ('EMIS', 'EXECUTE', 'REJETE')),
    emis_le        timestamptz   NOT NULL,
    execute_le     timestamptz,
    motif_rejet    varchar(500)
);
