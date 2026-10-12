package fr.claimflow.shared.securite;

import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import org.springframework.core.convert.converter.Converter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;

/**
 * Traduit les rôles du realm (claim realm_access.roles) en autorités Spring. Les rôles techniques
 * de Keycloak (offline_access, default-roles-claimflow…) sont ignorés : seuls ceux de Role comptent.
 *
 * <p>Le claim est lu directement : avec Spring Security 7, {@code getClaimAsMap} fait passer la
 * valeur par une conversion interne qui rendait la liste imbriquée « roles » inexploitable.
 */
final class ConvertisseurRolesKeycloak implements Converter<Jwt, Collection<GrantedAuthority>> {

    @Override
    public Collection<GrantedAuthority> convert(Jwt jeton) {
        if (!(jeton.getClaims().get("realm_access") instanceof Map<?, ?> realm)
            || !(realm.get("roles") instanceof Collection<?> roles)) {
            return List.of();
        }
        return roles.stream()
            .map(String::valueOf)
            .flatMap(nom -> Arrays.stream(Role.values()).filter(role -> role.name().equals(nom)))
            .map(role -> (GrantedAuthority) new SimpleGrantedAuthority(role.autorite()))
            .toList();
    }
}
