package fr.claimflow.bff;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;

/**
 * Adresses fournies par chaque environnement : l'API (jamais exposée à Internet, ADR-003) et la
 * SPA, où l'utilisateur revient après sa connexion ou sa déconnexion. Le cookie de session est
 * « Secure » par défaut ; seul le poste local (http://localhost) le désactive.
 */
@ConfigurationProperties("claimflow.bff")
public record ProprietesBff(String adresseApi, String adresseSpa, @DefaultValue("true") boolean cookieSecurise) {
}
