import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { Contrat } from '../api/models/contrat';
import { Icone } from '../partage/icone';
import { MontantPipe } from '../outils/montant.pipe';
import { formaterDate } from '../outils/date';
import { estEchu, LIBELLES_GARANTIE, LIBELLES_TYPE_CONTRAT } from './contrats';

@Component({
  selector: 'cf-carte-contrat',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [Icone, MontantPipe],
  templateUrl: './carte-contrat.html',
  styleUrl: './carte-contrat.css',
  host: { class: 'carte', 'data-test': 'contrat', role: 'article', '[attr.aria-labelledby]': 'idTitre()' },
})
export class CarteContrat {
  readonly contrat = input.required<Contrat>();

  protected readonly libellesGarantie = LIBELLES_GARANTIE;
  protected readonly libellesType = LIBELLES_TYPE_CONTRAT;
  protected readonly idTitre = computed(() => `contrat-${this.contrat().id}`);
  protected readonly echu = computed(() => estEchu(this.contrat()));
  protected readonly periode = computed(() => {
    const { debut, fin } = this.contrat();
    return fin ? `Du ${formaterDate(debut)} au ${formaterDate(fin)}` : `Depuis le ${formaterDate(debut)}`;
  });
}

