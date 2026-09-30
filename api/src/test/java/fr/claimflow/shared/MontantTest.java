package fr.claimflow.shared;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class MontantTest {

    @Test
    void se_lit_et_s_ecrit_au_format_de_l_api() {
        assertThat(Montant.de("3876.00")).hasToString("3876.00");
        assertThat(Montant.de("12")).hasToString("12.00");
        assertThat(Montant.de("12.5")).isEqualTo(Montant.de("12.50"));
    }

    @Test
    void refuse_plus_de_deux_decimales_et_les_valeurs_negatives() {
        assertThatThrownBy(() -> Montant.de("10.005")).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> Montant.de("-1.00")).isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void additionne_sans_erreur_d_arrondi() {
        assertThat(Montant.de("0.10").plus(Montant.de("0.20"))).isEqualTo(Montant.de("0.30"));
    }

    @Test
    void applique_un_taux_avec_un_arrondi_unique_au_centime() {
        assertThat(Montant.de("2640.00").pourcentage(15)).isEqualTo(Montant.de("396.00"));
        assertThat(Montant.de("10.05").pourcentage(15)).isEqualTo(Montant.de("1.51")); // 1,5075
        assertThatThrownBy(() -> Montant.de("10.00").pourcentage(101)).isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void la_soustraction_stricte_refuse_un_resultat_negatif() {
        assertThatThrownBy(() -> Montant.de("200.00").moins(Montant.de("300.00")))
                .isInstanceOf(IllegalArgumentException.class);
        assertThat(Montant.de("200.00").moinsPlancherZero(Montant.de("300.00"))).isEqualTo(Montant.ZERO);
    }

    @Test
    @DisplayName("RG-05 : min(dommage retenu − vétusté ; plafond) − franchise, sur l'exemple de la maquette")
    void rg05_calcule_l_indemnite_du_dossier_de_la_maquette() {
        var dommageRetenu = Montant.de("2640.00").plus(Montant.de("1180.00"))
                .plus(Montant.de("480.00")).plus(Montant.de("320.00"));
        var vetuste = Montant.de("2640.00").pourcentage(15).plus(Montant.de("320.00").pourcentage(15));
        var plafond = Montant.de("8000.00");
        var franchise = Montant.de("300.00");

        var indemnite = dommageRetenu.moins(vetuste).min(plafond).moinsPlancherZero(franchise);

        assertThat(dommageRetenu).isEqualTo(Montant.de("4620.00"));
        assertThat(vetuste).isEqualTo(Montant.de("444.00"));
        assertThat(indemnite).isEqualTo(Montant.de("3876.00"));
    }

    @Test
    @DisplayName("RG-05 : l'indemnité n'est jamais négative quand la franchise dépasse le dommage")
    void rg05_indemnite_jamais_negative() {
        var indemnite = Montant.de("180.00").min(Montant.de("8000.00")).moinsPlancherZero(Montant.de("300.00"));
        assertThat(indemnite).isEqualTo(Montant.ZERO);
    }

    @Test
    @DisplayName("RG-06 : au-delà du seuil de 10 000 €, la double validation s'impose")
    void rg06_compare_au_seuil() {
        var seuil = Montant.de("10000.00");
        assertThat(Montant.de("18450.00").estSuperieurA(seuil)).isTrue();
        assertThat(Montant.de("10000.00").estSuperieurA(seuil)).isFalse();
    }
}
