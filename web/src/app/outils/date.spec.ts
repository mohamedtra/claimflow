import { describe, expect, it } from 'vitest';
import { aujourdhuiAParis, dateDuJourEnToutesLettres, formaterDate } from './date';

describe('formaterDate', () => {
  it('affiche une date métier au format français, sans décalage de fuseau', () => {
    expect(formaterDate('2026-01-01')).toBe('01/01/2026');
  });

  it('refuse un texte qui n’est pas une date ISO', () => {
    expect(() => formaterDate('01/01/2026')).toThrow('Date invalide');
  });
});

describe('aujourdhuiAParis', () => {
  it('prend la date de Paris, pas celle de UTC', () => {
    // 23 h 30 UTC le 14 octobre : il est déjà 1 h 30 le 15 à Paris (heure d’été).
    expect(aujourdhuiAParis(new Date('2026-10-14T23:30:00Z'))).toBe('2026-10-15');
  });
});

describe('dateDuJourEnToutesLettres', () => {
  it('écrit la date en toutes lettres, en français', () => {
    expect(dateDuJourEnToutesLettres(new Date('2026-10-15T08:00:00Z'))).toBe('Jeudi 15 octobre 2026');
  });
});
