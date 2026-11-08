import { inject } from '@angular/core';
import { CanActivateFn, Router, UrlTree } from '@angular/router';
import { Role, Utilisateur } from './bff';
import { aLeRole, Session } from './session';

/** Données de route lues par la garde. */
export interface AccesRoute {
  /** Page sans connexion (la page de connexion). Un utilisateur connecté est renvoyé chez lui. */
  publique?: boolean;
  /** Rôle exigé. */
  role?: Role;
  /** Réservé au personnel : un assuré est renvoyé vers son espace. */
  personnel?: boolean;
}

/**
 * Garde des espaces (US-01, US-02). Elle protège l'affichage ; la vraie protection des données
 * reste l'API, qui contrôle le jeton et les droits à chaque appel.
 */
export const gardeSession: CanActivateFn = async (route) => {
  const session = inject(Session);
  const routeur = inject(Router);
  const acces: AccesRoute = route.data;

  const espaceDe = (qui: Utilisateur): UrlTree =>
    routeur.parseUrl(aLeRole(qui, 'ASSURE') ? '/' : '/collaborateur');

  let qui: Utilisateur | null;
  try {
    qui = await session.charger();
  } catch {
    // BFF en panne : on l'affiche, plutôt que de faire croire à une déconnexion.
    return acces.publique ? true : routeur.createUrlTree(['/connexion'], { queryParams: { indisponible: 1 } });
  }

  if (acces.publique) {
    return qui ? espaceDe(qui) : true;
  }
  if (!qui) {
    // Échec du retour de Keycloak : le BFF renvoie vers « /?erreur=connexion », on garde le motif.
    const erreur = route.queryParamMap.has('erreur') ? { erreur: 'connexion' } : {};
    return routeur.createUrlTree(['/connexion'], { queryParams: erreur });
  }
  if ((acces.role && !aLeRole(qui, acces.role)) || (acces.personnel && aLeRole(qui, 'ASSURE'))) {
    return espaceDe(qui);
  }
  return true;
};
