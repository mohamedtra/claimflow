/**
 * Dates métier (AGENTS.md) : l'API envoie des LocalDate au format ISO "2026-10-15".
 *
 * On ne passe jamais par new Date("2026-10-15") : ce texte est lu comme minuit UTC, ce qui
 * afficherait la veille sur un poste réglé à l'ouest de Greenwich. Le texte est découpé tel quel.
 */
const DATE_ISO = /^(\d{4})-(\d{2})-(\d{2})$/;

export function formaterDate(iso: string): string {
  const morceaux = DATE_ISO.exec(iso);
  if (!morceaux) {
    throw new Error(`Date invalide : « ${iso} » (format attendu : 2026-10-15)`);
  }
  const [, annee, mois, jour] = morceaux;
  return `${jour}/${mois}/${annee}`;
}

/** Date du jour à Paris, au format ISO : comparable directement aux dates de l'API. */
export function aujourdhuiAParis(maintenant: Date = new Date()): string {
  // Le format en-CA écrit justement AAAA-MM-JJ.
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'Europe/Paris' }).format(maintenant);
}

const EN_TOUTES_LETTRES = new Intl.DateTimeFormat('fr-FR', {
  timeZone: 'Europe/Paris',
  weekday: 'long',
  day: 'numeric',
  month: 'long',
  year: 'numeric',
});

/** « Jeudi 15 octobre 2026 », pour l'accueil. */
export function dateDuJourEnToutesLettres(maintenant: Date = new Date()): string {
  const texte = EN_TOUTES_LETTRES.format(maintenant);
  return texte.charAt(0).toUpperCase() + texte.slice(1);
}
