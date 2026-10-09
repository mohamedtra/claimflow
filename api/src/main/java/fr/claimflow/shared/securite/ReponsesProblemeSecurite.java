package fr.claimflow.shared.securite;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import org.jspecify.annotations.NonNull;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.oauth2.server.resource.web.BearerTokenAuthenticationEntryPoint;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.access.AccessDeniedHandler;

/**
 * Refus de sécurité au format RFC 9457 (schéma Probleme du contrat d'API). Les textes sont fixes :
 * rien de ce que le client envoie n'est recopié dans la réponse.
 */
final class ReponsesProblemeSecurite implements AuthenticationEntryPoint, AccessDeniedHandler {

    private final BearerTokenAuthenticationEntryPoint enteteBearer = new BearerTokenAuthenticationEntryPoint();

    @Override
    public void commence(@NonNull HttpServletRequest requete, @NonNull HttpServletResponse reponse, @NonNull AuthenticationException e)
        throws IOException {
        enteteBearer.commence(requete, reponse, e); // statut 401 et en-tête WWW-Authenticate (RFC 6750)
        ecrire(reponse, 401, "Authentification requise", "Jeton d'accès absent, expiré ou invalide.");
    }

    @Override
    public void handle(@NonNull HttpServletRequest requete, @NonNull HttpServletResponse reponse, @NonNull AccessDeniedException e)
        throws IOException {
        ecrire(reponse, 403, "Accès refusé", "Votre rôle ne permet pas cette opération.");
    }

    private static void ecrire(HttpServletResponse reponse, int statut, String titre, String detail)
        throws IOException {
        reponse.setStatus(statut);
        reponse.setContentType("application/problem+json");
        reponse.setCharacterEncoding(StandardCharsets.UTF_8.name());
        reponse.getWriter().write("""
                {"type":"about:blank","title":"%s","status":%d,"detail":"%s"}"""
            .formatted(titre, statut, detail));
    }
}
