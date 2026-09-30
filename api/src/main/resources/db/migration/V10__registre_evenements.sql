-- Registre de publication des événements de Spring Modulith 2.x (ADR-009) : il joue le rôle
-- d'outbox. Schéma repris de la documentation de Spring Modulith (dialecte PostgreSQL) ; la
-- création automatique est désactivée (spring.modulith.events.jdbc.schema-initialization.enabled
-- à false) pour que seules les migrations modifient la structure.
CREATE TABLE IF NOT EXISTS public.event_publication
(
  id                     UUID NOT NULL,
  listener_id            TEXT NOT NULL,
  event_type             TEXT NOT NULL,
  serialized_event       TEXT NOT NULL,
  publication_date       TIMESTAMP WITH TIME ZONE NOT NULL,
  completion_date        TIMESTAMP WITH TIME ZONE,
  status                 TEXT,
  completion_attempts    INT,
  last_resubmission_date TIMESTAMP WITH TIME ZONE,
  PRIMARY KEY (id)
);
CREATE INDEX IF NOT EXISTS event_publication_serialized_event_hash_idx
    ON public.event_publication USING hash (serialized_event);
CREATE INDEX IF NOT EXISTS event_publication_by_completion_date_idx
    ON public.event_publication (completion_date);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.event_publication TO claimflow_app;
