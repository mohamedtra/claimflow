import { defineConfig, devices } from '@playwright/test';

/**
 * Recette de bout en bout : un vrai navigateur contre un environnement déployé (E2E_URL), en
 * passant par CloudFront, le BFF et Keycloak. Les sélecteurs visent les attributs data-test de la
 * SPA, jamais sa structure : les tests ne dépendent pas du framework (ADR-017).
 */
const adresse = process.env['E2E_URL'];
if (!adresse) {
  throw new Error('E2E_URL est obligatoire, par exemple E2E_URL=https://xxxx.cloudfront.net');
}

export default defineConfig({
  testDir: './tests',
  timeout: 90_000,
  expect: { timeout: 20_000 },
  retries: process.env['CI'] ? 1 : 0,
  reporter: [['list'], ['html', { open: 'never', outputFolder: 'rapport' }]],
  use: {
    baseURL: adresse,
    testIdAttribute: 'data-test',
    locale: 'fr-FR',
    timezoneId: 'Europe/Paris',
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
  },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
});
