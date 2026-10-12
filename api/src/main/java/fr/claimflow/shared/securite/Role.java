package fr.claimflow.shared.securite;

/** Rôles du realm Keycloak « claimflow » (ADR-002). L'autorité Spring correspondante est ROLE_<nom>. */
public enum Role {

    ASSURE, GESTIONNAIRE, EXPERT, RESPONSABLE, ADMIN;

    String autorite() {
        return "ROLE_" + name();
    }
}
