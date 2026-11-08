import { computed, inject, Injectable, signal } from '@angular/core';
import { Bff, Role, Utilisateur } from './bff';

export function aLeRole(qui: Utilisateur | null, role: Role): boolean {
  return qui?.roles.includes(role) ?? false;
}

/** État de la session dans la SPA : qui est connecté, lu une fois auprès du BFF. */
@Injectable({ providedIn: 'root' })
export class Session {
  private readonly bff = inject(Bff);
  private readonly courant = signal<Utilisateur | null>(null);
  private chargement: Promise<Utilisateur | null> | null = null;

  readonly utilisateur = this.courant.asReadonly();
  readonly prenom = computed(() => this.courant()?.nom?.trim().split(/\s+/)[0] ?? '');
  readonly initiales = computed(() =>
    (this.courant()?.nom ?? '')
      .trim()
      .split(/\s+/)
      .filter(Boolean)
      .slice(0, 2)
      .map((mot) => mot.charAt(0).toUpperCase())
      .join(''),
  );

  /** Lit la session une seule fois ; une panne n'est pas mémorisée, pour pouvoir réessayer. */
  charger(): Promise<Utilisateur | null> {
    this.chargement ??= this.bff.lireUtilisateur().then(
      (qui) => {
        this.courant.set(qui);
        return qui;
      },
      (erreur: unknown) => {
        this.chargement = null;
        throw erreur;
      },
    );
    return this.chargement;
  }

  /** Session expirée ou fermée : on n'interroge plus le BFF avant la prochaine connexion. */
  oublier(): void {
    this.courant.set(null);
    this.chargement = Promise.resolve(null);
  }
}
