package fr.claimflow.sinistre.domain;

import java.util.Collections;
import java.util.EnumMap;
import java.util.EnumSet;
import java.util.Map;
import java.util.Set;

/**
 * Statuts du dossier de sinistre et transitions autorisées (section 1.3 du dossier projet, ADR-004).
 *
 * <p>C'est la seule description de la machine à états : l'agrégat {@code Sinistre} s'y réfère avant
 * tout changement de statut, et aucun autre code ne modifie un statut.
 */
public enum Statut {
    DECLARE,
    EN_INSTRUCTION,
    EN_ATTENTE_PIECES,
    EN_EXPERTISE,
    PROPOSITION,
    EN_VALIDATION,
    OFFRE_ENVOYEE,
    ACCEPTEE,
    INDEMNISE,
    REFUSE,
    CLASSE_SANS_SUITE,
    CLOS;

    private static final Map<Statut, Set<Statut>> SUIVANTS = new EnumMap<>(Statut.class);

    static {
        SUIVANTS.put(DECLARE, EnumSet.of(EN_INSTRUCTION, REFUSE));
        SUIVANTS.put(EN_INSTRUCTION, EnumSet.of(EN_ATTENTE_PIECES, EN_EXPERTISE, PROPOSITION));
        SUIVANTS.put(EN_ATTENTE_PIECES, EnumSet.of(EN_INSTRUCTION, CLASSE_SANS_SUITE));
        SUIVANTS.put(EN_EXPERTISE, EnumSet.of(EN_INSTRUCTION));
        SUIVANTS.put(PROPOSITION, EnumSet.of(EN_VALIDATION, OFFRE_ENVOYEE));   // RG-06
        SUIVANTS.put(EN_VALIDATION, EnumSet.of(PROPOSITION, OFFRE_ENVOYEE));
        SUIVANTS.put(OFFRE_ENVOYEE, EnumSet.of(ACCEPTEE, EN_INSTRUCTION));     // RG-14
        SUIVANTS.put(ACCEPTEE, EnumSet.of(INDEMNISE));
        SUIVANTS.put(INDEMNISE, EnumSet.of(CLOS));
        SUIVANTS.put(REFUSE, EnumSet.of(CLOS));
        SUIVANTS.put(CLASSE_SANS_SUITE, EnumSet.of(CLOS));
        SUIVANTS.put(CLOS, EnumSet.of(EN_INSTRUCTION));                        // RG-10
    }

    public boolean peutPasserA(Statut cible) {
        return SUIVANTS.get(this).contains(cible);
    }

    public Set<Statut> suivants() {
        return Collections.unmodifiableSet(SUIVANTS.get(this));
    }

    /** Un dossier est ouvert tant qu'une décision ou un paiement est attendu. */
    public boolean estOuvert() {
        return this != INDEMNISE && this != REFUSE && this != CLASSE_SANS_SUITE && this != CLOS;
    }
}
