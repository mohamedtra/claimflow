/**
 * Noyau partagé : value objects et erreurs métier communs à tous les modules. Module ouvert : ses
 * types sont utilisables partout, mais il ne dépend d'aucun autre module.
 */
@ApplicationModule(displayName = "Noyau partagé", type = ApplicationModule.Type.OPEN)
package fr.claimflow.shared;

import org.springframework.modulith.ApplicationModule;
