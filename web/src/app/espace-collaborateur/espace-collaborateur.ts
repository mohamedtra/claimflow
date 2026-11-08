import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { BoutonDeconnexion } from '../partage/bouton-deconnexion';
import { Logo } from '../partage/logo';
import { Role } from '../session/bff';
import { Session } from '../session/session';

const LIBELLES_ROLE: Record<Role, string> = {
  GESTIONNAIRE: 'Gestionnaire',
  EXPERT: 'Expert',
  RESPONSABLE: 'Responsable sinistres',
  ADMIN: 'Administrateur',
  ASSURE: 'Assuré',
};

/**
 * Personnel connecté (US-02) : son espace de travail arrive au sprint 3 (corbeille des dossiers,
 * US-07). En attendant, cette page confirme la connexion, second facteur compris.
 */
@Component({
  selector: 'cf-espace-collaborateur',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [Logo, BoutonDeconnexion],
  template: `
    <header class="entete">
      <cf-logo [taille]="28" />
      <cf-bouton-deconnexion />
    </header>
    <main class="contenu">
      <p class="surtitre">Espace collaborateur</p>
      <h1 data-test="salutation">Bonjour {{ session.prenom() }}</h1>
      <p data-test="roles">Connecté en tant que {{ roles() }}, avec un second facteur.</p>
      <p class="carte annonce">
        Votre espace de travail arrive au sprint 3 : corbeille des dossiers triés par échéance, recherche et recevabilité.
      </p>
    </main>
  `,
  styles: `
    :host {
      display: block;
      min-height: 100vh;
    }
    .entete {
      min-height: 64px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
      padding: 0 28px;
      background: var(--white);
      border-bottom: 1px solid var(--n-200);
    }
    .contenu {
      max-width: 720px;
      padding: 48px 28px;
      display: flex;
      flex-direction: column;
      gap: 12px;
    }
    .annonce {
      margin-top: 12px;
      padding: 16px 20px;
    }
    @media (max-width: 600px) {
      .entete,
      .contenu {
        padding-inline: 16px;
      }
    }
  `,
})
export class EspaceCollaborateur {
  protected readonly session = inject(Session);
  protected readonly roles = computed(() =>
    (this.session.utilisateur()?.roles ?? []).map((role) => LIBELLES_ROLE[role]).join(', '),
  );
}
