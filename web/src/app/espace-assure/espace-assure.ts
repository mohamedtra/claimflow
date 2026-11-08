import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { BoutonDeconnexion } from '../partage/bouton-deconnexion';
import { Logo } from '../partage/logo';
import { Session } from '../session/session';

/** Cadre de l'espace assuré (écran 02) : en-tête, navigation, contenu, pied de page. */
@Component({
  selector: 'cf-espace-assure',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterOutlet, RouterLink, RouterLinkActive, Logo, BoutonDeconnexion],
  templateUrl: './espace-assure.html',
  styleUrl: './espace-assure.css',
})
export class EspaceAssure {
  protected readonly session = inject(Session);
}
