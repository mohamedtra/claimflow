package fr.claimflow.contrat.domain;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** US-04 : l'assuré consulte ses contrats actifs et ceux échus depuis moins de deux ans. */
class ContratAssureTest {

    private static final LocalDate AUJOURD_HUI = LocalDate.of(2026, 10, 12);

    @Test
    void us04_un_contrat_sans_fin_est_consultable() {
        assertThat(contratFini(null).estConsultableLe(AUJOURD_HUI)).isTrue();
    }

    @Test
    void us04_un_contrat_echu_depuis_un_an_est_consultable() {
        assertThat(contratFini(AUJOURD_HUI.minusYears(1)).estConsultableLe(AUJOURD_HUI)).isTrue();
    }

    @Test
    void us04_un_contrat_echu_depuis_exactement_deux_ans_est_encore_consultable() {
        assertThat(contratFini(AUJOURD_HUI.minusYears(2)).estConsultableLe(AUJOURD_HUI)).isTrue();
    }

    @Test
    void us04_un_contrat_echu_depuis_plus_de_deux_ans_ne_l_est_plus() {
        assertThat(contratFini(AUJOURD_HUI.minusYears(2).minusDays(1)).estConsultableLe(AUJOURD_HUI)).isFalse();
    }

    private static ContratAssure contratFini(LocalDate fin) {
        return new ContratAssure(UUID.randomUUID(), "HAB-0000001", TypeContrat.HABITATION,
            "Multirisque habitation", LocalDate.of(2020, 1, 1), fin, List.of());
    }
}
