package fr.claimflow.bff;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.allOf;
import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.startsWith;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.oidcLogin;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.cookie;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.sun.net.httpserver.Headers;
import com.sun.net.httpserver.HttpServer;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.client.OAuth2AuthorizedClient;
import org.springframework.security.oauth2.client.authentication.OAuth2AuthenticationToken;
import org.springframework.security.oauth2.client.registration.ClientRegistrationRepository;
import org.springframework.security.oauth2.client.web.OAuth2AuthorizedClientRepository;
import org.springframework.security.oauth2.core.OAuth2AccessToken;
import org.springframework.security.oauth2.core.oidc.IdTokenClaimNames;
import org.springframework.security.oauth2.core.oidc.OidcIdToken;
import org.springframework.security.oauth2.core.oidc.user.DefaultOidcUser;
import org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.OidcLoginRequestPostProcessor;
import org.springframework.security.web.context.HttpSessionSecurityContextRepository;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

/** US-01 et US-02 : connexion par le BFF, aucun jeton dans le navigateur (ADR-003). */
@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
@Import(BffIT.RetourKeycloakDeTest.class)
class BffIT {

    private static final String CLAIRE = "5b1f2c3d-0001-4a00-8000-00000000c1a1";

    @Container
    @ServiceConnection
    static final PostgreSQLContainer POSTGRES = new PostgreSQLContainer("postgres:18");

    // Fausse API : retient les en-têtes de la dernière requête relayée.
    static final AtomicReference<Headers> RECUS = new AtomicReference<>();
    static final HttpServer API = demarrerFausseApi();

    @DynamicPropertySource
    static void adresseApi(DynamicPropertyRegistry registre) {
        registre.add("claimflow.bff.adresse-api", () -> "http://localhost:" + API.getAddress().getPort());
    }

    @AfterAll
    static void arreterFausseApi() {
        API.stop(0);
    }

    @Autowired
    MockMvc mvc;

    @BeforeEach
    void oublier() {
        RECUS.set(null);
    }

    @Test
    void us01_sans_session_le_bff_repond_401_sans_rien_relayer() throws Exception {
        mvc.perform(get("/bff/utilisateur"))
            .andExpect(status().isUnauthorized())
            .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON));
        mvc.perform(get("/api/v1/contrats"))
            .andExpect(status().isUnauthorized());

        assertThat(RECUS.get()).isNull();
    }

    @Test
    void us01_la_connexion_part_vers_keycloak_avec_pkce() throws Exception {
        mvc.perform(get("/oauth2/authorization/keycloak"))
            .andExpect(status().is3xxRedirection())
            .andExpect(header().string(HttpHeaders.LOCATION, allOf(
                startsWith("https://keycloak.test/realms/claimflow/protocol/openid-connect/auth"),
                containsString("code_challenge_method=S256"),
                containsString("scope=openid"))));
    }

    @Test
    void us01_la_spa_connait_l_utilisateur_et_recoit_son_jeton_csrf() throws Exception {
        mvc.perform(get("/bff/utilisateur").with(claire()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(CLAIRE))
            .andExpect(jsonPath("$.nom").value("Claire Martin"))
            .andExpect(jsonPath("$.email").value("claire.martin@exemple.fr"))
            .andExpect(jsonPath("$.roles", contains("ASSURE")))
            .andExpect(cookie().exists("XSRF-TOKEN"))
            .andExpect(cookie().httpOnly("XSRF-TOKEN", false));
    }

    @Test
    void us01_le_cookie_de_session_est_httponly_secure_et_samesite() throws Exception {
        mvc.perform(retourKeycloak())
            .andExpect(status().isOk())
            .andExpect(cookie().httpOnly(ConfigurationSession.COOKIE, true))
            .andExpect(cookie().secure(ConfigurationSession.COOKIE, true))
            .andExpect(cookie().sameSite(ConfigurationSession.COOKIE, "Lax"));
    }

    @Test
    void us01_l_api_recoit_le_jeton_mais_jamais_le_cookie() throws Exception {
        // 1. Comme au retour de Keycloak : utilisateur et jeton rangés en session, en base.
        var cookieSession = mvc.perform(retourKeycloak())
            .andReturn().getResponse().getCookie(ConfigurationSession.COOKIE);
        assertThat(cookieSession).as("cookie de session émis par le BFF").isNotNull();

        // 2. Comme le navigateur ensuite : le cookie, et rien d'autre.
        mvc.perform(get("/api/v1/contrats").cookie(cookieSession))
            .andExpect(status().isOk());

        assertThat(RECUS.get().getFirst("Authorization")).isEqualTo("Bearer jeton-de-test");
        assertThat(RECUS.get().containsKey("Cookie")).isFalse();
    }

    @Test
    void us01_la_deconnexion_exige_le_jeton_csrf() throws Exception {
        mvc.perform(post("/bff/deconnexion").with(claire()))
            .andExpect(status().isForbidden());
    }

    @Test
    void us01_la_deconnexion_rend_l_adresse_de_sortie_sans_rediriger() throws Exception {
        // Comme la SPA : lire le cookie XSRF-TOKEN, puis le renvoyer en en-tête.
        var xsrf = mvc.perform(get("/bff/utilisateur").with(claire()))
            .andReturn().getResponse().getCookie("XSRF-TOKEN");

        mvc.perform(post("/bff/deconnexion").with(claire())
                .cookie(xsrf).header("X-XSRF-TOKEN", xsrf.getValue()))
            .andExpect(status().isAccepted())
            .andExpect(header().string(HttpHeaders.LOCATION, "http://localhost:5173/"));
    }

    private static OidcLoginRequestPostProcessor claire() {
        return oidcLogin()
            .idToken(t -> t.subject(CLAIRE)
                .claim("name", "Claire Martin")
                .claim("email", "claire.martin@exemple.fr"))
            .authorities(new SimpleGrantedAuthority("ROLE_ASSURE"));
    }
    private static MockHttpServletRequestBuilder retourKeycloak() {
        return get("/test/retour-keycloak").with(authentication(claireConnectee()));
    }

    private static OAuth2AuthenticationToken claireConnectee() {
        var maintenant = Instant.now();
        var idToken = OidcIdToken.withTokenValue("id-token").subject(CLAIRE)
            .issuedAt(maintenant).expiresAt(maintenant.plusSeconds(300)).build();
        var utilisateur = new DefaultOidcUser(List.of(new SimpleGrantedAuthority("ROLE_ASSURE")), idToken,
            IdTokenClaimNames.SUB);
        return new OAuth2AuthenticationToken(utilisateur, utilisateur.getAuthorities(), "keycloak");
    }

    /**
     * N'existe que dans les tests : fait ce que fait le retour de Keycloak (/login/oauth2/code), mais
     * sans Keycloak. Passe par la vraie chaîne de filtres : Spring Session range tout en base et émet
     * le cookie, exactement comme pour le navigateur.
     */
    @RestController
    static class RetourKeycloakDeTest {

        private final ClientRegistrationRepository clients;
        private final OAuth2AuthorizedClientRepository jetons;

        RetourKeycloakDeTest(ClientRegistrationRepository clients, OAuth2AuthorizedClientRepository jetons) {
            this.clients = clients;
            this.jetons = jetons;
        }

        @GetMapping("/test/retour-keycloak")
        void connecter(Authentication connexion, HttpServletRequest requete, HttpServletResponse reponse) {
            var contexte = SecurityContextHolder.createEmptyContext();
            contexte.setAuthentication(connexion);
            new HttpSessionSecurityContextRepository().saveContext(contexte, requete, reponse);

            var maintenant = Instant.now();
            var jetonAcces = new OAuth2AccessToken(OAuth2AccessToken.TokenType.BEARER, "jeton-de-test",
                maintenant, maintenant.plusSeconds(300));
            jetons.saveAuthorizedClient(
                new OAuth2AuthorizedClient(clients.findByRegistrationId("keycloak"), connexion.getName(), jetonAcces),
                connexion, requete, reponse);
        }
    }

    private static HttpServer demarrerFausseApi() {
        try {
            var serveur = HttpServer.create(new InetSocketAddress("localhost", 0), 0);
            serveur.createContext("/", echange -> {
                RECUS.set(echange.getRequestHeaders());
                var corps = "[]".getBytes(StandardCharsets.UTF_8);
                echange.getResponseHeaders().add("Content-Type", "application/json");
                echange.sendResponseHeaders(200, corps.length);
                try (var sortie = echange.getResponseBody()) {
                    sortie.write(corps);
                }
            });
            serveur.start();
            return serveur;
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }
}
