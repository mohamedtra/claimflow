package fr.claimflow.sinistre.domain;

import java.io.Serial;

/**
 * Tentative de transition absente de la machine à états. L'API la traduit en réponse 422.
 */
public class TransitionInterdite extends RuntimeException {

    @Serial
    private static final long serialVersionUID = 1L;

    private final Statut depuis;
    private final Statut vers;

    public TransitionInterdite(Statut depuis, Statut vers) {
        super("Transition interdite : " + depuis + " vers " + vers);
        this.depuis = depuis;
        this.vers = vers;
    }

    public Statut depuis() {
        return depuis;
    }

    public Statut vers() {
        return vers;
    }
}
