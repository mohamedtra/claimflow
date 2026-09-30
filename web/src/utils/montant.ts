/**
 * Formatage des montants reçus de l'API (ADR-012).
 *
 * L'API transmet les montants en chaîne décimale ("3876.00"). La SPA ne fait aucun calcul dessus :
 * elle se contente de les afficher. La chaîne est passée telle quelle à Intl.NumberFormat, qui la
 * traite comme un décimal exact, sans conversion en nombre flottant.
 */
const FORMAT_EUROS = new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'EUR' })
const MONTANT = /^\d{1,10}\.\d{2}$/

export function formaterMontant(montant: string): string {
  if (!MONTANT.test(montant)) {
    throw new Error(`Montant invalide : « ${montant} » (format attendu : 3876.00)`)
  }
  return FORMAT_EUROS.format(montant as Intl.StringNumericLiteral)
}
