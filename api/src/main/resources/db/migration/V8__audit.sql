-- Journal d'audit en ajout seul, entrées chaînées par hachage (RG-11, ADR-010).
CREATE TABLE audit.entree_audit (
    id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    evenement_id   uuid         NOT NULL UNIQUE,     -- idempotence : un événement, une entrée
    horodatage     timestamptz  NOT NULL DEFAULT now(),
    acteur_id      varchar(64)  NOT NULL,
    acteur_role    varchar(30)  NOT NULL,
    action         varchar(60)  NOT NULL,
    objet_type     varchar(30)  NOT NULL,
    objet_id       uuid         NOT NULL,
    avant          jsonb,                             -- identifiants et montants, jamais de nom
    apres          jsonb,
    hash_precedent char(64)     NOT NULL,
    hash           char(64)     NOT NULL UNIQUE       -- sha256(hash_precedent + contenu)
);

CREATE INDEX ix_audit_objet ON audit.entree_audit (objet_type, objet_id, horodatage);
CREATE INDEX ix_audit_acteur ON audit.entree_audit (acteur_id, horodatage);
CREATE INDEX ix_audit_temps ON audit.entree_audit USING brin (horodatage);

CREATE FUNCTION audit.refuser_modification() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'Le journal d''audit est en ajout seul (RG-11)'
        USING ERRCODE = 'insufficient_privilege';
END $$;

CREATE TRIGGER tr_audit_ajout_seul BEFORE UPDATE OR DELETE ON audit.entree_audit
    FOR EACH ROW EXECUTE FUNCTION audit.refuser_modification();

CREATE TRIGGER tr_audit_pas_de_vidage BEFORE TRUNCATE ON audit.entree_audit
    FOR EACH STATEMENT EXECUTE FUNCTION audit.refuser_modification();
