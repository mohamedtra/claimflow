package fr.claimflow.contrat;

import static fr.claimflow.shared.securite.JetonsDeTest.CLAIRE;
import static fr.claimflow.shared.securite.JetonsDeTest.jeton;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.hasItem;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import fr.claimflow.shared.securite.Role;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.context.jdbc.Sql;
import org.springframework.test.web.servlet.MockMvc;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

/** US-04 : l'assuré consulte ses contrats. US-03 : il ne voit que les siens, et seul un assuré y a accès. */
@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
@Sql("/db/contrats-de-test.sql")
class ContratsApiIT {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer POSTGRES = new PostgreSQLContainer("postgres:18")
        .withInitScript("db/roles-de-test.sql");

    @Autowired
    MockMvc mvc;

    @Test
    void us04_l_assure_voit_ses_contrats_et_leurs_garanties() throws Exception {
        mvc.perform(get("/api/v1/contrats").with(jeton(CLAIRE, Role.ASSURE)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$", hasSize(2)))
            .andExpect(jsonPath("$[0].numero").value("HAB-0000001"))      // le plus récent d'abord
            .andExpect(jsonPath("$[0].type").value("HABITATION"))
            .andExpect(jsonPath("$[0].garanties", hasSize(2)))
            .andExpect(jsonPath("$[0].garanties[0].type").value("DEGAT_DES_EAUX"))
            .andExpect(jsonPath("$[0].garanties[0].plafond").value("8000.00"))   // chaîne, ADR-012
            .andExpect(jsonPath("$[0].garanties[0].tauxVetuste").value(15))
            .andExpect(jsonPath("$[1].numero").value("AUTO-0000002"));
    }

    @Test
    void us04_un_contrat_echu_depuis_plus_de_deux_ans_est_masque() throws Exception {
        mvc.perform(get("/api/v1/contrats").with(jeton(CLAIRE, Role.ASSURE)))
            .andExpect(jsonPath("$[*].numero", not(hasItem("AUTO-0000003"))));
    }

    @Test
    void us03_un_assure_ne_voit_jamais_les_contrats_d_un_autre() throws Exception {
        mvc.perform(get("/api/v1/contrats").with(jeton(CLAIRE, Role.ASSURE)))
            .andExpect(jsonPath("$[*].numero", not(hasItem("HAB-0000004"))));
    }

    @Test
    void us03_un_compte_sans_assure_relie_ne_voit_aucun_contrat() throws Exception {
        mvc.perform(get("/api/v1/contrats").with(jeton("5b1f2c3d-9999-4a00-8000-00000000ffff", Role.ASSURE)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$", hasSize(0)));
    }

    @ParameterizedTest
    @EnumSource(value = Role.class, names = "ASSURE", mode = EnumSource.Mode.EXCLUDE)
    void us03_les_contrats_sont_reserves_aux_assures(Role role) throws Exception {
        mvc.perform(get("/api/v1/contrats").with(jeton(CLAIRE, role)))
            .andExpect(status().isForbidden());
    }
}
