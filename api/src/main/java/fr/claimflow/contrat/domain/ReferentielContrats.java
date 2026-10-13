package fr.claimflow.contrat.domain;

import java.util.List;
import java.util.UUID;

/** Accès au référentiel des contrats importé du SI de souscription (lecture seule). */
public interface ReferentielContrats {
    List<ContratAssure> contratsDe(UUID utilisateurId);
}
