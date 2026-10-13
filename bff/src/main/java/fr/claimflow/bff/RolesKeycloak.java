package fr.claimflow.bff;

import com.nimbusds.jwt.JWTParser;
import java.text.ParseException;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

/**
 * Lit les rôles du realm (realm_access.roles) dans le jeton d'accès. Le BFF ne s'en sert que pour
 * informer la SPA (menus, écrans) : l'API reste seule juge des droits (US-03).
 *
 * <p>La signature n'est pas revérifiée : le jeton vient d'être reçu de Keycloak lui-même, sur le
 * canal serveur à serveur de l'échange de code. Il n'est jamais passé par le navigateur.
 */
final class RolesKeycloak {

    private static final Logger LOG = LoggerFactory.getLogger(RolesKeycloak.class);
    private static final Set<String> CONNUS = Set.of("ASSURE", "GESTIONNAIRE", "EXPERT", "RESPONSABLE", "ADMIN");

    private RolesKeycloak() {
    }

    static List<GrantedAuthority> depuisJetonAcces(String jetonAcces) {
        try {
            var revendications = JWTParser.parse(jetonAcces).getJWTClaimsSet().getClaims();
            if (!(revendications.get("realm_access") instanceof Map<?, ?> realm)
                || !(realm.get("roles") instanceof Collection<?> roles)) {
                return List.of();
            }
            return roles.stream()
                .map(String::valueOf)
                .filter(CONNUS::contains)
                .map(role -> (GrantedAuthority) new SimpleGrantedAuthority("ROLE_" + role))
                .toList();
        } catch (ParseException e) {
            // Jamais le jeton dans les journaux.
            LOG.warn("Jeton d'accès illisible : aucun rôle retenu");
            return List.of();
        }
    }
}
