package fr.claimflow.shared.securite;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;

/** US-03 : l'utilisateur connecté est tiré du jeton, jamais d'un paramètre de la requête. */
class UtilisateurConnecteTest {

    @Test
    void us03_l_identite_et_les_roles_viennent_du_jeton() {
        var jwt = ConvertisseurRolesKeycloakTest.jeton(Map.of("realm_access", Map.of("roles", List.of("GESTIONNAIRE"))));
        var authentification = new JwtAuthenticationToken(jwt, new ConvertisseurRolesKeycloak().convert(jwt));

        var utilisateur = UtilisateurConnecte.depuis(authentification);

        assertThat(utilisateur.id()).isEqualTo(UUID.fromString(ConvertisseurRolesKeycloakTest.CLAIRE));
        assertThat(utilisateur.roles()).containsExactly(Role.GESTIONNAIRE);
        assertThat(utilisateur.a(Role.ASSURE)).isFalse();
    }
}
