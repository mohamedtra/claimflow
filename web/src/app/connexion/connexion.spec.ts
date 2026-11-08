import { TestBed } from '@angular/core/testing';
import { provideRouter, withComponentInputBinding } from '@angular/router';
import { RouterTestingHarness } from '@angular/router/testing';
import { beforeEach, describe, expect, it } from 'vitest';
import { ConnexionPage } from './connexion';

describe('Connexion (US-01, US-02)', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideRouter([{ path: 'connexion', component: ConnexionPage }], withComponentInputBinding())],
    });
  });

  async function afficher(adresse: string): Promise<HTMLElement> {
    const harnais = await RouterTestingHarness.create();
    await harnais.navigateByUrl(adresse);
    return harnais.routeNativeElement as HTMLElement;
  }

  it('envoie vers Keycloak par le BFF, sans formulaire d’identifiants dans la SPA', async () => {
    const page = await afficher('/connexion');
    expect(page.querySelector('[data-test="se-connecter"]')?.getAttribute('href')).toBe('/oauth2/authorization/keycloak');
    expect(page.querySelector('input')).toBeNull();
    expect(page.querySelector('[data-test="message"]')).toBeNull();
  });

  it('explique une session expirée', async () => {
    const page = await afficher('/connexion?expiree=1');
    expect(page.querySelector('[data-test="message"]')?.textContent).toContain('session a expiré');
  });

  it('explique un échec de connexion', async () => {
    const page = await afficher('/connexion?erreur=connexion');
    expect(page.querySelector('[data-test="message"]')?.textContent).toContain("n'a pas abouti");
  });

  it('signale un service de connexion indisponible', async () => {
    const page = await afficher('/connexion?indisponible=1');
    expect(page.querySelector('[data-test="message"]')?.textContent).toContain('indisponible');
  });
});
