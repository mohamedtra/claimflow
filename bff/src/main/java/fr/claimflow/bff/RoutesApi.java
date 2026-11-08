package fr.claimflow.bff;

import static org.springframework.cloud.gateway.server.mvc.filter.BeforeFilterFunctions.removeRequestHeader;
import static org.springframework.cloud.gateway.server.mvc.filter.BeforeFilterFunctions.uri;
import static org.springframework.cloud.gateway.server.mvc.filter.TokenRelayFilterFunctions.tokenRelay;
import static org.springframework.cloud.gateway.server.mvc.handler.GatewayRouterFunctions.route;
import static org.springframework.cloud.gateway.server.mvc.handler.HandlerFunctions.http;
import static org.springframework.web.servlet.function.RequestPredicates.path;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ProblemDetail;
import org.springframework.security.oauth2.core.OAuth2AuthorizationException;
import org.springframework.web.servlet.function.HandlerFilterFunction;
import org.springframework.web.servlet.function.RouterFunction;
import org.springframework.web.servlet.function.ServerResponse;

/**
 * /api/** est relayé tel quel vers l'API, avec le jeton d'accès de la session dans l'en-tête
 * Authorization (TokenRelay). Le cookie de session, lui, ne sort jamais du BFF.
 */
@Configuration(proxyBeanMethods = false)
class RoutesApi {

    @Bean
    RouterFunction<ServerResponse> routeApi(ProprietesBff proprietes) {
        return route("api")
            .route(path("/api/**"), http())
            // sessionExpiree() enveloppe tokenRelay() : elle voit passer ses erreurs.
            .filter(sessionExpiree().andThen(tokenRelay()))
            .before(uri(proprietes.adresseApi()))
            .before(removeRequestHeader(HttpHeaders.COOKIE))
            .build();
    }

    /**
     * La session existe, mais plus aucun jeton utilisable : jeton absent, ou jeton de
     * rafraîchissement refusé par Keycloak (session SSO close, inactivité). Sans ce filtre, Spring
     * Security répondrait 302 vers Keycloak, qu'un appel HTTP de la SPA ne peut pas suivre (CORS). On
     * ferme la session et on répond 401 : la SPA renvoie à la connexion (US-01).
     */
    static HandlerFilterFunction<ServerResponse, ServerResponse> sessionExpiree() {
        return (requete, suite) -> {
            try {
                return suite.handle(requete);
            } catch (OAuth2AuthorizationException erreur) {
                var session = requete.servletRequest().getSession(false);
                if (session != null) {
                    session.invalidate();
                }
                var probleme = ProblemDetail.forStatusAndDetail(HttpStatus.UNAUTHORIZED,
                    "Session expirée (US-01) : se reconnecter par /oauth2/authorization/keycloak.");
                probleme.setTitle("Session expirée");
                return ServerResponse.status(HttpStatus.UNAUTHORIZED)
                    .contentType(MediaType.APPLICATION_PROBLEM_JSON)
                    .body(probleme);
            }
        };
    }
}
