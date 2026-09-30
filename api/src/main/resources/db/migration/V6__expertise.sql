CREATE TABLE expertise.mission (
    id          uuid        PRIMARY KEY,
    sinistre_id uuid        NOT NULL,                       -- référence inter-module, sans FK
    expert_id   uuid        NOT NULL,
    statut      varchar(20) NOT NULL CHECK (statut IN ('NOUVELLE', 'PLANIFIEE', 'RAPPORT_ATTENDU', 'DEPOSEE')),
    rendez_vous timestamptz,
    constats    text,
    depose_le   timestamptz,
    cree_le     timestamptz NOT NULL,
    version     bigint      NOT NULL DEFAULT 0,
    CONSTRAINT ck_mission_depot CHECK ((statut = 'DEPOSEE') = (depose_le IS NOT NULL))
);
-- « Mes missions » de l'expert (US-15).
CREATE INDEX ix_mission_expert ON expertise.mission (expert_id, statut, cree_le DESC);
CREATE INDEX ix_mission_sinistre ON expertise.mission (sinistre_id);

CREATE TABLE expertise.ligne_chiffrage (
    id            uuid          PRIMARY KEY,
    mission_id    uuid          NOT NULL REFERENCES expertise.mission (id) ON DELETE CASCADE,
    ordre         smallint      NOT NULL,
    poste         varchar(200)  NOT NULL,
    quantite      numeric(8,2)  NOT NULL CHECK (quantite > 0),
    unite         varchar(20),
    prix_unitaire numeric(12,2) NOT NULL CHECK (prix_unitaire >= 0),
    taux_vetuste  smallint      NOT NULL CHECK (taux_vetuste BETWEEN 0 AND 100),
    CONSTRAINT uq_ligne_chiffrage_ordre UNIQUE (mission_id, ordre)
);
