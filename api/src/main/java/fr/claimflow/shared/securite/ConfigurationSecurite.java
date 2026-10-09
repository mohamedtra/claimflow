package fr.claimflow.shared.securite;

import jakarta.servlet.DispatcherType;
import org.springframework.boot.autoconfigure.condition.ConditionalOnWebApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.web.SecurityFilterChain;

/**
 * L'API est un resource server (ADR-002) : chaque appel à /api/** porte un jeton Keycloak valide,
 * vérifié sur sa signature, son émetteur, son audience et son expiration. Tout le reste est fermé.
 * {@code @EnableMethodSecurity} prépare les politiques par commande (@PreAuthorize, section 2.9).
 *
 * <p>Chargée seulement dans une application web : sans HTTP (MigrationsIT, tâches en ligne de
 * commande), il n'y a pas de chaîne de filtres à construire.
 */
@Configuration(proxyBeanMethods = false)
@ConditionalOnWebApplication(type = ConditionalOnWebApplication.Type.SERVLET)
@EnableMethodSecurity
class ConfigurationSecurite {

    // CSRF désactivé volontairement (java:S4502) : l'API n'émet ni cookie ni session et n'accepte
    // que des jetons Bearer, qu'un site tiers ne peut pas joindre à une requête. La protection CSRF
    // est portée par le BFF, seul point d'entrée du navigateur (ADR-003).
    @SuppressWarnings("java:S4502")
    @Bean
    SecurityFilterChain securiteApi(HttpSecurity http) {
        var reponses = new ReponsesProblemeSecurite();
        var roles = new JwtAuthenticationConverter();
        roles.setJwtGrantedAuthoritiesConverter(new ConvertisseurRolesKeycloak());

        return http
            .csrf(AbstractHttpConfigurer::disable)
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(a -> a
                // Sans cette ligne, un 404 deviendrait 403 en passant par /error.
                .dispatcherTypeMatchers(DispatcherType.ERROR).permitAll()
                .requestMatchers("/actuator/health/**", "/actuator/info").permitAll()
                .requestMatchers("/api/**").authenticated()
                .anyRequest().denyAll())
            .oauth2ResourceServer(o -> o
                .jwt(jwt -> jwt.jwtAuthenticationConverter(roles))
                .authenticationEntryPoint(reponses)
                .accessDeniedHandler(reponses))
            .exceptionHandling(e -> e
                .authenticationEntryPoint(reponses)
                .accessDeniedHandler(reponses))
            .build();
    }
}
