import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { Icone } from '../partage/icone';
import { Logo } from '../partage/logo';
import { ADRESSE_CONNEXION } from '../session/bff';

interface Message {
  classe: 'alerte-attention' | 'alerte-erreur';
  texte: string;
}

/**
 * Écran 01 (US-01, US-02). Aucun champ d'identifiant ici : la saisie se fait sur la page de
 * Keycloak, où mènent le BFF et ce bouton (ADR-002, ADR-003 ; écart assumé avec la maquette,
 * section 3.26 du dossier). Les paramètres de l'adresse arrivent en entrées du composant
 * (withComponentInputBinding).
 */
@Component({
  selector: 'cf-connexion',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [Logo, Icone],
  templateUrl: './connexion.html',
  styleUrl: './connexion.css',
})
export class ConnexionPage {
  /** ?expiree=1 : l'intercepteur a reçu un 401 de l'API. */
  readonly expiree = input<string>();
  /** ?erreur=connexion : le retour de Keycloak a échoué (BFF). */
  readonly erreur = input<string>();
  /** ?indisponible=1 : le BFF ne répond pas. */
  readonly indisponible = input<string>();

  protected readonly adresseConnexion = ADRESSE_CONNEXION;
  protected readonly message = computed<Message | null>(() => {
    if (this.erreur()) {
      return {
        classe: 'alerte-erreur',
        texte: "La connexion n'a pas abouti. Réessayez ; si le problème persiste, contactez l'assistance.",
      };
    }
    if (this.indisponible()) {
      return {
        classe: 'alerte-erreur',
        texte: 'Le service de connexion est momentanément indisponible. Réessayez dans quelques instants.',
      };
    }
    if (this.expiree()) {
      return { classe: 'alerte-attention', texte: 'Votre session a expiré. Reconnectez-vous pour continuer.' };
    }
    return null;
  });
}
