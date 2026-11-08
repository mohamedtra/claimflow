import { ChangeDetectionStrategy, Component, computed, inject, OnInit } from '@angular/core';
import { RouterLink } from '@angular/router';
import { estEchu, MesContrats } from '../contrats/contrats';
import { dateDuJourEnToutesLettres } from '../outils/date';
import { Icone } from '../partage/icone';
import { Session } from '../session/session';

/**
 * Écran 02, dans sa version du sprint 1 : accueil et résumé des contrats actifs. Les sinistres en
 * cours et la déclaration arrivent avec US-05 et US-11 (sprint 2).
 */
@Component({
  selector: 'cf-accueil',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [Icone, RouterLink],
  providers: [MesContrats],
  templateUrl: './accueil.html',
  styleUrl: './accueil.css',
})
export class AccueilPage implements OnInit {
  protected readonly session = inject(Session);
  protected readonly mesContrats = inject(MesContrats);
  protected readonly aujourdhui = dateDuJourEnToutesLettres();
  protected readonly contratsActifs = computed(() => this.mesContrats.contrats().filter((contrat) => !estEchu(contrat)));

  ngOnInit(): void {
    void this.mesContrats.charger();
  }
}
