import { HttpErrorResponse } from '@angular/common/http';
import { inject, Injectable, signal } from '@angular/core';
import { Api } from '../api/api';
import { listerMesContrats } from '../api/fn/contrats/lister-mes-contrats';
import { Contrat } from '../api/models/contrat';
import { TypeGarantie } from '../api/models/type-garantie';
import { aujourdhuiAParis } from '../outils/date';

export const LIBELLES_TYPE_CONTRAT: Record<Contrat['type'], string> = {
  HABITATION: 'Habitation',
  AUTO: 'Auto',
};

export const LIBELLES_GARANTIE: Record<TypeGarantie, string> = {
  DEGAT_DES_EAUX: 'Dégât des eaux',
  INCENDIE: 'Incendie',
  VOL: 'Vol',
  BRIS_DE_GLACE: 'Bris de glace',
  TEMPETE: 'Tempête',
  AUTO_COLLISION: 'Auto · collision',
  AUTO_VANDALISME: 'Auto · vandalisme',
};

/**
 * Échu : la date de fin est passée, à Paris. Un contrat reste actif le jour de sa fin.
 * L'API ne renvoie que les contrats actifs ou échus depuis deux ans au plus (US-04).
 */
export function estEchu(contrat: Contrat, aujourdhui: string = aujourdhuiAParis()): boolean {
  return contrat.fin != null && contrat.fin < aujourdhui;
}

export type EtatChargement = 'chargement' | 'pret' | 'erreur';

/**
 * US-04 : les contrats de l'assuré connecté (GET /api/v1/contrats, fonction générée depuis le
 * contrat OpenAPI). Fourni par chaque écran (providers), pour que chacun ait son propre état.
 */
@Injectable()
export class MesContrats {
  private readonly api = inject(Api);
  readonly contrats = signal<Contrat[]>([]);
  readonly etat = signal<EtatChargement>('chargement');

  async charger(): Promise<void> {
    this.etat.set('chargement');
    try {
      this.contrats.set(await this.api.invoke(listerMesContrats));
      this.etat.set('pret');
    } catch (erreur) {
      // Le 401 est traité par l'intercepteur (retour à la connexion) : pas de message d'erreur ici.
      if (!(erreur instanceof HttpErrorResponse && erreur.status === 401)) {
        this.etat.set('erreur');
      }
    }
  }
}
