import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { Bff } from '../session/bff';
import { Navigateur } from '../session/navigateur';
import { Session } from '../session/session';
import { Icone } from './icone';

/**
 * Déconnexion (US-01) : le BFF ferme sa session (POST, avec le jeton CSRF), puis le navigateur va
 * chez Keycloak fermer la session SSO, qui le renvoie à la SPA.
 */
@Component({
  selector: 'cf-bouton-deconnexion',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [Icone],
  template: `
    <button type="button" class="btn btn-secondaire" [disabled]="enCours()" (click)="deconnecter()" data-test="se-deconnecter">
      <cf-icone nom="sortie" [taille]="17" />
      Se déconnecter
    </button>
  `,
})
export class BoutonDeconnexion {
  private readonly bff = inject(Bff);
  private readonly session = inject(Session);
  private readonly navigateur = inject(Navigateur);
  protected readonly enCours = signal(false);

  protected async deconnecter(): Promise<void> {
    this.enCours.set(true);
    try {
      const adresse = await this.bff.seDeconnecter();
      this.session.oublier();
      this.navigateur.aller(adresse);
    } catch {
      // Session déjà fermée ou BFF injoignable : un rechargement affichera l'état réel.
      this.navigateur.aller('/');
    }
  }
}
