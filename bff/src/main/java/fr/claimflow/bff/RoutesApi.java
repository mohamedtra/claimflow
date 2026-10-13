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
            .filter(tokenRelay())
            .before(uri(proprietes.adresseApi()))
            .before(removeRequestHeader(HttpHeaders.COOKIE))
            .build();
    }
}
