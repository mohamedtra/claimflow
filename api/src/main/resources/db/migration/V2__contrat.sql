-- Référentiel en lecture seule, alimenté par l'import quotidien du SI de souscription (EN-07).

CREATE TABLE contrat.assure (
    id            uuid         PRIMARY KEY,
    utilisateur_id uuid        UNIQUE,              -- identifiant Keycloak, renseigné à l'activation
    nom           varchar(120) NOT NULL,
    email         varchar(254) NOT NULL UNIQUE,
    iban_masque   varchar(34),                      -- ex. FR76 •••• •••• •••• 4821
    importe_le    timestamptz  NOT NULL DEFAULT now()
);

CREATE TABLE contrat.contrat (
    id         uuid        PRIMARY KEY,
    numero     varchar(20) NOT NULL UNIQUE,
    assure_id  uuid        NOT NULL REFERENCES contrat.assure (id),
    type       varchar(20) NOT NULL CHECK (type IN ('HABITATION', 'AUTO')),
    libelle    varchar(120) NOT NULL,
    debut      date        NOT NULL,
    fin        date,
    importe_le timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_contrat_periode CHECK (fin IS NULL OR fin >= debut)
);
CREATE INDEX ix_contrat_assure ON contrat.contrat (assure_id);

CREATE TABLE contrat.garantie (
    id           uuid          PRIMARY KEY,
    contrat_id   uuid          NOT NULL REFERENCES contrat.contrat (id) ON DELETE CASCADE,
    type         varchar(30)   NOT NULL,
    plafond      numeric(12,2) NOT NULL CHECK (plafond > 0),
    franchise    numeric(12,2) NOT NULL CHECK (franchise >= 0),
    taux_vetuste smallint      NOT NULL CHECK (taux_vetuste BETWEEN 0 AND 100),
    CONSTRAINT uq_garantie_contrat_type UNIQUE (contrat_id, type),
    CONSTRAINT ck_garantie_type CHECK (type IN (
        'DEGAT_DES_EAUX', 'INCENDIE', 'VOL', 'BRIS_DE_GLACE', 'TEMPETE', 'AUTO_COLLISION', 'AUTO_VANDALISME'))
);
