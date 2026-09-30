package fr.claimflow.shared;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Objects;

/**
 * Montant en euros, exact au centime (ADR-012).
 *
 * <p>Toujours positif ou nul et toujours à deux décimales. Les calculs intermédiaires restent exacts ;
 * le seul arrondi, au centime le plus proche (moitié vers le haut), a lieu quand un taux est appliqué.
 * Aucun {@code double} n'intervient, ni ici ni ailleurs dans le domaine : une règle ArchUnit le vérifie.
 */
public record Montant(BigDecimal valeur) implements Comparable<Montant> {

    public static final Montant ZERO = new Montant(BigDecimal.ZERO);

    private static final BigDecimal CENT = BigDecimal.valueOf(100);

    public Montant {
        Objects.requireNonNull(valeur, "valeur");
        if (valeur.scale() > 2 && valeur.stripTrailingZeros().scale() > 2) {
            throw new IllegalArgumentException("Un montant a au plus deux décimales : " + valeur.toPlainString());
        }
        if (valeur.signum() < 0) {
            throw new IllegalArgumentException("Un montant ne peut pas être négatif : " + valeur.toPlainString());
        }
        valeur = valeur.setScale(2, RoundingMode.UNNECESSARY);
    }

    /** Crée un montant à partir de sa forme texte, celle de l'API : {@code "3876.00"}. */
    public static Montant de(String texte) {
        return new Montant(new BigDecimal(texte));
    }

    public Montant plus(Montant autre) {
        return new Montant(valeur.add(autre.valeur));
    }

    /** Soustraction stricte : un résultat négatif signale une erreur de calcul. */
    public Montant moins(Montant autre) {
        return new Montant(valeur.subtract(autre.valeur));
    }

    /** Soustraction bornée à zéro, pour l'application d'une franchise (RG-05 : jamais négatif). */
    public Montant moinsPlancherZero(Montant autre) {
        return new Montant(valeur.subtract(autre.valeur).max(BigDecimal.ZERO));
    }

    /** Applique un taux entier, en pourcentage, par exemple un taux de vétusté. */
    public Montant pourcentage(int taux) {
        if (taux < 0 || taux > 100) {
            throw new IllegalArgumentException("Un taux est compris entre 0 et 100 : " + taux);
        }
        return new Montant(valeur.multiply(BigDecimal.valueOf(taux)).divide(CENT, 2, RoundingMode.HALF_UP));
    }

    public Montant min(Montant autre) {
        return compareTo(autre) <= 0 ? this : autre;
    }

    public boolean estSuperieurA(Montant autre) {
        return compareTo(autre) > 0;
    }

    @Override
    public int compareTo(Montant autre) {
        return valeur.compareTo(autre.valeur);
    }

    /** Forme texte de l'API : deux décimales, point décimal, sans séparateur de milliers. */
    @Override
    public String toString() {
        return valeur.toPlainString();
    }
}
