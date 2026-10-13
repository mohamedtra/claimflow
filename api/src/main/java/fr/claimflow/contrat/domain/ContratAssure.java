package fr.claimflow.contrat.domain;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** Contrat d'un assuré, tel qu'il le consulte dans son espace (US-04). */
public record ContratAssure(UUID id, String numero, TypeContrat type, String libelle,
                            LocalDate debut, LocalDate fin, List<GarantieSouscrite> garanties) {

    /** Un contrat échu reste consultable pendant deux ans (contrat d'API, listerMesContrats). */
    private static final int ANNEES_DE_CONSULTATION_APRES_ECHEANCE = 2;

    public ContratAssure {
        garanties = List.copyOf(garanties);
    }

    /** Actif, ou échu depuis deux ans au plus, borne comprise. */
    public boolean estConsultableLe(LocalDate jour) {
        return fin == null || !fin.isBefore(jour.minusYears(ANNEES_DE_CONSULTATION_APRES_ECHEANCE));
    }
}
