package fr.claimflow.contrat;

/**
 * Garanties qu'un contrat peut couvrir. Dans le package racine du module : c'est son API publique,
 * le module sinistre s'en servira pour vérifier la garantie déclarée (US-05).
 */
public enum TypeGarantie {
    DEGAT_DES_EAUX, INCENDIE, VOL, BRIS_DE_GLACE, TEMPETE, AUTO_COLLISION, AUTO_VANDALISME
}
