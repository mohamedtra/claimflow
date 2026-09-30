import { describe, expect, it } from 'vitest'
import { formaterMontant } from './montant'

// Intl utilise une espace fine insécable (U+202F) pour les milliers et une espace insécable
// (U+00A0) avant le symbole €.
const FINE = ' '
const INSECABLE = ' '

describe('formaterMontant (ADR-012)', () => {
  it('affiche un montant en euros au format français', () => {
    expect(formaterMontant('3876.00')).toBe(`3${FINE}876,00${INSECABLE}€`)
  })

  it('conserve les centimes sans erreur d’arrondi', () => {
    expect(formaterMontant('0.30')).toBe(`0,30${INSECABLE}€`)
    expect(formaterMontant('9999999999.99')).toBe(`9${FINE}999${FINE}999${FINE}999,99${INSECABLE}€`)
  })

  it('refuse un nombre au lieu d’une chaîne décimale', () => {
    expect(() => formaterMontant('3876')).toThrow(/Montant invalide/)
    expect(() => formaterMontant('-12.00')).toThrow(/Montant invalide/)
  })
})
