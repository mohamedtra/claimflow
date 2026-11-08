import { ChangeDetectionStrategy, Component, input } from '@angular/core';

export type NomIcone = 'maison' | 'voiture' | 'bouclier' | 'sortie' | 'cadenas' | 'chevron' | 'alerte' | 'info';

/** Icônes au trait, dessinées pour ClaimFlow (aucune bibliothèque d'icônes). Décoratives : aria-hidden. */
@Component({
  selector: 'cf-icone',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <svg
      [attr.width]="taille()"
      [attr.height]="taille()"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.8"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
    >
      @switch (nom()) {
        @case ('maison') {
          <path d="M3 10.5 12 3l9 7.5" />
          <path d="M5 9v11h14V9" />
          <path d="M10 20v-6h4v6" />
        }
        @case ('voiture') {
          <path d="M5 11l1.6-4.2A2 2 0 0 1 8.5 5.5h7a2 2 0 0 1 1.9 1.3L19 11" />
          <rect x="3" y="11" width="18" height="6" rx="2" />
          <circle cx="7.5" cy="17.5" r="1.5" />
          <circle cx="16.5" cy="17.5" r="1.5" />
        }
        @case ('bouclier') {
          <path d="M12 3 4 6v6c0 4.5 3.4 8 8 9 4.6-1 8-4.5 8-9V6z" />
          <path d="m9 12 2 2 4-4" />
        }
        @case ('sortie') {
          <path d="M14 4h5v16h-5" />
          <path d="M10 8l-4 4 4 4" />
          <path d="M6 12h10" />
        }
        @case ('cadenas') {
          <rect x="5" y="11" width="14" height="9" rx="2" />
          <path d="M8 11V8a4 4 0 0 1 8 0v3" />
        }
        @case ('chevron') {
          <path d="m9 6 6 6-6 6" />
        }
        @case ('alerte') {
          <path d="M12 4 2.5 20h19z" />
          <path d="M12 10v4" />
          <path d="M12 17h.01" />
        }
        @case ('info') {
          <circle cx="12" cy="12" r="9" />
          <path d="M12 11v5" />
          <path d="M12 8h.01" />
        }
      }
    </svg>
  `,
  styles: `
    :host {
      display: inline-flex;
      flex: none;
    }
  `,
})
export class Icone {
  readonly nom = input.required<NomIcone>();
  readonly taille = input(20);
}
