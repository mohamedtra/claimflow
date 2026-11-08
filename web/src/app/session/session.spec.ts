import { TestBed } from '@angular/core/testing';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { Bff, Utilisateur } from './bff';
import { aLeRole, Session } from './session';

const claire: Utilisateur = { id: 'c1', nom: 'Claire Martin', email: null, roles: ['ASSURE'] };

describe('Session', () => {
  const lireUtilisateur = vi.fn<() => Promise<Utilisateur | null>>();
  let session: Session;

  beforeEach(() => {
    lireUtilisateur.mockReset();
    TestBed.configureTestingModule({ providers: [{ provide: Bff, useValue: { lireUtilisateur } }] });
    session = TestBed.inject(Session);
  });

  it('donne le prénom et les initiales pour l’en-tête', async () => {
    lireUtilisateur.mockResolvedValue(claire);
    await session.charger();
    expect(session.prenom()).toBe('Claire');
    expect(session.initiales()).toBe('CM');
  });

  it('reste vide sans session', async () => {
    lireUtilisateur.mockResolvedValue(null);
    await session.charger();
    expect(session.prenom()).toBe('');
    expect(session.initiales()).toBe('');
  });

  it('réessaie après une panne du BFF', async () => {
    lireUtilisateur.mockRejectedValueOnce(new Error('indisponible')).mockResolvedValueOnce(claire);
    await expect(session.charger()).rejects.toThrow('indisponible');
    await expect(session.charger()).resolves.toEqual(claire);
  });

  it('oublie l’utilisateur sans rappeler le BFF', async () => {
    lireUtilisateur.mockResolvedValue(claire);
    await session.charger();
    session.oublier();
    await expect(session.charger()).resolves.toBeNull();
    expect(session.utilisateur()).toBeNull();
    expect(lireUtilisateur).toHaveBeenCalledTimes(1);
  });

  it('vérifie un rôle', () => {
    expect(aLeRole(claire, 'ASSURE')).toBe(true);
    expect(aLeRole(claire, 'GESTIONNAIRE')).toBe(false);
    expect(aLeRole(null, 'ASSURE')).toBe(false);
  });
});
