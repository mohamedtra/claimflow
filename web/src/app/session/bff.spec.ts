import { provideHttpClient, withXsrfConfiguration } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { Bff, Utilisateur } from './bff';

describe('Bff (US-01)', () => {
  let bff: Bff;
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(withXsrfConfiguration({ cookieName: 'XSRF-TOKEN', headerName: 'X-XSRF-TOKEN' })),
        provideHttpClientTesting(),
      ],
    });
    bff = TestBed.inject(Bff);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => http.verify());

  it('rend l’utilisateur connecté', async () => {
    const claire: Utilisateur = { id: 'c1', nom: 'Claire Martin', email: 'claire.martin@exemple.fr', roles: ['ASSURE'] };
    const reponse = bff.lireUtilisateur();
    http.expectOne('/bff/utilisateur').flush(claire);
    await expect(reponse).resolves.toEqual(claire);
  });

  it('rend null sans session (401)', async () => {
    const reponse = bff.lireUtilisateur();
    http.expectOne('/bff/utilisateur').flush(null, { status: 401, statusText: 'Unauthorized' });
    await expect(reponse).resolves.toBeNull();
  });

  it('échoue si le BFF est en panne, pour ne pas confondre panne et déconnexion', async () => {
    const reponse = bff.lireUtilisateur();
    http.expectOne('/bff/utilisateur').flush(null, { status: 503, statusText: 'Service Unavailable' });
    await expect(reponse).rejects.toThrow('indisponible (503)');
  });

  it('se déconnecte avec le jeton CSRF et rend l’adresse de sortie de Keycloak', async () => {
    document.cookie = 'XSRF-TOKEN=jeton-csrf';
    const sortie = 'http://localhost:8180/realms/claimflow/protocol/openid-connect/logout?id_token_hint=x';
    const reponse = bff.seDeconnecter();

    const requete = http.expectOne('/bff/deconnexion');
    expect(requete.request.method).toBe('POST');
    expect(requete.request.headers.get('X-XSRF-TOKEN')).toBe('jeton-csrf');
    requete.flush('', { status: 202, statusText: 'Accepted', headers: { Location: sortie } });

    await expect(reponse).resolves.toBe(sortie);
  });
});
