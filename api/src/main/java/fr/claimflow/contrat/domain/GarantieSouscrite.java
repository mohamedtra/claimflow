// GarantieSouscrite.java
package fr.claimflow.contrat.domain;

import fr.claimflow.contrat.TypeGarantie;
import fr.claimflow.shared.Montant;

/** Garantie d'un contrat, avec ses limites. Le taux de vétusté est un pourcentage. */
public record GarantieSouscrite(TypeGarantie type, Montant plafond, Montant franchise, int tauxVetuste) {
}
