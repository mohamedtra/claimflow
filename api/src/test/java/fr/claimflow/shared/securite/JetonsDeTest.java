package fr.claimflow.shared.securite;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;

import java.util.Arrays;
import java.util.Map;
import org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.JwtRequestPostProcessor;

/** Jetons de test, construits comme Keycloak les émet : « sub » et realm_access.roles. */
public final class JetonsDeTest {

    /** Identifiant Keycloak de Claire Martin, assurée du jeu de démonstration. */
    public static final String CLAIRE = "5b1f2c3d-0001-4a00-8000-00000000c1a1";

    private JetonsDeTest() {
    }

    public static JwtRequestPostProcessor jeton(String sujet, Role... roles) {
        var noms = Arrays.stream(roles).map(Role::name).toList();
        return jwt()
            .jwt(j -> j.subject(sujet).claim("realm_access", Map.of("roles", noms)))
            .authorities(new ConvertisseurRolesKeycloak());
    }
}
