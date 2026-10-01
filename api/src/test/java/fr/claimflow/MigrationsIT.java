package fr.claimflow;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.sql.DriverManager;
import java.sql.SQLException;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

/**
 * Démarre l'application complète sur un vrai PostgreSQL (jamais H2), applique toutes les migrations,
 * puis vérifie les garanties portées par la base elle-même.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.NONE)
@Testcontainers
class MigrationsIT {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer POSTGRES = new PostgreSQLContainer("postgres:18")
            .withInitScript("db/roles-de-test.sql");

    private static final String ENTREE_AUDIT = """
            INSERT INTO audit.entree_audit
                (evenement_id, acteur_id, acteur_role, action, objet_type, objet_id, hash_precedent, hash)
            VALUES (gen_random_uuid(), 'test', 'GESTIONNAIRE', 'SINISTRE_DECLARE', 'SINISTRE',
                    gen_random_uuid(), repeat('0', 64), encode(sha256(gen_random_uuid()::text::bytea), 'hex'))
            """;

    @Autowired
    Flyway flyway;

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void toutes_les_migrations_sont_appliquees() {
        assertThat(flyway.info().pending()).isEmpty();
        assertThat(flyway.info().current().getVersion().getVersion()).isEqualTo("10");
    }

    @Test
    void les_parametres_valides_au_cadrage_sont_en_place() {
        var seuils = jdbc.queryForObject(
                "SELECT seuil_expertise || '/' || seuil_double_validation FROM parametrage.parametres", String.class);
        assertThat(seuils).isEqualTo("1500.00/10000.00");
    }

    @Test
    void rg11_le_compte_applicatif_ajoute_au_journal_sans_pouvoir_le_modifier() throws SQLException {
        try (var connexion = DriverManager.getConnection(POSTGRES.getJdbcUrl(), "claimflow_app", "claimflow-app-test");
             var requete = connexion.createStatement()) {
            assertThat(requete.executeUpdate(ENTREE_AUDIT)).isEqualTo(1);
            assertThatThrownBy(() -> requete.executeUpdate("UPDATE audit.entree_audit SET action = 'MODIFIE'"))
                    .isInstanceOf(SQLException.class)
                    .extracting(e -> ((SQLException) e).getSQLState()).isEqualTo("42501");
            assertThatThrownBy(() -> requete.executeUpdate("DELETE FROM audit.entree_audit"))
                    .isInstanceOf(SQLException.class)
                    .extracting(e -> ((SQLException) e).getSQLState()).isEqualTo("42501");
        }
    }

    @Test
    void rg11_meme_le_proprietaire_ne_peut_pas_alterer_le_journal() {
        jdbc.update(ENTREE_AUDIT);
        // Le message de PostgreSQL est porté par la cause : Spring enveloppe l'erreur SQL.
        assertThatThrownBy(() -> jdbc.update("UPDATE audit.entree_audit SET action = 'MODIFIE'"))
                .isInstanceOf(DataAccessException.class)
                .rootCause().hasMessageContaining("ajout seul");
        assertThatThrownBy(() -> jdbc.update("TRUNCATE audit.entree_audit"))
                .isInstanceOf(DataAccessException.class)
                .rootCause().hasMessageContaining("ajout seul");
    }

    @Test
    void rg06_la_base_refuse_qu_un_auteur_valide_sa_propre_proposition() {
        assertThatThrownBy(() -> jdbc.update("""
                INSERT INTO indemnisation.proposition
                    (id, sinistre_id, statut, dommage_retenu, vetuste, plafond, franchise, montant,
                     propose_par, valide_par, cree_le)
                VALUES (gen_random_uuid(), gen_random_uuid(), 'OFFRE_ENVOYEE', 13780, 0, 60000, 500, 13280,
                        '5b1f2c3d-0005-4a00-8000-00000000c1a5', '5b1f2c3d-0005-4a00-8000-00000000c1a5', now())
                """))
                .isInstanceOf(DataAccessException.class)
                .hasMessageContaining("ck_proposition_quatre_yeux");
    }

    @Test
    void un_statut_inconnu_est_refuse() {
        assertThatThrownBy(() -> jdbc.update("""
                INSERT INTO sinistre.sinistre
                    (id, numero, contrat_id, assure_id, assure_nom, garantie, date_survenance, date_connaissance,
                     declare_le, circonstances, lieu_ligne, lieu_code_postal, lieu_commune, statut)
                VALUES (gen_random_uuid(), 'SIN-2026-000001', gen_random_uuid(), gen_random_uuid(), 'Test',
                        'VOL', DATE '2026-09-18', DATE '2026-09-18', now(), 'Circonstances assez détaillées',
                        '1 rue de la Paix', '06400', 'Cannes', 'PAYE')
                """))
                .isInstanceOf(DataAccessException.class)
                .hasMessageContaining("ck_sinistre_statut");
    }
}
