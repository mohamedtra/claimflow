package fr.claimflow.contrat.application;

import fr.claimflow.contrat.domain.ContratAssure;
import fr.claimflow.contrat.domain.ReferentielContrats;
import java.time.Clock;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** US-04 : les contrats qu'un assuré peut consulter aujourd'hui. */
@Service
public class ConsultationContrats {

    private final ReferentielContrats referentiel;
    private final Clock horloge;

    public ConsultationContrats(ReferentielContrats referentiel, Clock horloge) {
        this.referentiel = referentiel;
        this.horloge = horloge;
    }

    @Transactional(readOnly = true)
    public List<ContratAssure> contratsConsultablesPar(UUID utilisateurId) {
        var aujourdHui = LocalDate.now(horloge);
        return referentiel.contratsDe(utilisateurId).stream()
            .filter(contrat -> contrat.estConsultableLe(aujourdHui))
            .toList();
    }
}
