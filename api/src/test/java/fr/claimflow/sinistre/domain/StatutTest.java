package fr.claimflow.sinistre.domain;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.ArrayDeque;
import java.util.Arrays;
import java.util.EnumSet;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

class StatutTest {

    @ParameterizedTest(name = "{0} vers {1} est autorisée")
    @CsvSource({
        "DECLARE,           EN_INSTRUCTION",
        "DECLARE,           REFUSE",
        "EN_INSTRUCTION,    EN_ATTENTE_PIECES",
        "EN_ATTENTE_PIECES, CLASSE_SANS_SUITE",
        "PROPOSITION,       OFFRE_ENVOYEE",     // sous le seuil de double validation
        "PROPOSITION,       EN_VALIDATION",     // au-delà du seuil (RG-06)
        "EN_VALIDATION,     PROPOSITION",       // rejet par le responsable
        "OFFRE_ENVOYEE,     ACCEPTEE",          // acceptation par l'assuré (RG-14)
        "OFFRE_ENVOYEE,     EN_INSTRUCTION",    // contestation par l'assuré (RG-14)
        "CLOS,              EN_INSTRUCTION"     // réouverture (RG-10)
    })
    void autorise_les_transitions_prevues(Statut depuis, Statut vers) {
        assertThat(depuis.peutPasserA(vers)).isTrue();
    }

    @ParameterizedTest(name = "{0} vers {1} est refusée")
    @CsvSource({
        "DECLARE,       PROPOSITION",   // pas de proposition sans instruction
        "PROPOSITION,   ACCEPTEE",      // l'assuré doit d'abord accepter l'offre (RG-14)
        "EN_VALIDATION, ACCEPTEE",      // la validation envoie l'offre, elle ne l'accepte pas
        "EN_EXPERTISE,  ACCEPTEE",      // pas d'acceptation pendant l'expertise
        "CLOS,          INDEMNISE",     // un dossier clos se rouvre, il ne se paie pas
        "INDEMNISE,     EN_INSTRUCTION" // il faut d'abord le clore
    })
    void refuse_les_transitions_non_prevues(Statut depuis, Statut vers) {
        assertThat(depuis.peutPasserA(vers)).isFalse();
    }

    @Test
    @DisplayName("La machine à états compte 12 statuts et 19 transitions (section 2.6)")
    void compte_les_transitions() {
        assertThat(Statut.values()).hasSize(12);
        assertThat(Arrays.stream(Statut.values()).mapToInt(s -> s.suivants().size()).sum()).isEqualTo(19);
    }

    @Test
    void tous_les_statuts_sont_atteignables_depuis_la_declaration() {
        var atteints = EnumSet.of(Statut.DECLARE);
        var aVisiter = new ArrayDeque<Statut>(atteints);
        while (!aVisiter.isEmpty()) {
            for (var suivant : aVisiter.poll().suivants()) {
                if (atteints.add(suivant)) {
                    aVisiter.add(suivant);
                }
            }
        }
        assertThat(atteints).containsExactlyInAnyOrder(Statut.values());
    }

    @Test
    void seuls_les_statuts_finaux_ferment_le_dossier() {
        assertThat(EnumSet.allOf(Statut.class).stream().filter(s -> !s.estOuvert()))
                .containsExactlyInAnyOrder(Statut.INDEMNISE, Statut.REFUSE, Statut.CLASSE_SANS_SUITE, Statut.CLOS);
    }
}
