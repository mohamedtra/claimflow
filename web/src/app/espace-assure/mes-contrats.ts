import { ChangeDetectionStrategy, Component, inject, OnInit } from '@angular/core';
import { CarteContrat } from '../contrats/carte-contrat';
import { MesContrats } from '../contrats/contrats';

/**
 * US-04 : consulter mes contrats et garanties. Contrats actifs, ou échus depuis deux ans au plus
 * (règle appliquée par l'API).
 */
@Component({
  selector: 'cf-mes-contrats',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CarteContrat],
  providers: [MesContrats],
  template: `
    <div class="entete">
      <h1>Mes contrats</h1>
      <p class="discret">Vos contrats en cours et ceux échus depuis moins de deux ans, avec leurs garanties.</p>
    </div>

    @switch (mesContrats.etat()) {
      @case ('chargement') {
        <p class="discret" role="status">Chargement de vos contrats…</p>
      }
      @case ('erreur') {
        <div class="alerte alerte-erreur" role="alert">
          <span>Vos contrats n'ont pas pu être chargés.</span>
          <button type="button" class="btn btn-secondaire" (click)="mesContrats.charger()">Réessayer</button>
        </div>
      }
      @default {
        @for (contrat of mesContrats.contrats(); track contrat.id) {
          <cf-carte-contrat [contrat]="contrat" />
        } @empty {
          <p class="carte vide" data-test="aucun-contrat">
            Aucun contrat n'est rattaché à votre espace. Si c'est inattendu, contactez l'assistance.
          </p>
        }
      }
    }
  `,
  styles: `
    :host {
      max-width: 960px;
      display: flex;
      flex-direction: column;
      gap: 20px;
    }
    .entete {
      display: flex;
      flex-direction: column;
      gap: 6px;
      margin-bottom: 4px;
    }
    .vide {
      padding: 20px;
    }
    .alerte {
      align-items: center;
      justify-content: space-between;
    }
  `,
})
export class MesContratsPage implements OnInit {
  protected readonly mesContrats = inject(MesContrats);

  ngOnInit(): void {
    void this.mesContrats.charger();
  }
}
