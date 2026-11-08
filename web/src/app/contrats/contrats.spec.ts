import { describe, expect, it } from 'vitest';
import { Contrat } from '../api/models/contrat';
import { estEchu } from './contrats';

const contrat: Contrat = {
  id: 'k1',
  numero: 'HAB-3391027',
  type: 'HABITATION',
  libelle: 'Multirisque habitation',
  debut: '2024-03-01',
  garanties: [],
};

describe('estEchu (US-04)', () => {
  it('un contrat sans fin est actif', () => {
    expect(estEchu(contrat, '2026-10-15')).toBe(false);
  });

  it('un contrat est encore actif le jour de sa fin', () => {
    expect(estEchu({ ...contrat, fin: '2026-10-15' }, '2026-10-15')).toBe(false);
  });

  it('un contrat est échu le lendemain de sa fin', () => {
    expect(estEchu({ ...contrat, fin: '2026-10-14' }, '2026-10-15')).toBe(true);
  });
});
