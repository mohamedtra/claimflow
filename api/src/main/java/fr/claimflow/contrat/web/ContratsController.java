package fr.claimflow.contrat.web;

import fr.claimflow.contrat.application.ConsultationContrats;
import fr.claimflow.contrat.domain.ContratAssure;
import fr.claimflow.contrat.domain.GarantieSouscrite;
import fr.claimflow.openapi.api.ContratsApi;
import fr.claimflow.openapi.model.Contrat;
import fr.claimflow.openapi.model.Garantie;
import fr.claimflow.shared.securite.UtilisateurConnecte;
import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.RestController;

/**
 * GET /api/v1/contrats (contrat d'API, ADR-005). Réservé aux assurés (US-03) ; l'assuré est celui du
 * jeton, jamais un paramètre de la requête. Traduit le domaine vers les classes générées.
 */
@RestController
class ContratsController implements ContratsApi {

    private final ConsultationContrats consultation;

    ContratsController(ConsultationContrats consultation) {
        this.consultation = consultation;
    }

    @Override
    @PreAuthorize("hasRole('ASSURE')")
    public ResponseEntity<List<Contrat>> listerMesContrats() {
        var contrats = consultation.contratsConsultablesPar(UtilisateurConnecte.courant().id());
        return ResponseEntity.ok(contrats.stream().map(ContratsController::contratApi).toList());
    }

    private static Contrat contratApi(ContratAssure contrat) {
        return new Contrat()
            .id(contrat.id())
            .numero(contrat.numero())
            .type(Contrat.TypeEnum.valueOf(contrat.type().name()))
            .libelle(contrat.libelle())
            .debut(contrat.debut())
            .fin(contrat.fin())
            .garanties(contrat.garanties().stream().map(ContratsController::garantieApi).toList());
    }

    private static Garantie garantieApi(GarantieSouscrite garantie) {
        return new Garantie()
            // Même nom que l'enum du domaine : le type généré est écrit en entier.
            .type(fr.claimflow.openapi.model.TypeGarantie.valueOf(garantie.type().name()))
            .plafond(garantie.plafond().toString())      // "8000.00" (ADR-012)
            .franchise(garantie.franchise().toString())
            .tauxVetuste(garantie.tauxVetuste());
    }
}
