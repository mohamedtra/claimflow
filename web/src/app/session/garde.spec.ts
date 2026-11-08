import { TestBed } from '@angular/core/testing';
import { provideRouter, Router } from '@angular/router';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { routes } from '../app.routes';
import { Bff, Utilisateur } from './bff';

const claire: Utilisateur = { id: 'c1', nom: 'Claire Martin', email: null, roles: ['ASSURE'] };
const julien: Utilisateur = { id: 'j1', nom: 'Julien Moreau', email: null, roles: ['GESTIONNAIRE'] };

describe('garde de navigation (US-01, US-02)', () => {
  const lireUtilisateur = vi.fn<() => Promise<Utilisateur | null>>();

  async function naviguer(adresse: string): Promise<string> {
    const routeur = TestBed.inject(Router);
    await routeur.navigateByUrl(adresse);
    return routeur.url;
  }

  beforeEach(() => {
    lireUtilisateur.mockReset();
    TestBed.configureTestingModule({
      providers: [provideRouter(routes), { provide: Bff, useValue: { lireUtilisateur } }],
    });
  });

  it('renvoie vers la connexion sans session', async () => {
    lireUtilisateur.mockResolvedValue(null);
    expect(await naviguer('/contrats')).toBe('/connexion');
  });

  it('garde le motif quand le retour de Keycloak a échoué', async () => {
    lireUtilisateur.mockResolvedValue(null);
    expect(await naviguer('/?erreur=connexion')).toBe('/connexion?erreur=connexion');
  });

  it('ouvre l’espace assuré à Claire', async () => {
    lireUtilisateur.mockResolvedValue(claire);
    expect(await naviguer('/contrats')).toBe('/contrats');
  });

  it('renvoie un assuré déjà connecté de la connexion vers son accueil', async () => {
    lireUtilisateur.mockResolvedValue(claire);
    expect(await naviguer('/connexion')).toBe('/');
  });

  it('n’ouvre pas l’espace collaborateur à un assuré', async () => {
    lireUtilisateur.mockResolvedValue(claire);
    expect(await naviguer('/collaborateur')).toBe('/');
  });

  it('n’ouvre pas l’espace assuré au personnel', async () => {
    lireUtilisateur.mockResolvedValue(julien);
    expect(await naviguer('/contrats')).toBe('/collaborateur');
  });

  it('distingue la panne du BFF d’une absence de session', async () => {
    lireUtilisateur.mockRejectedValue(new Error('Service de connexion indisponible (503)'));
    expect(await naviguer('/')).toBe('/connexion?indisponible=1');
  });

  it('ne relit la session qu’une fois', async () => {
    lireUtilisateur.mockResolvedValue(claire);
    await naviguer('/');
    await naviguer('/contrats');
    await naviguer('/collaborateur');
    expect(lireUtilisateur).toHaveBeenCalledTimes(1);
  });
});
