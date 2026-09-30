import createClient from 'openapi-fetch'
import type { paths } from './schema'

/**
 * Client typé de l'API ClaimFlow, généré à partir de docs/openapi/claimflow.yaml (ADR-005).
 * Les chemins, paramètres et réponses sont vérifiés à la compilation : un changement du contrat
 * qui casse la SPA est détecté par `npm run type-check`.
 *
 * Les requêtes partent vers la même origine : le BFF y ajoute le jeton d'accès (ADR-003).
 */
export const api = createClient<paths>({ baseUrl: '/', credentials: 'same-origin' })
