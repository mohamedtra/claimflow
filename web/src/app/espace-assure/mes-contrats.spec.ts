import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { beforeEach, describe, expect, it } from 'vitest';
import { provideApiConfiguration } from '../api/api-configuration';
import { Contrat } from '../api/models/contrat';
import { MesContratsPage } from './mes-contrats';

const habitation: Contrat = {
  id: 'k1',
  numero: 'HAB-3391027',
  type: 'HABITATION',
  libelle: 'Multirisque habitation',
  debut: '2024-03-01',
  garanties: [
    { type: 'DEGAT_DES_EAUX', plafond: '15000.00', franchise: '150.00', tauxVetuste: 10 },
    { type: 'INCENDIE', plafond: '300000.00', franchise: '300.00', tauxVetuste: 0 },
  ],
};
const autoEchue: Contrat = {
  id: 'k2',
  numero: 'AUTO-7712045',
  type: 'AUTO',
  libelle: 'Auto tous risques',
  debut: '2023-01-01',
  fin: '2025-12-31',
  garanties: [],
};

describe('Mes contrats (US-04)', () => {
  let serveur: HttpTestingController;

  async function afficher(): Promise<ComponentFixture<MesContratsPage>> {
    const page = TestBed.createComponent(MesContratsPage);
    await page.whenStable();
    return page;
  }

  async function repondre(page: ComponentFixture<MesContratsPage>, statut: number, corps: Contrat[] | null) {
    serveur.expectOne('/api/v1/contrats').flush(corps, { status: statut, statusText: String(statut) });
    // La réponse traverse quelques promesses (client généré, service) avant de mettre à jour les
    // signaux : on laisse passer un tour de boucle, puis on attend le rendu.
    await new Promise((suite) => setTimeout(suite));
    await page.whenStable();
    return page.nativeElement as HTMLElement;
  }

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideHttpClient(), provideHttpClientTesting(), provideApiConfiguration('')],
    });
    serveur = TestBed.inject(HttpTestingController);
  });

  it('affiche chaque contrat avec ses garanties, plafonds et franchises en euros', async () => {
    const ecran = await repondre(await afficher(), 200, [habitation, autoEchue]);

    const contrats = ecran.querySelectorAll('[data-test="contrat"]');
    expect(contrats).toHaveLength(2);
    expect(contrats[0]?.textContent).toContain('HAB-3391027');
    expect(contrats[0]?.querySelector('[data-test="statut"]')?.textContent).toBe('Actif');
    expect(contrats[1]?.querySelector('[data-test="statut"]')?.textContent).toBe('Échu');

    const degatDesEaux = contrats[0]?.querySelector('[data-test="garantie"]')?.textContent ?? '';
    expect(degatDesEaux).toContain('Dégât des eaux');
    expect(degatDesEaux).toContain('15 000,00 €');
    expect(degatDesEaux).toContain('150,00 €');
    expect(degatDesEaux).toContain('10 %');
  });

  it('le dit quand aucun contrat n’est rattaché', async () => {
    const ecran = await repondre(await afficher(), 200, []);
    expect(ecran.querySelector('[data-test="aucun-contrat"]')).not.toBeNull();
  });

  it('propose de réessayer si l’API échoue', async () => {
    const page = await afficher();
    const ecran = await repondre(page, 503, null);
    expect(ecran.querySelector('[role="alert"]')?.textContent).toContain("n'ont pas pu être chargés");

    ecran.querySelector<HTMLButtonElement>('[role="alert"] button')?.click();
    await repondre(page, 200, [habitation]);
    expect(ecran.querySelectorAll('[data-test="contrat"]')).toHaveLength(1);
  });
});
