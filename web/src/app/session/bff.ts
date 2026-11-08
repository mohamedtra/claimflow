import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { firstValueFrom } from 'rxjs';

/** Rôles applicatifs (RolesKeycloak côté BFF). */
export type Role = 'ASSURE' | 'GESTIONNAIRE' | 'EXPERT' | 'RESPONSABLE' | 'ADMIN';

/** Réponse de GET /bff/utilisateur. En lecture seule : la SPA ne modifie jamais l'utilisateur. */
export interface Utilisateur {
  readonly id: string;
  readonly nom: string | null;
  readonly email: string | null;
  readonly roles: readonly Role[];
}

/**
 * Connexion : une navigation complète vers le BFF, jamais un appel HTTP. Le BFF redirige vers
 * Keycloak (code + PKCE) ; l'identifiant et le mot de passe ne sont saisis que sur la page de
 * Keycloak (ADR-002, ADR-003).
 */
export const ADRESSE_CONNEXION = '/oauth2/authorization/keycloak';

/** Points techniques du BFF : qui est connecté, et déconnexion. */
@Injectable({ providedIn: 'root' })
export class Bff {
  private readonly http = inject(HttpClient);

  /** L'utilisateur connecté, ou null sans session (401). Toute autre erreur est une panne. */
  async lireUtilisateur(): Promise<Utilisateur | null> {
    try {
      return await firstValueFrom(this.http.get<Utilisateur>('/bff/utilisateur'));
    } catch (erreur) {
      if (erreur instanceof HttpErrorResponse && erreur.status === 401) {
        return null;
      }
      const statut = erreur instanceof HttpErrorResponse ? erreur.status : 'réseau';
      throw new Error(`Service de connexion indisponible (${statut})`, { cause: erreur });
    }
  }

  /**
   * Ferme la session du BFF et rend l'adresse de déconnexion de Keycloak (en-tête Location de la
   * réponse 202), où le navigateur doit aller pour fermer aussi la session SSO. Le jeton CSRF est
   * ajouté par HttpClient (withXsrfConfiguration, app.config.ts).
   */
  async seDeconnecter(): Promise<string> {
    const reponse = await firstValueFrom(
      this.http.post('/bff/deconnexion', null, { observe: 'response', responseType: 'text' }),
    );
    return reponse.headers.get('Location') ?? '/';
  }
}
