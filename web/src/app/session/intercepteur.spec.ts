import { HttpClient, provideHttpClient, withInterceptors } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { Router } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { intercepteurSessionExpiree } from './intercepteur';
import { Session } from './session';

describe('intercepteur de session expirée (US-01)', () => {
  const navigate = vi.fn().mockResolvedValue(true);
  const oublier = vi.fn();
  let http: HttpClient;
  let serveur: HttpTestingController;

  beforeEach(() => {
    navigate.mockClear();
    oublier.mockClear();
    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(withInterceptors([intercepteurSessionExpiree])),
        provideHttpClientTesting(),
        { provide: Router, useValue: { navigate } },
        { provide: Session, useValue: { oublier } },
      ],
    });
    http = TestBed.inject(HttpClient);
    serveur = TestBed.inject(HttpTestingController);
  });

  it('renvoie à la connexion quand l’API répond 401', async () => {
    const appel = firstValueFrom(http.get('/api/v1/contrats'));
    serveur.expectOne('/api/v1/contrats').flush(null, { status: 401, statusText: 'Unauthorized' });

    await expect(appel).rejects.toMatchObject({ status: 401 });
    expect(oublier).toHaveBeenCalled();
    expect(navigate).toHaveBeenCalledWith(['/connexion'], { queryParams: { expiree: 1 } });
  });

  it('laisse passer le 401 de /bff/utilisateur, qui veut seulement dire « pas connecté »', async () => {
    const appel = firstValueFrom(http.get('/bff/utilisateur'));
    serveur.expectOne('/bff/utilisateur').flush(null, { status: 401, statusText: 'Unauthorized' });

    await expect(appel).rejects.toMatchObject({ status: 401 });
    expect(navigate).not.toHaveBeenCalled();
  });

  it('ne touche pas aux autres erreurs de l’API', async () => {
    const appel = firstValueFrom(http.get('/api/v1/contrats'));
    serveur.expectOne('/api/v1/contrats').flush(null, { status: 503, statusText: 'Service Unavailable' });

    await expect(appel).rejects.toMatchObject({ status: 503 });
    expect(navigate).not.toHaveBeenCalled();
  });
});
