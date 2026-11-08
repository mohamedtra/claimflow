import { Pipe, PipeTransform } from '@angular/core';
import { formaterMontant } from './montant';

/** {{ garantie.plafond | montant }} → « 8 000,00 € » (ADR-012). */
@Pipe({ name: 'montant' })
export class MontantPipe implements PipeTransform {
  transform(montant: string): string {
    return formaterMontant(montant);
  }
}

