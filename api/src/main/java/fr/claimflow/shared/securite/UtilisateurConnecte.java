package fr.claimflow.shared.securite;

import java.util.Arrays;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;

/**
 * Utilisateur à l'origine de la requête, tel que l'a authentifié son jeton. L'identifiant est le
 * « sub » Keycloak : pour un assuré, c'est assure.utilisateur_id (hypothèse H1 du sprint 1).
 */
public record UtilisateurConnecte(UUID id, Set<Role> roles) {

    public UtilisateurConnecte {
        Objects.requireNonNull(id, "id");
        roles = Set.copyOf(roles);
    }

    public boolean a(Role role) {
        return roles.contains(role);
    }

    /** Utilisateur de la requête en cours. Échoue si la requête n'est pas authentifiée par jeton. */
    public static UtilisateurConnecte courant() {
        if (SecurityContextHolder.getContext().getAuthentication() instanceof JwtAuthenticationToken jeton) {
            return depuis(jeton);
        }
        throw new IllegalStateException("Aucun utilisateur authentifié par jeton dans cette requête");
    }

    static UtilisateurConnecte depuis(JwtAuthenticationToken jeton) {
        Set<Role> roles = jeton.getAuthorities().stream()
            .map(GrantedAuthority::getAuthority)
            .flatMap(autorite -> Arrays.stream(Role.values()).filter(r -> r.autorite().equals(autorite)))
            .collect(Collectors.toUnmodifiableSet());
        return new UtilisateurConnecte(UUID.fromString(Objects.requireNonNull(jeton.getToken().getSubject())), roles);
    }
}
