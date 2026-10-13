package fr.claimflow.bff;

import java.util.List;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.core.oidc.user.OidcUser;
import org.springframework.security.web.csrf.CsrfToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/** US-01 : la SPA demande qui est connecté. Elle reçoit une identité et des rôles, jamais un jeton. */
@RestController
class UtilisateurController {

    private static final String PREFIXE = "ROLE_";

    record Utilisateur(String id, String nom, String email, List<String> roles) {
    }

    @GetMapping("/bff/utilisateur")
    Utilisateur utilisateur(@AuthenticationPrincipal OidcUser utilisateur, CsrfToken csrf) {
        // Lire le jeton CSRF garantit l'écriture du cookie XSRF-TOKEN : la SPA en a besoin pour
        // ses requêtes modifiantes, dès le premier appel après la connexion.
        csrf.getToken();
        var roles = utilisateur.getAuthorities().stream()
            .map(GrantedAuthority::getAuthority)
            .filter(autorite -> autorite.startsWith(PREFIXE))
            .map(autorite -> autorite.substring(PREFIXE.length()))
            .toList();
        return new Utilisateur(utilisateur.getSubject(), utilisateur.getFullName(), utilisateur.getEmail(), roles);
    }
}
