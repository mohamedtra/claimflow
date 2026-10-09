package fr.claimflow.shared.securite;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;

/** US-03 : les rôles Keycloak deviennent des autorités Spring. */
class ConvertisseurRolesKeycloakTest {

    static final String CLAIRE = "5b1f2c3d-0001-4a00-8000-00000000c1a1";

    private final ConvertisseurRolesKeycloak convertisseur = new ConvertisseurRolesKeycloak();

    @Test
    void us03_seuls_les_roles_claimflow_deviennent_des_autorites() {
        var jeton = jeton(Map.of("realm_access",
            Map.of("roles", List.of("ASSURE", "offline_access", "default-roles-claimflow"))));

        assertThat(convertisseur.convert(jeton))
            .extracting(GrantedAuthority::getAuthority)
            .containsExactly("ROLE_ASSURE");
    }

    @Test
    void us03_un_jeton_sans_roles_ne_donne_aucune_autorite() {
        assertThat(convertisseur.convert(jeton(Map.of("autre", "valeur")))).isEmpty();
    }

    static Jwt jeton(Map<String, Object> claims) {
        return Jwt.withTokenValue("jeton").header("alg", "none").subject(CLAIRE)
            .claims(c -> c.putAll(claims)).build();
    }
}
