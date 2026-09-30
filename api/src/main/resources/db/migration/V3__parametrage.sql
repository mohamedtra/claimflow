-- Paramètres des règles de gestion : une seule ligne, typée, versionnée (US-27).
CREATE TABLE parametrage.parametres (
    id                                  smallint      PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    seuil_expertise                     numeric(12,2) NOT NULL CHECK (seuil_expertise > 0),          -- RG-04
    seuil_double_validation             numeric(12,2) NOT NULL CHECK (seuil_double_validation > 0),  -- RG-06
    delai_declaration_jours_ouvres      smallint      NOT NULL CHECK (delai_declaration_jours_ouvres > 0),     -- RG-01
    delai_declaration_vol_jours_ouvres  smallint      NOT NULL CHECK (delai_declaration_vol_jours_ouvres > 0), -- RG-01
    delai_reouverture_ans               smallint      NOT NULL CHECK (delai_reouverture_ans > 0),      -- RG-10
    delai_accuse_reception_heures       smallint      NOT NULL CHECK (delai_accuse_reception_heures > 0), -- RG-08
    delai_decision_jours                smallint      NOT NULL CHECK (delai_decision_jours > 0),       -- RG-08
    alerte_avant_echeance_jours         smallint      NOT NULL CHECK (alerte_avant_echeance_jours > 0),  -- RG-08
    delai_classement_sans_suite_jours   smallint      NOT NULL CHECK (delai_classement_sans_suite_jours > 0),
    delai_relance_offre_jours           smallint      NOT NULL CHECK (delai_relance_offre_jours > 0),  -- RG-14
    fraude_sinistres_sur_12_mois        smallint      NOT NULL CHECK (fraude_sinistres_sur_12_mois > 0),     -- RG-09
    fraude_delai_apres_souscription_jours smallint    NOT NULL CHECK (fraude_delai_apres_souscription_jours > 0), -- RG-09
    pieces_taille_max_mo                smallint      NOT NULL CHECK (pieces_taille_max_mo BETWEEN 1 AND 50),    -- RG-12
    pieces_types_acceptes               varchar(50)[] NOT NULL,
    version                             bigint        NOT NULL DEFAULT 0,
    modifie_le                          timestamptz   NOT NULL DEFAULT now()
);

-- Valeurs validées au cadrage (29/09/2026), identiques dans tous les environnements.
INSERT INTO parametrage.parametres (
    seuil_expertise, seuil_double_validation,
    delai_declaration_jours_ouvres, delai_declaration_vol_jours_ouvres, delai_reouverture_ans,
    delai_accuse_reception_heures, delai_decision_jours, alerte_avant_echeance_jours,
    delai_classement_sans_suite_jours, delai_relance_offre_jours,
    fraude_sinistres_sur_12_mois, fraude_delai_apres_souscription_jours,
    pieces_taille_max_mo, pieces_types_acceptes)
VALUES (1500.00, 10000.00, 5, 2, 2, 48, 30, 5, 60, 15, 3, 30, 10,
        ARRAY['application/pdf', 'image/jpeg', 'image/png']);

-- Équipes et gestionnaires, pour l'affectation automatique (RG-07).
CREATE TABLE parametrage.equipe (
    id         uuid        PRIMARY KEY,
    nom        varchar(80) NOT NULL UNIQUE,
    specialite varchar(20) NOT NULL CHECK (specialite IN ('HABITATION', 'AUTO'))
);

CREATE TABLE parametrage.collaborateur (
    id        uuid         PRIMARY KEY,                 -- identifiant Keycloak (sub)
    nom       varchar(120) NOT NULL,
    role      varchar(20)  NOT NULL CHECK (role IN ('GESTIONNAIRE', 'RESPONSABLE', 'EXPERT', 'ADMIN')),
    equipe_id uuid         REFERENCES parametrage.equipe (id),
    actif     boolean      NOT NULL DEFAULT true,
    CONSTRAINT ck_collaborateur_equipe CHECK (role IN ('EXPERT', 'ADMIN') OR equipe_id IS NOT NULL)
);
