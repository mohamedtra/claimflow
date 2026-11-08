import { ChangeDetectionStrategy, Component, input } from '@angular/core';

@Component({
  selector: 'cf-logo',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'logo', '[class.sombre]': 'surFondSombre()' },
  template: `
    <svg [attr.width]="taille()" [attr.height]="taille()" viewBox="0 0 32 32" aria-hidden="true">
      <rect width="32" height="32" rx="8" [attr.fill]="surFondSombre() ? '#178A9A' : '#0B4F5C'" />
      <path d="M22.6 10.2A8.4 8.4 0 1 0 22.6 21.8" fill="none" stroke="#fff" stroke-width="3" stroke-linecap="round" />
      <circle cx="11.2" cy="16" r="1.9" fill="#fff" />
      <circle cx="16.2" cy="16" r="1.9" fill="#fff" opacity=".7" />
      <circle cx="23.2" cy="16" r="2.6" fill="#E09A12" />
    </svg>
    <span class="nom">Claim<span class="flow">Flow</span></span>
  `,
  styles: `
    :host {
      display: inline-flex;
      align-items: center;
      gap: 10px;
    }
    .nom {
      font-family: var(--f-display);
      font-weight: 700;
      font-size: 21px;
      letter-spacing: -0.01em;
      color: var(--n-900);
    }
    .flow {
      color: var(--brand-600);
    }
    :host(.sombre) .nom {
      color: var(--white);
    }
    :host(.sombre) .flow {
      color: var(--brand-200);
    }
  `,
})
export class Logo {
  readonly taille = input(30);
  readonly surFondSombre = input(false);
}
