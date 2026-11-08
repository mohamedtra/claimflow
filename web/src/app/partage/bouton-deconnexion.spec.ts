import { TestBed } from '@angular/core/testing';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { Bff } from '../session/bff';
import { Navigateur } from '../session/navigateur';
import { Session } from '../session/session';
import { BoutonDeconnexion } from './bouton-deconnexion';

describe('Déconnexion (US-01)', () => {
  const seDeconnecter = vi.fn<() => Promise<string>>();
  const aller = vi.fn();
  const oublier = vi.fn();

  beforeEach(() => {
    seDeconnecter.mockReset();
    aller.mockReset();
    oublier.mockReset();
    TestBed.configureTestingModule({
      providers: [
        { provide: Bff, useValue: { seDeconnecter } },
        { provide: Navigateur, useValue: { aller } },
        { provide: Session, useValue: { oublier } },
      ],
    });
  });

  async function cliquer(): Promise<void> {
    const bouton = TestBed.createComponent(BoutonDeconnexion);
    await bouton.whenStable();
    (bouton.nativeElement as HTMLElement).querySelector('button')?.click();
    await new Promise((suite) => setTimeout(suite));
  }

  it('ferme la session du BFF puis envoie chez Keycloak fermer la session SSO', async () => {
    const sortie = 'http://localhost:8180/realms/claimflow/protocol/openid-connect/logout?id_token_hint=x';
    seDeconnecter.mockResolvedValue(sortie);
    await cliquer();
    expect(oublier).toHaveBeenCalled();
    expect(aller).toHaveBeenCalledWith(sortie);
  });

  it('recharge l’application si le BFF ne répond pas', async () => {
    seDeconnecter.mockRejectedValue(new Error('réseau'));
    await cliquer();
    expect(aller).toHaveBeenCalledWith('/');
  });
});
