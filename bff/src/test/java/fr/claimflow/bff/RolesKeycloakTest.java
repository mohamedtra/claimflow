package fr.claimflow.bff;

import static org.assertj.core.api.Assertions.assertThat;

import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.PlainJWT;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.security.core.GrantedAuthority;

/** US-01 : la SPA connaît les rôles métier de l'utilisateur, pas les rôles techniques de Keycloak. */
class RolesKeycloakTest {

    @Test
    void us01_seuls_les_roles_metier_deviennent_des_autorites() {
        var jeton = jeton(Map.of("roles", List.of("ASSURE", "offline_access", "default-roles-claimflow")));

        assertThat(RolesKeycloak.depuisJetonAcces(jeton))
            .extracting(GrantedAuthority::getAuthority)
            .containsExactly("ROLE_ASSURE");
    }

    @Test
    void us01_sans_realm_access_aucun_role() {
        var jeton = new PlainJWT(new JWTClaimsSet.Builder().subject("x").build()).serialize();

        assertThat(RolesKeycloak.depuisJetonAcces(jeton)).isEmpty();
    }

    @Test
    void us01_un_jeton_illisible_ne_donne_aucun_role() {
        assertThat(RolesKeycloak.depuisJetonAcces("pas-un-jwt")).isEmpty();
    }

    private static String jeton(Object realmAccess) {
        return new PlainJWT(new JWTClaimsSet.Builder()
            .subject("5b1f2c3d-0001-4a00-8000-00000000c1a1")
            .claim("realm_access", realmAccess)
            .build()).serialize();
    }
}
