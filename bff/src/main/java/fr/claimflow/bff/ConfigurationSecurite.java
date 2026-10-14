package fr.claimflow.bff;

import jakarta.servlet.DispatcherType;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.oauth2.client.OAuth2AuthorizedClientManager;
import org.springframework.security.oauth2.client.OAuth2AuthorizedClientProviderBuilder;
import org.springframework.security.oauth2.client.oidc.userinfo.OidcUserRequest;
import org.springframework.security.oauth2.client.oidc.userinfo.OidcUserService;
import org.springframework.security.oauth2.client.oidc.web.logout.OidcClientInitiatedLogoutSuccessHandler;
import org.springframework.security.oauth2.client.registration.ClientRegistrationRepository;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserService;
import org.springframework.security.oauth2.client.web.DefaultOAuth2AuthorizationRequestResolver;
import org.springframework.security.oauth2.client.web.DefaultOAuth2AuthorizedClientManager;
import org.springframework.security.oauth2.client.web.HttpSessionOAuth2AuthorizedClientRepository;
import org.springframework.security.oauth2.client.web.OAuth2AuthorizationRequestCustomizers;
import org.springframework.security.oauth2.client.web.OAuth2AuthorizationRequestRedirectFilter;
import org.springframework.security.oauth2.client.web.OAuth2AuthorizedClientRepository;
import org.springframework.security.oauth2.core.oidc.IdTokenClaimNames;
import org.springframework.security.oauth2.core.oidc.user.DefaultOidcUser;
import org.springframework.security.oauth2.core.oidc.user.OidcUser;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.logout.LogoutSuccessHandler;

/**
 * Le BFF est le seul point d'entrée du navigateur (ADR-003) : il connecte l'utilisateur auprès de
 * Keycloak (code + PKCE), garde les jetons en session serveur et ne rend au navigateur qu'un cookie
 * HttpOnly. Les requêtes modifiantes portent un jeton CSRF.
 */
@Configuration(proxyBeanMethods = false)
class ConfigurationSecurite {

    private static final String NON_CONNECTE = """
        {"type":"about:blank","title":"Non connecté","status":401,\
        "detail":"Aucune session ouverte : se connecter par /oauth2/authorization/keycloak."}""";

    @Bean
    SecurityFilterChain securiteBff(HttpSecurity http, ClientRegistrationRepository clients,
                                    OAuth2UserService<OidcUserRequest, OidcUser> utilisateursOidc,
                                    ProprietesBff proprietes) {
        var demandes = new DefaultOAuth2AuthorizationRequestResolver(clients,
            OAuth2AuthorizationRequestRedirectFilter.DEFAULT_AUTHORIZATION_REQUEST_BASE_URI);
        demandes.setAuthorizationRequestCustomizer(OAuth2AuthorizationRequestCustomizers.withPkce());

        return http
            .authorizeHttpRequests(a -> a
                .dispatcherTypeMatchers(DispatcherType.ERROR).permitAll()
                .requestMatchers("/actuator/health/**", "/actuator/info").permitAll()
                .anyRequest().authenticated())
            .oauth2Login(o -> o
                .authorizationEndpoint(e -> e.authorizationRequestResolver(demandes))
                .userInfoEndpoint(u -> u.oidcUserService(utilisateursOidc))
                .defaultSuccessUrl(proprietes.adresseSpa(), true)
                .failureUrl(proprietes.adresseSpa() + "?erreur=connexion"))
            .logout(l -> l
                .logoutUrl("/bff/deconnexion")
                .logoutSuccessHandler(deconnexion(clients, proprietes.adresseSpa())))
            // Cookie XSRF-TOKEN lisible par la SPA, renvoyé dans l'en-tête X-XSRF-TOKEN.
            .csrf(c -> c.spa())
            // Une requête fetch ne sait pas suivre une redirection vers Keycloak : 401 net.
            .exceptionHandling(e -> e.authenticationEntryPoint(ConfigurationSecurite::nonConnecte))
            .build();
    }

    /** Jetons rangés dans la session (donc en base), et non dans la mémoire du processus. */
    @Bean
    OAuth2AuthorizedClientRepository jetonsEnSession() {
        return new HttpSessionOAuth2AuthorizedClientRepository();
    }

    /** Utilisé par TokenRelay : rend le jeton de la session et le rafraîchit s'il a expiré. */
    @Bean
    OAuth2AuthorizedClientManager gestionnaireJetons(ClientRegistrationRepository clients,
                                                     OAuth2AuthorizedClientRepository jetons) {
        var gestionnaire = new DefaultOAuth2AuthorizedClientManager(clients, jetons);
        gestionnaire.setAuthorizedClientProvider(OAuth2AuthorizedClientProviderBuilder.builder()
            .authorizationCode()
            .refreshToken()
            .build());
        return gestionnaire;
    }

    /** Ajoute à l'utilisateur OIDC les rôles du realm, absents du jeton d'identité. */
    @Bean
    OAuth2UserService<OidcUserRequest, OidcUser> utilisateursOidc() {
        var delegue = new OidcUserService();
        return requete -> {
            var utilisateur = delegue.loadUser(requete);
            var roles = RolesKeycloak.depuisJetonAcces(requete.getAccessToken().getTokenValue());
            return new DefaultOidcUser(roles, utilisateur.getIdToken(), utilisateur.getUserInfo(),
                IdTokenClaimNames.SUB);
        };
    }

    /**
     * Ferme la session locale puis rend l'adresse de déconnexion de Keycloak (202 + Location) au
     * lieu de rediriger : la SPA appelle en fetch et navigue elle-même vers cette adresse.
     */
    private static LogoutSuccessHandler deconnexion(ClientRegistrationRepository clients, String adresseSpa) {
        var oidc = new OidcClientInitiatedLogoutSuccessHandler(clients);
        oidc.setPostLogoutRedirectUri(adresseSpa);
        oidc.setDefaultTargetUrl(adresseSpa);
        oidc.setRedirectStrategy((requete, reponse, adresse) -> {
            reponse.setStatus(HttpStatus.ACCEPTED.value());
            reponse.setHeader(HttpHeaders.LOCATION, adresse);
        });
        return oidc;
    }

    private static void nonConnecte(HttpServletRequest requete, HttpServletResponse reponse,
                                    AuthenticationException erreur) throws IOException {
        reponse.setStatus(HttpStatus.UNAUTHORIZED.value());
        reponse.setContentType(MediaType.APPLICATION_PROBLEM_JSON_VALUE);
        reponse.setCharacterEncoding(StandardCharsets.UTF_8.name());
        reponse.getWriter().write(NON_CONNECTE);
    }
}
