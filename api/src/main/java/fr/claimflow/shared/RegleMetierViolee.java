package fr.claimflow.shared;

import java.io.Serial;
import java.util.Objects;

/**
 * Une règle de gestion interdit l'opération demandée. L'API la traduit en réponse 422 au format
 * Problem Details, avec l'identifiant de la règle ({@code RG-06}, par exemple).
 */
public class RegleMetierViolee extends RuntimeException {

    @Serial
    private static final long serialVersionUID = 1L;

    private final String regle;

    public RegleMetierViolee(String regle, String message) {
        super(message);
        this.regle = Objects.requireNonNull(regle, "regle");
    }

    public String regle() {
        return regle;
    }
}
