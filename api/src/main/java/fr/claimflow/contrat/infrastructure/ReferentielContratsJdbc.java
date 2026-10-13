package fr.claimflow.contrat.infrastructure;

import fr.claimflow.contrat.TypeGarantie;
import fr.claimflow.contrat.domain.ContratAssure;
import fr.claimflow.contrat.domain.GarantieSouscrite;
import fr.claimflow.contrat.domain.ReferentielContrats;
import fr.claimflow.contrat.domain.TypeContrat;
import fr.claimflow.shared.Montant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Lecture du référentiel en une seule requête : contrats et garanties ensemble, sans requête par
 * contrat (pas de N+1). Le filtre sur l'utilisateur est dans le WHERE : un contrat d'un autre
 * assuré n'est jamais chargé (section 2.9, premier verrou contre l'IDOR).
 */
@Repository
class ReferentielContratsJdbc implements ReferentielContrats {

    private static final String CONTRATS_DE_L_UTILISATEUR = """
            SELECT c.id, c.numero, c.type, c.libelle, c.debut, c.fin,
                   g.type AS garantie, g.plafond, g.franchise, g.taux_vetuste
            FROM contrat.contrat c
            JOIN contrat.assure a ON a.id = c.assure_id
            LEFT JOIN contrat.garantie g ON g.contrat_id = c.id
            WHERE a.utilisateur_id = :utilisateur
            ORDER BY c.debut DESC, c.numero, g.type
            """;

    private final JdbcClient jdbc;

    ReferentielContratsJdbc(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public List<ContratAssure> contratsDe(UUID utilisateurId) {
        // Une ligne par garantie : on regroupe par contrat en gardant l'ordre de la requête.
        Map<UUID, Brouillon> contrats = new LinkedHashMap<>();
        jdbc.sql(CONTRATS_DE_L_UTILISATEUR)
            .param("utilisateur", utilisateurId)
            .query(ligne -> {
                var id = ligne.getObject("id", UUID.class);
                var contrat = contrats.computeIfAbsent(id, cle -> {
                    try {
                        return new Brouillon(cle, ligne.getString("numero"),
                            TypeContrat.valueOf(ligne.getString("type")), ligne.getString("libelle"),
                            ligne.getObject("debut", LocalDate.class), ligne.getObject("fin", LocalDate.class),
                            new ArrayList<>());
                    } catch (java.sql.SQLException e) {
                        throw new IllegalStateException(e);
                    }
                });
                if (ligne.getString("garantie") != null) {
                    contrat.garanties().add(new GarantieSouscrite(
                        TypeGarantie.valueOf(ligne.getString("garantie")),
                        new Montant(ligne.getBigDecimal("plafond")),
                        new Montant(ligne.getBigDecimal("franchise")),
                        ligne.getInt("taux_vetuste")));
                }
            });
        return contrats.values().stream().map(Brouillon::contrat).toList();
    }

    private record Brouillon(UUID id, String numero, TypeContrat type, String libelle,
                             LocalDate debut, LocalDate fin, List<GarantieSouscrite> garanties) {
        ContratAssure contrat() {
            return new ContratAssure(id, numero, type, libelle, debut, fin, garanties);
        }
    }
}
