package fr.claimflow.contrat.application;

import static org.assertj.core.api.Assertions.assertThat;

import fr.claimflow.contrat.domain.ContratAssure;
import fr.claimflow.contrat.domain.ReferentielContrats;
import fr.claimflow.contrat.domain.TypeContrat;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/**
 * US-04 : seuls les contrats consultables à la date du jour sont rendus. Sans base de données ni
 * Spring : un faux référentiel (le port) et une horloge figée suffisent.
 */
class ConsultationContratsTest {

    // 12/10/2026 à 23 h 30 UTC : il est déjà le 13/10 à Paris.
    private static final Clock HORLOGE =
        Clock.fixed(Instant.parse("2026-10-12T23:30:00Z"), ZoneId.of("Europe/Paris"));

    @Test
    void us04_filtre_les_contrats_selon_la_date_de_paris() {
        var actif = contrat("HAB-1", null);
        var limite = contrat("AUTO-2", LocalDate.of(2024, 10, 13));      // échu il y a exactement deux ans, à Paris
        var tropAncien = contrat("AUTO-3", LocalDate.of(2024, 10, 12));
        ReferentielContrats faux = utilisateur -> List.of(actif, limite, tropAncien);

        var resultat = new ConsultationContrats(faux, HORLOGE).contratsConsultablesPar(UUID.randomUUID());

        assertThat(resultat).containsExactly(actif, limite);
    }

    private static ContratAssure contrat(String numero, LocalDate fin) {
        return new ContratAssure(UUID.randomUUID(), numero, TypeContrat.AUTO, "Contrat de test",
            LocalDate.of(2020, 1, 1), fin, List.of());
    }
}
