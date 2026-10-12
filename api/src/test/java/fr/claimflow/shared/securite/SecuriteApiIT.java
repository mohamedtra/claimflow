package fr.claimflow.shared.securite;

import static org.hamcrest.Matchers.startsWith;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.JwtRequestPostProcessor;
import org.springframework.test.web.servlet.MockMvc;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

/** US-03 : l'API refuse tout appel sans jeton valide, et ferme tout ce qui n'est pas l'API. */
@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
class SecuriteApiIT {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer POSTGRES = new PostgreSQLContainer("postgres:18")
        .withInitScript("db/roles-de-test.sql");

    @Autowired
    MockMvc mvc;

    @Test
    void us03_sans_jeton_l_api_repond_401_au_format_probleme() throws Exception {
        mvc.perform(get("/api/v1/contrats"))
            .andExpect(status().isUnauthorized())
            .andExpect(header().string("WWW-Authenticate", startsWith("Bearer")))
            .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON))
            .andExpect(jsonPath("$.status").value(401));
    }

    @Test
    void us03_un_jeton_illisible_est_refuse() throws Exception {
        mvc.perform(get("/api/v1/contrats").header("Authorization", "Bearer pas-un-jwt"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void us03_la_sante_reste_publique() throws Exception {
        mvc.perform(get("/actuator/health")).andExpect(status().isOk());
    }

    @Test
    void us03_un_jeton_valide_franchit_la_securite() throws Exception {
        // La ressource arrive à l'étape 2 : 404, et surtout ni 401 ni 403.
        mvc.perform(get("/api/v1/contrats").with(assure())).andExpect(status().isNotFound());
    }

    @Test
    void us03_tout_ce_qui_n_est_pas_l_api_est_ferme() throws Exception {
        mvc.perform(get("/console").with(assure()))
            .andExpect(status().isForbidden())
            .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON));
    }

    private static JwtRequestPostProcessor assure() {
        return jwt()
            .jwt(j -> j.subject(ConvertisseurRolesKeycloakTest.CLAIRE)
                .claim("realm_access", Map.of("roles", List.of("ASSURE"))))
            .authorities(new ConvertisseurRolesKeycloak());
    }
}
