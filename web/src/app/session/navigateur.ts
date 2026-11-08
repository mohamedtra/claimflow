import { DOCUMENT, inject, Injectable } from '@angular/core';

/** Navigation complète (hors du routeur Angular) : vers Keycloak à la déconnexion. Remplaçable en test. */
@Injectable({ providedIn: 'root' })
export class Navigateur {
  private readonly document = inject(DOCUMENT);

  aller(adresse: string): void {
    this.document.location.assign(adresse);
  }
}
