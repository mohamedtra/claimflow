-- Métadonnées des pièces ; le contenu est dans le stockage objet (ADR-008).
CREATE TABLE document.piece (
    id              uuid         PRIMARY KEY,
    sinistre_id     uuid         NOT NULL,                  -- référence inter-module, sans FK
    nom             varchar(255) NOT NULL,
    categorie       varchar(30)  NOT NULL CHECK (categorie IN (
                        'PHOTO', 'DEVIS', 'FACTURE', 'CONSTAT', 'RAPPORT_EXPERTISE', 'AUTRE')),
    type_detecte    varchar(100) NOT NULL,                  -- détecté sur le contenu (RG-12)
    taille          bigint       NOT NULL CHECK (taille > 0),
    sha256          char(64)     NOT NULL,
    cle_stockage    varchar(300) NOT NULL UNIQUE,
    statut_analyse  varchar(20)  NOT NULL CHECK (statut_analyse IN ('EN_ANALYSE', 'SAINE', 'REJETEE')),
    deposee_par_id  uuid         NOT NULL,
    deposee_par_role varchar(20) NOT NULL,
    deposee_le      timestamptz  NOT NULL
);
CREATE INDEX ix_piece_sinistre ON document.piece (sinistre_id, deposee_le);
