package fr.claimflow.bff;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.session.web.http.CookieSerializer;
import org.springframework.session.web.http.DefaultCookieSerializer;

/**
 * Cookie de session du BFF (ADR-003) : le seul élément d'authentification que reçoit le navigateur.
 *
 * <p>Déclaré explicitement plutôt que par server.servlet.session.cookie.* : Spring Boot n'applique
 * ces propriétés au cookie de Spring Session qu'avec un serveur embarqué. En déploiement WAR, et dans
 * les tests MockMvc qui empruntent ce chemin, le cookie redevenait « SESSION », sans HttpOnly ni
 * SameSite. Ici, ses attributs ne dépendent plus du mode de déploiement.
 */
@Configuration(proxyBeanMethods = false)
class ConfigurationSession {

    static final String COOKIE = "CLAIMFLOW_SESSION";

    @Bean
    CookieSerializer cookieDeSession(ProprietesBff proprietes) {
        var cookie = new DefaultCookieSerializer();
        cookie.setCookieName(COOKIE);
        cookie.setCookiePath("/");
        cookie.setUseHttpOnlyCookie(true);
        cookie.setUseSecureCookie(proprietes.cookieSecurise());
        // Lax et non Strict : le retour de Keycloak est une navigation qui vient d'un autre site.
        cookie.setSameSite("Lax");
        return cookie;
    }
}
